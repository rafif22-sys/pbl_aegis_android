// lib/features/petugas/screens/buat_laporan_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'widgets/patroli/camera_capture_widget.dart';
import '../models/patroli_draft_model.dart';
import '../models/patroli_model.dart';
import '../services/patroli_draft_service.dart';

class _C {
  static const bgPage   = Color(0xFFDCEFFE);
  static const blue     = Color(0xFF1565C0);
  static const blueCard = Color(0xFF0040A2);
  static const blueDark = Color(0xFF0F2A44);
  static const green    = Color(0xFF22C55E);
  static const muted    = Color(0xFF64748B);
  static const gray     = Color(0xFF94A3B8);
}

enum KondisiPatroli {
  aman('aman'),
  kerusakanFasilitas('kerusakan fasilitas'),
  aktivitasMencurigakan('aktivitas mencurigakan'),
  kebersihan('kebersihan');

  final String label; // nilai yang dikirim ke server (lowercase, sesuai enum DB)
  const KondisiPatroli(this.label);

  // Label tampilan di UI
  String get displayLabel => switch (this) {
    KondisiPatroli.aman                  => 'Aman',
    KondisiPatroli.kerusakanFasilitas    => 'Kerusakan Fasilitas',
    KondisiPatroli.aktivitasMencurigakan => 'Aktivitas Mencurigakan',
    KondisiPatroli.kebersihan            => 'Kebersihan',
  };
}

class BuatLaporanScreen extends StatefulWidget {
  final CheckpointPatroli checkpoint;
  final int    idJadwalAbsensi;
  final String tanggal;
  final String jamShift;
  final double petugasLatitude;
  final double petugasLongitude;
  final String token;
  final String namaPetugas;           // ← untuk path Supabase & key draft
  final PatroliDraftModel? existingDraft; // ← pre-fill jika sudah ada draft

  const BuatLaporanScreen({
    super.key,
    required this.checkpoint,
    required this.idJadwalAbsensi,
    required this.tanggal,
    required this.jamShift,
    required this.petugasLatitude,
    required this.petugasLongitude,
    required this.token,
    required this.namaPetugas,
    this.existingDraft,
  });

  @override
  State<BuatLaporanScreen> createState() => _BuatLaporanScreenState();
}

class _BuatLaporanScreenState extends State<BuatLaporanScreen> {
  KondisiPatroli    _kondisi    = KondisiPatroli.aman;
  final List<XFile> _photos     = [];
  final _catatanCtrl            = TextEditingController();
  bool              _submitting = false;
  final _picker                 = ImagePicker();

  late DateTime _now;
  Timer?        _clockTimer;

  // Waktu laporan dikunci saat halaman dibuka (bukan saat simpan)
  late DateTime _waktuLaporanFixed;

  @override
  void initState() {
    super.initState();
    _waktuLaporanFixed = DateTime.now();
    _now = _waktuLaporanFixed;
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Pre-fill dari draft yang sudah ada
    _prefillFromDraft();
  }

  /// Isi form dari draft tersimpan (jika ada)
  void _prefillFromDraft() {
    final draft = widget.existingDraft;
    if (draft == null) return;

    // Kondisi
    final matchedKondisi = KondisiPatroli.values.where(
      (k) => k.label == draft.kondisi,
    ).firstOrNull;
    if (matchedKondisi != null) _kondisi = matchedKondisi;

    // Catatan
    _catatanCtrl.text = draft.catatan;

    // Foto — konversi path → XFile (hanya jika file masih ada)
    for (final path in draft.fotoPaths) {
      if (File(path).existsSync()) {
        _photos.add(XFile(path));
      }
    }

    // Gunakan waktu laporan dari draft (bukan waktu sekarang)
    try {
      _waktuLaporanFixed = DateTime.parse(draft.waktuLaporan);
    } catch (_) {
      _waktuLaporanFixed = DateTime.now();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _catatanCtrl.dispose();
    super.dispose();
  }

  // ── Format helpers ────────────────────────────────────
  String get _tanggalFormatted {
    try {
      final dt = DateTime.parse(widget.tanggal);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return widget.tanggal;
    }
  }

  String get _waktuNow => DateFormat('HH:mm:ss').format(_now);

  String get _waktuLaporanIso =>
      DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_waktuLaporanFixed);

  // ── Foto ─────────────────────────────────────────────
  Future<void> _ambilFoto() async {
    if (_photos.length >= 6) {
      _showSnack('Maksimal 6 gambar', isError: true);
      return;
    }
    final photo = await CameraCaptureWidget.show(
      context,
      title: 'Foto Checkpoint',
    );
    if (photo != null && mounted) setState(() => _photos.add(photo));
  }

  void _hapusFoto(int index) => setState(() => _photos.removeAt(index));

  // ── Simpan ke local storage (bukan langsung ke server) ────────────────────
  Future<void> _simpanLaporan() async {
    setState(() => _submitting = true);
    try {
      final draft = PatroliDraftModel(
        idJadwalAbsensi  : widget.idJadwalAbsensi,
        idRuteCheckpoint : widget.checkpoint.id,
        kondisi          : _kondisi.label,
        catatan          : _catatanCtrl.text.trim(),
        waktuLaporan     : _waktuLaporanIso,
        petugasLatitude  : widget.petugasLatitude,
        petugasLongitude : widget.petugasLongitude,
        fotoPaths        : _photos.map((f) => f.path).toList(),
      );

      await PatroliDraftService.saveDraft(draft);

      if (mounted) {
        _showSnack('Draft tersimpan! Kirim setelah semua checkpoint selesai.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Gagal menyimpan draft: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFDC2626) : _C.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showErrorDialog(String message) {
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
              'Gagal Menyimpan Draft',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.blueDark,
              ),
            ),
          ),
        ]),
        content: Text(message,
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
    return Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // AppBar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: _C.blueDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'BUAT LAPORAN',
                    style: TextStyle(
                      color: _C.blueDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  // Badge "Edit Draft" jika ada draft sebelumnya
                  if (widget.existingDraft != null) ...[ 
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Text(
                        'Edit Draft',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(),
                          _buildTanggalWaktuRow(),
                          const SizedBox(height: 20),
                          _buildKondisiSection(),
                          const SizedBox(height: 20),
                          _buildFotoSection(),
                          const SizedBox(height: 20),
                          _buildCatatanSection(),
                          const SizedBox(height: 24),
                          _buildSimpanButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Card ─────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
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
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.checkpoint.namaCheckpoint,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.jamShift.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.jamShift,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tanggal + Waktu ───────────────────────────────────
  Widget _buildTanggalWaktuRow() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: _C.muted),
              const SizedBox(width: 6),
              Text(
                _tanggalFormatted,
                style: const TextStyle(
                  color: _C.blueDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: _C.muted),
              const SizedBox(width: 6),
              Text(
                _waktuNow,
                style: const TextStyle(
                  color: _C.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Kondisi ──────────────────────────────────────────
  Widget _buildKondisiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: _C.blueCard,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kondisi',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withOpacity(0.7), size: 22),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: Column(
            children: KondisiPatroli.values.map((k) {
              final selected = _kondisi == k;
              final isLast   = k == KondisiPatroli.values.last;
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _kondisi = k),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? _C.blue
                                    : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                            ),
                            child: selected
                                ? Center(
                                    child: Container(
                                      width: 10, height: 10,
                                      decoration: const BoxDecoration(
                                        color: _C.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            k.displayLabel,
                            style: TextStyle(
                              color: selected ? _C.blue : _C.blueDark,
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Foto ─────────────────────────────────────────────
  Widget _buildFotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Ambil ',
              style: TextStyle(
                  color: _C.blueDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          Text('${_photos.length} - 6 Gambar',
              style: const TextStyle(
                  color: _C.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._photos.asMap().entries
                .map((e) => _buildFotoItem(e.key, e.value)),
            if (_photos.length < 6)
              GestureDetector(
                onTap: _ambilFoto,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: _C.muted, size: 20),
                      ),
                      const SizedBox(height: 6),
                      const Text('Ambil foto',
                          style: TextStyle(
                              color: _C.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFotoItem(int index, XFile file) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PatroliCapturedPhotoPreview(
            imageFile: file,
            width: 90, height: 90,
          ),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () => _hapusFoto(index),
            child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ── Catatan ──────────────────────────────────────────
  Widget _buildCatatanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Text('Catatan',
              style: TextStyle(
                  color: _C.blueDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          SizedBox(width: 6),
          Icon(Icons.description_rounded, color: _C.muted, size: 16),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _catatanCtrl,
          maxLines: 4,
          style: const TextStyle(color: _C.blueDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Deskripsi Keadaan',
            hintStyle: const TextStyle(color: _C.gray, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.blue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Tombol Simpan (ke lokal) ──────────────────────────────
  Widget _buildSimpanButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _submitting ? null : _simpanLaporan,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26)),
          elevation: 2,
        ),
        child: _submitting
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_alt_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.existingDraft != null
                        ? 'Perbarui Draft'
                        : 'Simpan Laporan',
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
}