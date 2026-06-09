// lib/features/petugas/screens/sesi_patroli_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/patroli_draft_model.dart';
import '../models/patroli_model.dart';
import '../repositories/patroli_repository.dart';
import '../services/patroli_draft_service.dart';
import 'buat_laporan_screen.dart';
import 'sos_form_screen.dart';

// ─────────────────────────────────────────────────────────
// Konstanta warna
// ─────────────────────────────────────────────────────────
class _C {
  static const bgPage   = Color(0xFFDCEFFE);
  static const blue     = Color(0xFF1565C0);
  static const blueCard = Color(0xFF0040A2);
  static const blueDark = Color(0xFF0F2A44);
  static const iconBg   = Color(0xFFC6DDF4);
  static const muted    = Color(0xFF64748B);
  static const gray     = Color(0xFF94A3B8);
  static const green    = Color(0xFF22C55E);
  static const header   = Color(0xFF0F172A);
  static const cardBg   = Colors.white;
  static const amber    = Color(0xFFF59E0B); // warna draft (kuning)

  static const logoUrl =
      'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/new_logo.png';
}

// ─────────────────────────────────────────────────────────
// OSRM routing
// ─────────────────────────────────────────────────────────
Future<List<LatLng>> fetchOsrmRoute(List<LatLng> waypoints) async {
  if (waypoints.length < 2) return waypoints;
  final coords =
      waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
  final url = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson',
  );
  try {
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return waypoints;
    final body  = jsonDecode(res.body);
    final route = body['routes']?[0];
    if (route == null) return waypoints;
    final coords2 = route['geometry']['coordinates'] as List;
    return coords2
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  } catch (_) {
    return waypoints;
  }
}

// ─────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────
class SesiPatroliScreen extends StatefulWidget {
  final int idJadwalAbsensi;
  const SesiPatroliScreen({super.key, required this.idJadwalAbsensi});

  @override
  State<SesiPatroliScreen> createState() => _SesiPatroliScreenState();
}

class _SesiPatroliScreenState extends State<SesiPatroliScreen> {
  final _repo    = PatroliRepository();
  final _mapCtrl = MapController();

  PatroliModel? _sesi;
  bool          _loading      = true;
  String?       _error;
  LatLng?       _myPos;
  Timer?        _lokasiTimer;
  List<LatLng>  _routePoints  = [];
  bool          _loadingRoute = false;

  // Apakah sedang mengambil GPS untuk buka laporan
  int? _loadingCheckpointId;

  // Map status draft lokal: cpId → true jika ada draft tersimpan di HP
  Map<int, bool> _localDraftMap = {};

  // Apakah sedang proses kirim semua laporan
  bool _sending = false;

  // Nama petugas (dari AuthProvider)
  String _namaPetugas = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _lokasiTimer?.cancel();
    super.dispose();
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _init() async {
    // Ambil nama petugas dari AuthProvider
    if (mounted) {
      _namaPetugas = context.read<AuthProvider>().user?.nama ?? '';
    }
    await _loadSesi();
    await _startTracking();
  }

  // ── Load data sesi ──────────────────────────────────
  Future<void> _loadSesi() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.getSesi(
        token: _token,
        idJadwalAbsensi: widget.idJadwalAbsensi,
      );
      setState(() => _sesi = data);

      // Baca status draft lokal setelah sesi server selesai di-load
      await _refreshDraftMap(data);

      if (data.checkpoints.length >= 2) {
        setState(() => _loadingRoute = true);
        final waypoints = data.checkpoints
            .map((cp) => LatLng(cp.latitude, cp.longitude))
            .toList();
        final route = await fetchOsrmRoute(waypoints);
        if (mounted) {
          setState(() { _routePoints = route; _loadingRoute = false; });
        }
      }

      if (data.checkpoints.isNotEmpty) {
        final cp = data.checkpoints.first;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _mapCtrl.move(LatLng(cp.latitude, cp.longitude), 15);
        });
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Baca status draft lokal dari SharedPreferences
  Future<void> _refreshDraftMap(PatroliModel data) async {
    final cpIds = data.checkpoints.map((cp) => cp.id).toList();
    final draftMap = await PatroliDraftService.getDraftStatusMap(
      widget.idJadwalAbsensi,
      cpIds,
    );
    if (mounted) setState(() => _localDraftMap = draftMap);
  }

  // ── Tracking lokasi petugas (setiap 15 detik) ───────
  Future<void> _startTracking() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _myPos = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}

    _lokasiTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        if (!mounted) return;
        setState(() => _myPos = LatLng(pos.latitude, pos.longitude));
        await _repo.updateLokasi(
          token: _token,
          idJadwalAbsensi: widget.idJadwalAbsensi,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      } catch (_) {}
    });
  }

  void _flyToMe() {
    if (_myPos != null) _mapCtrl.move(_myPos!, 16);
  }

  // ── Buka form buat/edit laporan ─────────────────────
  Future<void> _buatLaporan(CheckpointPatroli cp) async {
    if (_loadingCheckpointId != null) return;

    setState(() => _loadingCheckpointId = cp.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 12),
          Text('Mengambil lokasi…'),
        ]),
        duration: Duration(seconds: 15),
        backgroundColor: Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      // 1. Cek & minta izin GPS
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showInfoDialog(
          icon: Icons.location_disabled_rounded,
          iconColor: const Color(0xFFDC2626),
          title: 'Izin Lokasi Diperlukan',
          body: 'Aktifkan izin lokasi di pengaturan perangkat '
              'untuk membuat laporan patroli.',
        );
        return;
      }

      // 2. Ambil posisi petugas
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;

      // 3. Validasi jarak
      final jarakMeter = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        cp.latitude,
        cp.longitude,
      );

      const toleransi = 30.0;

      if (jarakMeter > toleransi) {
        _showInfoDialog(
          icon: Icons.location_off_rounded,
          iconColor: const Color(0xFFDC2626),
          title: 'Terlalu Jauh dari Checkpoint',
          body: 'Anda berada ${jarakMeter.round()} m dari checkpoint '
              '"${cp.namaCheckpoint}". '
              'Dekati checkpoint hingga dalam radius $toleransi m '
              'untuk membuat laporan.',
        );
        return;
      }

      setState(() => _myPos = LatLng(pos.latitude, pos.longitude));

      // 4. Baca draft yang sudah ada (jika ada) untuk pre-fill form
      final existingDraft = await PatroliDraftService.getDraft(
        widget.idJadwalAbsensi,
        cp.id,
      );

      // 5. Buka form laporan
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BuatLaporanScreen(
            checkpoint       : cp,
            idJadwalAbsensi  : widget.idJadwalAbsensi,
            tanggal          : _sesi?.tanggal  ?? '',
            jamShift         : _sesi?.jamShift ?? '',
            petugasLatitude  : pos.latitude,
            petugasLongitude : pos.longitude,
            token            : _token,
            namaPetugas      : _namaPetugas,
            existingDraft    : existingDraft, // pre-fill jika ada draft
          ),
        ),
      );

      // 6. Refresh status draft lokal jika laporan berhasil disimpan
      if (result == true && mounted && _sesi != null) {
        await _refreshDraftMap(_sesi!);
      }

    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showInfoDialog(
          icon: Icons.gps_off_rounded,
          iconColor: const Color(0xFFDC2626),
          title: 'GPS Tidak Tersedia',
          body: 'Gagal mendapatkan lokasi. Pastikan GPS aktif lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCheckpointId = null);
    }
  }

  // ── Kirim semua laporan ke server ───────────────────
  Future<void> _kirimSemuaLaporan() async {
    final sesi = _sesi;
    if (sesi == null) return;

    // Kumpulkan semua checkpoint yang punya draft lokal
    final cpIds = sesi.checkpoints.map((cp) => cp.id).toList();
    final allDrafts = await PatroliDraftService.getAllDrafts(
      widget.idJadwalAbsensi,
      cpIds,
    );

    // Hanya kirim checkpoint yang belum ada di database
    final draftToSend = <int, PatroliDraftModel>{};
    for (final cp in sesi.checkpoints) {
      if (!cp.sudahDilaporkan && allDrafts.containsKey(cp.id)) {
        draftToSend[cp.id] = allDrafts[cp.id]!;
      }
    }

    if (draftToSend.isEmpty) {
      _showInfoDialog(
        icon: Icons.info_outline_rounded,
        iconColor: _C.blue,
        title: 'Tidak Ada Draft',
        body: 'Semua laporan sudah terkirim ke server.',
      );
      return;
    }

    // Tampilkan loading dialog
    setState(() => _sending = true);
    _showSendingDialog(total: draftToSend.length);

    int berhasil = 0;
    String? errorMsg;

    for (final entry in draftToSend.entries) {
      final draft = entry.value;
      try {
        // Konversi foto path lokal ke XFile
        final photos = draft.fotoPaths
            .where((p) => File(p).existsSync())
            .map((p) => XFile(p))
            .toList();

        await _repo.buatLaporan(
          token             : _token,
          idJadwalAbsensi   : draft.idJadwalAbsensi,
          idRuteCheckpoint  : draft.idRuteCheckpoint,
          kondisi           : draft.kondisi,
          catatan           : draft.catatan,
          petugasLatitude   : draft.petugasLatitude,
          petugasLongitude  : draft.petugasLongitude,
          photos            : photos,
          waktuLaporan      : draft.waktuLaporan,
          namaPetugas       : _namaPetugas,
          skipDistanceCheck : true, // jarak sudah divalidasi saat simpan lokal
        );

        // Hapus draft yang berhasil dikirim satu per satu
        await PatroliDraftService.deleteDraft(
          widget.idJadwalAbsensi,
          draft.idRuteCheckpoint,
        );

        berhasil++;
      } catch (e) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
        break; // hentikan jika ada error, draft yang belum terkirim tetap ada
      }
    }

    if (!mounted) return;

    // Tutup dialog loading
    Navigator.of(context, rootNavigator: true).pop();
    setState(() => _sending = false);

    if (errorMsg != null) {
      // Ada error — draft tetap ada untuk coba ulang
      _showKirimErrorDialog(
        berhasil: berhasil,
        total: draftToSend.length,
        message: errorMsg,
      );
    } else {
      // Semua berhasil
      await _refreshDraftMap(sesi);
      await _loadSesi();
      _showSuksesDialog();
    }
  }

  // ── Dialog loading saat kirim ────────────────────────
  void _showSendingDialog({required int total}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const CircularProgressIndicator(color: _C.blue),
              const SizedBox(height: 20),
              const Text(
                'Mengirim Laporan…',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _C.blueDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Mengunggah $total laporan checkpoint\nke server…',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.muted, fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog sukses setelah kirim ─────────────────────
  void _showSuksesDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                color: _C.green, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Laporan Terkirim!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.blueDark,
              ),
            ),
          ),
        ]),
        content: const Text(
          'Semua laporan patroli berhasil dikirim ke server. Sesi patroli selesai.',
          style: TextStyle(color: _C.muted, fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Dialog error saat kirim ──────────────────────────
  void _showKirimErrorDialog({
    required int    berhasil,
    required int    total,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFDC2626), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pengiriman Gagal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.blueDark,
              ),
            ),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$berhasil dari $total laporan berhasil terkirim.',
              style: const TextStyle(
                  color: _C.blueDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(
                    color: _C.muted, fontSize: 13, height: 1.5)),
            const SizedBox(height: 8),
            const Text(
              'Draft yang belum terkirim masih tersimpan. Coba kirim ulang.',
              style: TextStyle(
                  color: _C.muted, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Refresh agar status yang sudah berhasil terlihat
              if (_sesi != null) _refreshDraftMap(_sesi!);
              _loadSesi();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tutup',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Dialog konfirmasi keluar ─────────────────────────
  Future<bool> _onWillPop() async {
    final hasDraft = await PatroliDraftService.hasAnyDraft(
      widget.idJadwalAbsensi,
      _sesi?.checkpoints.map((cp) => cp.id).toList() ?? [],
    );

    if (!hasDraft || !mounted) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.amber.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: _C.amber, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Draft Belum Dikirim',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.blueDark,
              ),
            ),
          ),
        ]),
        content: const Text(
          'Masih ada laporan yang belum dikirim ke server.\n\n'
          'Draft tersimpan di HP dan bisa Anda kirim lain kali saat kembali ke halaman ini.',
          style: TextStyle(color: _C.muted, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap di Sini',
                style: TextStyle(color: _C.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Keluar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showInfoDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _C.blueDark)),
          ),
        ]),
        content: Text(body,
            style: const TextStyle(
                color: _C.muted, fontSize: 14, height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tutup',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _C.bgPage,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Back button row ──
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final canPop = await _onWillPop();
                        if (canPop && mounted) Navigator.pop(context);
                      },
                      child: const Icon(Icons.arrow_back,
                          color: _C.blueDark, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SESI PATROLI',
                      style: TextStyle(
                        color: _C.blueDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    // Badge jumlah draft
                    if (_localDraftMap.values.any((v) => v)) ...[
                      const SizedBox(width: 8),
                      _buildDraftBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // ── Card putih pembungkus seluruh konten ──
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(color: _C.blue))
                          : _error != null
                              ? _buildError()
                              : _sesi == null
                                  ? const SizedBox()
                                  : _buildBody(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Badge jumlah draft tersimpan di header
  Widget _buildDraftBadge() {
    final count = _localDraftMap.values.where((v) => v).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.amber),
      ),
      child: Text(
        '$count Draft',
        style: const TextStyle(
          color: Color(0xFF92400E),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────
  Widget _buildBody() {
    final sesi = _sesi!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSesiHeaderCard(sesi),
          const SizedBox(height: 16),
          _buildMapSection(sesi),
          const SizedBox(height: 20),
          _buildCheckpointSection(sesi),
          const SizedBox(height: 16),
          _buildKirimButton(sesi),
          const SizedBox(height: 12),
          _buildSOSButton(),
        ],
      ),
    );
  }

  // ── Header Card ──────────────────────────────────────
  Widget _buildSesiHeaderCard(PatroliModel sesi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _C.blueCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _C.blueCard.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesi Patroli',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sesi.jamShift.isNotEmpty ? sesi.jamShift : sesi.namaRute,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Peta ─────────────────────────────────────────────
  Widget _buildMapSection(PatroliModel sesi) {
    final routeToShow = _routePoints.isNotEmpty
        ? _routePoints
        : sesi.checkpoints
            .map((cp) => LatLng(cp.latitude, cp.longitude))
            .toList();

    final center = sesi.checkpoints.isNotEmpty
        ? LatLng(sesi.checkpoints.first.latitude,
            sesi.checkpoints.first.longitude)
        : const LatLng(-7.05, 110.437);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 260,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.aegis.app',
                  ),
                  if (routeToShow.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routeToShow,
                          strokeWidth: 6,
                          color: _C.blue.withOpacity(0.22),
                        ),
                        Polyline(
                          points: routeToShow,
                          strokeWidth: 3.5,
                          color: _C.blue,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      ...sesi.checkpoints.map(_buildCheckpointMarker),
                      if (_myPos != null)
                        Marker(
                          point: _myPos!,
                          width: 48, height: 48,
                          child: _MyLocationDot(),
                        ),
                    ],
                  ),
                ],
              ),

              if (_loadingRoute)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _C.blue),
                    ),
                  ),
                ),

              Positioned(
                bottom: 12, right: 12,
                child: GestureDetector(
                  onTap: _flyToMe,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location_rounded,
                        color: _C.blue, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Marker _buildCheckpointMarker(CheckpointPatroli cp) {
    final done    = cp.sudahDilaporkan;
    final isDraft = !done && (_localDraftMap[cp.id] == true);

    // Warna: hijau=selesai DB, amber=draft lokal, biru=belum
    final color = done ? _C.green : (isDraft ? _C.amber : _C.blue);

    return Marker(
      point: LatLng(cp.latitude, cp.longitude),
      width: 42, height: 52,
      child: GestureDetector(
        onTap: () => _mapCtrl.move(LatLng(cp.latitude, cp.longitude), 17),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : isDraft
                        ? const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 14)
                        : Text(
                            '${cp.urutan}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
              ),
            ),
            Container(width: 3, height: 7, color: color),
          ],
        ),
      ),
    );
  }

  // ── Daftar Checkpoint ─────────────────────────────────
  Widget _buildCheckpointSection(PatroliModel sesi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Patroli',
          style: TextStyle(
            color: _C.blueDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...sesi.checkpoints.map((cp) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCheckpointTile(cp),
            )),
      ],
    );
  }

  Widget _buildCheckpointTile(CheckpointPatroli cp) {
    final done       = cp.sudahDilaporkan;          // sudah di database
    final isDraft    = !done && (_localDraftMap[cp.id] == true); // draft lokal
    final isLoading  = _loadingCheckpointId == cp.id;
    final anyLoading = _loadingCheckpointId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDraft
            ? Border.all(color: _C.amber.withOpacity(0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox / Draft indicator
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: done
                  ? _C.green
                  : isDraft
                      ? _C.amber.withOpacity(0.15)
                      : Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: done
                    ? _C.green
                    : isDraft
                        ? _C.amber
                        : const Color(0xFFCBD5E1),
                width: 1.8,
              ),
            ),
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : isDraft
                    ? const Icon(Icons.edit_rounded,
                        color: _C.amber, size: 13)
                    : null,
          ),
          const SizedBox(width: 10),

          // Nomor urutan
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: done ? _C.green : (isDraft ? _C.amber : _C.blue),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${cp.urutan}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nama checkpoint
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cp.namaCheckpoint,
                  style: const TextStyle(
                    color: _C.blueDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isDraft) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Draft tersimpan — tekan untuk edit',
                    style: TextStyle(
                      color: _C.amber,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Tombol aksi
          if (done)
            // Selesai di DB — tidak bisa edit
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Color(0xFF166534), size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Selesai',
                    style: TextStyle(
                      color: Color(0xFF166634),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            // Belum selesai di DB — bisa buat/edit laporan (jika draft)
            GestureDetector(
              onTap: anyLoading ? null : () => _buatLaporan(cp),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isLoading
                      ? const Color(0xFFF1F5F9)
                      : isDraft
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(20),
                  border: isDraft
                      ? Border.all(color: _C.amber.withOpacity(0.5))
                      : null,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _C.blue),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDraft
                                ? Icons.edit_rounded
                                : Icons.description_rounded,
                            color: anyLoading
                                ? const Color(0xFFB0BEC5)
                                : isDraft
                                    ? const Color(0xFF92400E)
                                    : const Color(0xFF64748B),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isDraft ? 'Edit' : 'Buat Laporan',
                            style: TextStyle(
                              color: anyLoading
                                  ? const Color(0xFFB0BEC5)
                                  : isDraft
                                      ? const Color(0xFF92400E)
                                      : const Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tombol Kirim Laporan ──────────────────────────────
  Widget _buildKirimButton(PatroliModel sesi) {
    // Aktif jika semua checkpoint sudah selesai di DB ATAU punya draft lokal
    final allCovered = sesi.checkpoints.isNotEmpty &&
        sesi.checkpoints.every((cp) =>
            cp.sudahDilaporkan || (_localDraftMap[cp.id] == true));

    // Hitung berapa yang masih draft (belum dikirim ke server)
    final draftCount = sesi.checkpoints
        .where((cp) => !cp.sudahDilaporkan && (_localDraftMap[cp.id] == true))
        .length;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (allCovered && !_sending && draftCount > 0)
            ? _kirimSemuaLaporan
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: (allCovered && draftCount > 0) ? _C.blue : const Color(0xFFCBD5E1),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26)),
          elevation: (allCovered && draftCount > 0) ? 2 : 0,
        ),
        child: _sending
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    draftCount > 0
                        ? 'Kirim $draftCount Laporan'
                        : 'Kirim Laporan',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Tombol SOS (navigasi langsung tanpa konfirmasi keluar) ──
  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () {
        // Navigasi ke SOS tanpa dialog konfirmasi dan TANPA hapus draft
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SOSFormScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFF09FA6).withOpacity(0.45),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFED4D5C), Color(0xFFF27855)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'KIRIM SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(Icons.shield_outlined,
                      size: 26, color: Colors.white),
                  const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadSesi,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Dot lokasi saya (pulse animation)
// ─────────────────────────────────────────────────────────
class _MyLocationDot extends StatefulWidget {
  @override
  State<_MyLocationDot> createState() => _MyLocationDotState();
}

class _MyLocationDotState extends State<_MyLocationDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _scale,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}