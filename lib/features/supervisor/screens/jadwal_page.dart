// FILE: jadwal_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import 'detail_absensi_page.dart';
import 'widgets/aegis_top_header.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

class JadwalData {
  final int? id;
  final String nama;
  final String pos;
  final String tanggal;
  final String hari;
  final String shift;
  final String waktu;
  final String status;
  final String? fotoProfil;
  final String? jamMasuk;        // ← TAMBAH
  final String? jamPulang;       // ← TAMBAH
  final String? fotoAbsensiMasuk;
  final String? fotoAbsensiPulang;

  const JadwalData({
    this.id,
    required this.nama,
    required this.pos,
    required this.tanggal,
    required this.hari,
    required this.shift,
    required this.waktu,
    required this.status,
    this.fotoProfil,
    this.jamMasuk,               // ← TAMBAH
    this.jamPulang,              // ← TAMBAH
    this.fotoAbsensiMasuk,
    this.fotoAbsensiPulang,
  });

  factory JadwalData.fromJson(Map<String, dynamic> json) {
    final petugas = _asMap(json['petugas']) ??
        _asMap(json['user']) ??
        _asMap(json['pegawai']) ??
        _asMap(json['anggota']);
    final shift = _asMap(json['shift']);
    final pos = _asMap(json['pos_jaga']) ??
        _asMap(json['lokasi']) ??
        _asMap(json['lokasi_jaga']) ??
        _asMap(json['pos']);

    final rawTanggal = _readString(json, ['tanggal', 'date']);
    final rawPos = _readString(pos, ['nama', 'pos_jaga']) ??
        _readString(json, ['pos_jaga', 'pos']) ??
        'Pos Utama';
    final rawMulai = _readString(json, ['jam_mulai', 'mulai']) ??
        _readString(shift, ['jam_mulai', 'mulai']);
    final rawSelesai = _readString(json, ['jam_selesai', 'selesai']) ??
        _readString(shift, ['jam_selesai', 'selesai']);
    final rawStatus = _readString(json, ['status']);

    return JadwalData(
      id: _readInt(json, ['id_jadwal_absensi', 'id']),
      nama: _readString(json, ['nama_petugas', 'nama']) ??
          _readString(petugas, ['nama']) ??
          'Petugas',
      pos: rawPos,
      tanggal: _formatTanggal(rawTanggal),
      hari: _namaHari(rawTanggal, _readString(json, ['hari'])),
      shift: _readString(json, ['nama_shift', 'shift']) ??
          _readString(shift, ['nama']) ??
          'Shift',
      waktu: '${_formatJam(rawMulai)} - ${_formatJam(rawSelesai)}',
      status: _normalizeStatus(rawStatus),
      fotoProfil: _buildFotoUrl(
          _readString(json, ['foto_profil']) ?? _readString(petugas, ['foto_profil'])),
      jamMasuk: _formatJam(_readString(json, ['jam_masuk'])),   // ← TAMBAH
      jamPulang: _formatJam(_readString(json, ['jam_pulang'])), // ← TAMBAH
      fotoAbsensiMasuk: _buildFotoUrl(
          _readString(json, ['foto_absensi_masuk']) ?? _readString(json, ['foto_masuk'])),
      fotoAbsensiPulang: _buildFotoUrl(
          _readString(json, ['foto_absensi_pulang']) ?? _readString(json, ['foto_pulang'])),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static String? _readString(Map<String, dynamic>? src, List<String> keys) {
    if (src == null) return null;
    for (final k in keys) {
      final v = src[k];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> src, List<String> keys) {
    for (final k in keys) {
      final v = src[k];
      if (v is int) return v;
      if (v != null) return int.tryParse(v.toString());
    }
    return null;
  }

  static String _normalizeStatus(String? raw) {
    final v = (raw ?? 'menunggu').toLowerCase().trim();
    if (v.contains('hadir')) return 'HADIR';
    if (v.contains('telat') || v.contains('terlambat')) return 'TERLAMBAT';
    if (v.contains('alpha') || v.contains('alpa')) return 'ALPHA';
    if (v.contains('libur')) return 'LIBUR';
    return 'MENUNGGU';
  }

  static String _formatJam(String? raw) {
    if (raw == null || raw.isEmpty || raw == '-') return '--:--';
    final p = raw.split(':');
    if (p.length >= 2) return '${p[0].padLeft(2, '0')}:${p[1]}';
    return raw;
  }

  static String _formatTanggal(String? raw) {
    final d = DateTime.tryParse(raw ?? '');
    if (d == null) return raw ?? '-';
    return '${_hariIndonesia(d.weekday)}, ${d.day.toString().padLeft(2, '0')} '
        '${_bulanIndonesia(d.month)} ${d.year}';
  }

  static String _namaHari(String? rawTanggal, String? rawHari) {
    if (rawHari != null && rawHari.trim().isNotEmpty) {
      final lo = rawHari.toLowerCase();
      return '${lo[0].toUpperCase()}${lo.substring(1)}';
    }
    final d = DateTime.tryParse(rawTanggal ?? '');
    return _hariIndonesia(d?.weekday ?? 1);
  }

  static String _hariIndonesia(int w) =>
      const {1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis', 5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'}[w] ?? 'Senin';

  static String _bulanIndonesia(int m) =>
      const {1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April', 5: 'Mei', 6: 'Juni', 7: 'Juli', 8: 'Agustus', 9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember'}[m] ?? '';

  static String? _buildFotoUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final resolved = raw
        .replaceAll('http://127.0.0.1:54321', AppConfig.supabaseUrl)
        .replaceAll('http://localhost:54321', AppConfig.supabaseUrl);
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) return resolved;
    final cleaned = resolved.startsWith('/') ? resolved.substring(1) : resolved;
    return '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.supabaseBucket}/$cleaned';
  }
}

// ─── Page ────────────────────────────────────────────────────────────────────

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});
  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  static const _blue = Color(0xFF1969C9);
  static const _navy = Color(0xFF071B2F);
  static const _bg   = Color(0xFFE4F2FD);

  static const double _listPanelHeight = 320.0;

  final List<String> _days = const ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];

  String _activeDay      = 'Senin';
  String _selectedPos    = 'Semua Pos';
  String _selectedStatus = 'Semua Status';
  String _historyStatus  = 'Semua';
  DateTime? _historyTanggal;
  bool _loading = true;
  String? _error;
  List<JadwalData>  _jadwal       = [];
  List<JadwalData>? _riwayatJadwal;
  List<String>      _masterPos    = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchJadwal());
  }

  // ── fetch ────────────────────────────────────────────────────────────────

  Future<void> _fetchJadwal() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      setState(() { _loading = false; _error = 'Token login tidak tersedia.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([_getSupervisorJadwal(token), _getMasterPosJaga(token)]);
      if (!mounted) return;
      setState(() {
        _jadwal    = results[0] as List<JadwalData>;
        _masterPos = results[1] as List<String>;
        if (_jadwal.isNotEmpty) _activeDay = _jadwal.first.hari;
        _selectedPos    = 'Semua Pos';
        _selectedStatus = 'Semua Status';
        _riwayatJadwal  = null;
        _historyTanggal = null;
        _historyStatus  = 'Semua';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<List<JadwalData>> _getSupervisorJadwal(String token) async {
    final endpoints = [
      '${ApiClient.baseUrl}/supervisor/jadwal/mingguan',
      '${ApiClient.baseUrl}/supervisor/jadwal',
    ];
    final results  = <JadwalData>[];
    final seenKeys = <String>{};
    Object? lastError;
    for (final ep in endpoints) {
      try {
        final resp = await http.get(Uri.parse(ep), headers: ApiClient.headers(token: token));
        if (resp.statusCode != 200) { lastError = 'Gagal memuat jadwal (${resp.statusCode})'; continue; }
        for (final item in _extractList(jsonDecode(resp.body)).whereType<Map>()) {
          final data = JadwalData.fromJson(Map<String, dynamic>.from(item));
          final key  = data.id != null ? 'id:${data.id}' : '${data.pos}|${data.hari}|${data.shift}|${data.nama}';
          if (seenKeys.add(key)) results.add(data);
        }
      } catch (e) { lastError = e; }
    }
    if (results.isNotEmpty) return results;
    throw Exception(lastError ?? 'Gagal memuat jadwal dari database.');
  }

  Future<void> _applyRiwayatFilter() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    setState(() => _loading = true);
    try {
      final params = <String, String>{};
      if (_historyStatus != 'Semua') params['status'] = _historyStatus.toLowerCase();
      if (_historyTanggal != null) {
        final t = _historyTanggal!;
        params['tanggal'] = '${t.year}-${t.month.toString().padLeft(2,'0')}-${t.day.toString().padLeft(2,'0')}';
      }
      final uri = Uri.parse('${ApiClient.baseUrl}/supervisor/riwayat-absensi')
          .replace(queryParameters: params.isEmpty ? null : params);
      final resp = await http.get(uri, headers: ApiClient.headers(token: token));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final results  = <JadwalData>[];
        final seenKeys = <String>{};
        for (final item in _extractList(jsonDecode(resp.body)).whereType<Map>()) {
          final data = JadwalData.fromJson(Map<String, dynamic>.from(item));
          final key  = data.id != null ? 'id:${data.id}' : '${data.pos}|${data.hari}|${data.shift}|${data.nama}';
          if (seenKeys.add(key)) results.add(data);
        }
        setState(() { _riwayatJadwal = results; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<String>> _getMasterPosJaga(String token) async {
    try {
      final resp = await http.get(
          Uri.parse('${ApiClient.baseUrl}/supervisor/pos-jaga'),
          headers: ApiClient.headers(token: token));
      if (resp.statusCode != 200) return [];
      final names = <String>{};
      for (final item in _extractList(jsonDecode(resp.body)).whereType<Map>()) {
        final n = Map<String, dynamic>.from(item)['nama'] ?? item['nama_pos'];
        if (n != null) names.add(n.toString().trim());
      }
      return names.toList()..sort();
    } catch (_) { return []; }
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return const [];
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  // ── computed ──────────────────────────────────────────────────────────────

  List<JadwalData> get _filteredJadwal => _jadwal.where((e) {
    final sameDay    = e.hari.toLowerCase() == _activeDay.toLowerCase();
    final samePos    = _selectedPos    == 'Semua Pos'    || e.pos.trim().toLowerCase() == _selectedPos.trim().toLowerCase();
    final sameStatus = _selectedStatus == 'Semua Status' || e.status == _selectedStatus;
    return sameDay && samePos && sameStatus;
  }).toList();

  List<JadwalData> get _historyJadwal {
    final source    = _riwayatJadwal ?? _jadwal;
    final todayDate = DateTime.now().let((n) => DateTime(n.year, n.month, n.day));
    return source.where((item) {
      final parts  = item.tanggal.split(', ');
      final parsed = _parseTanggalIndonesia(parts.length > 1 ? parts[1] : item.tanggal);
      if (parsed == null || !parsed.isBefore(todayDate)) return false;
      if (_historyTanggal != null) {
        final sel = DateTime(_historyTanggal!.year, _historyTanggal!.month, _historyTanggal!.day);
        return parsed == sel;
      }
      if (_riwayatJadwal == null && _historyStatus != 'Semua') return item.status == _historyStatus;
      return true;
    }).toList();
  }

  DateTime? _parseTanggalIndonesia(String text) {
    const bulan = {'Januari':1,'Februari':2,'Maret':3,'April':4,'Mei':5,'Juni':6,'Juli':7,'Agustus':8,'September':9,'Oktober':10,'November':11,'Desember':12};
    final p = text.trim().split(' ');
    if (p.length < 3) return null;
    final d = int.tryParse(p[0]), m = bulan[p[1]], y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  List<String> get _posOptions {
    final base      = _masterPos.isNotEmpty ? _masterPos : ['Pos Jaga Utama','Pos Jaga Tengah','Pos Jaga Selatan'];
    final collected = _jadwal.map((e) => e.pos).where((e) => e.trim().isNotEmpty).toSet();
    return ['Semua Pos', ...({...base,...collected}.toList()..sort())];
  }

  int _count(String status) => _jadwal.where((e) => e.status == status).length;

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          const AegisTopHeader(),
          Expanded(child: RefreshIndicator(
            color: _blue,
            onRefresh: _fetchJadwal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 112),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 20),
                _buildSectionTitle('Jadwal Minggu Ini', subtitle: 'Monitoring kehadiran petugas'),
                const SizedBox(height: 18),
                _buildSummaryCards(),
                const SizedBox(height: 20),
                _buildDaysFilter(),
                const SizedBox(height: 14),
                _buildLocationAndStatusFilter(),
                const SizedBox(height: 20),
                _buildListHeader('DAFTAR PETUGAS', Icons.groups_2_outlined),
                _buildScrollablePanel(_loading, _error, _filteredJadwal),
                const SizedBox(height: 26),
                _buildSectionTitle('RIWAYAT JADWAL'),
                const SizedBox(height: 14),
                _buildRiwayatFilterCard(),
                const SizedBox(height: 14),
                _buildRiwayatPanel(),
              ]),
            ),
          )),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PANELS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScrollablePanel(bool loading, String? error, List<JadwalData> data) {
    return Container(
      height: _listPanelHeight,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 8, offset: const Offset(0,3))],
      ),
      child: _buildPanelContent(loading: loading, error: error, data: data),
    );
  }

  Widget _buildRiwayatPanel() {
    return SizedBox(
      height: _listPanelHeight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 8, offset: const Offset(0,3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _buildPanelContent(loading: _loading, error: null, data: _historyJadwal, showTanggal: true),
        ),
      ),
    );
  }

  Widget _buildPanelContent({
    required bool loading,
    String? error,
    required List<JadwalData> data,
    bool showTanggal = false,
  }) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _blue));
    if (error != null) return _buildMessageCard(
      icon: Icons.wifi_off_rounded,
      title: 'Jadwal belum dapat dimuat',
      message: error,
      action: TextButton(onPressed: _fetchJadwal, child: const Text('Coba Lagi')),
    );
    if (data.isEmpty) {
      return Center(child: _buildMessageCard(
        icon: Icons.event_busy_rounded,
        title: 'Tidak ada jadwal',
        message: 'Data jadwal untuk filter ini belum tersedia.',
      ));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        physics: const BouncingScrollPhysics(),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildCardPetugas(data[i], showTanggal: showTanggal),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 5,
          height: subtitle != null ? 48 : 24,
          decoration: BoxDecoration(color: const Color(0xFF0D6AE4), borderRadius: BorderRadius.circular(1)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1, color: Color(0xFF071226))),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5565), fontWeight: FontWeight.w400)),
          ],
        ])),
      ]),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        Row(children: [
          Expanded(child: _buildSummaryBox('TOTAL HADIR',  _count('HADIR').toString().padLeft(2,'0'),     Icons.check_circle,    const Color(0xFFB4E5BF), const Color(0xFF087A32))),
          const SizedBox(width: 14),
          Expanded(child: _buildSummaryBox('TERLAMBAT',    _count('TERLAMBAT').toString().padLeft(2,'0'), Icons.access_time,     const Color(0xFFFFE9CC), const Color(0xFF8E3F0C))),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _buildSummaryBox('ALPHA',        _count('ALPHA').toString().padLeft(2,'0'),     Icons.cancel_outlined, const Color(0xFFFFE6E7), const Color(0xFFD61D1D))),
          const SizedBox(width: 14),
          Expanded(child: _buildSummaryBox('MENUNGGU',     _count('MENUNGGU').toString().padLeft(2,'0'),  Icons.more_horiz,      const Color(0xFFB5C9E7), _navy, leftBorder: true)),
        ]),
      ]),
    );
  }

  Widget _buildSummaryBox(String title, String value, IconData icon, Color bg, Color accent, {bool leftBorder = false}) {
    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(16,14,14,14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: leftBorder ? const Border(left: BorderSide(color: Color(0xFF0A2F50), width: 4)) : null,
        boxShadow: [BoxShadow(color: const Color(0xFF7AA5C7).withAlpha(51), blurRadius: 14, offset: const Offset(0,6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF3B4250))),
        Row(children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: accent, height: 1)),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: accent),
        ]),
      ]),
    );
  }

  Widget _buildDaysFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final day    = _days[i];
          final active = _activeDay == day;
          return GestureDetector(
            onTap: () => setState(() => _activeDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF075DD9) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? const Color(0xFF075DD9) : const Color(0xFFC1C7D0), width: 1.2),
              ),
              child: Text(day, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF4A4F59))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationAndStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(children: [
        Expanded(child: PopupMenuButton<String>(
          onSelected: (v) => setState(() => _selectedPos = v),
          offset: const Offset(0, 48),
          itemBuilder: (_) => _posOptions.map((p) => PopupMenuItem(
            value: p,
            child: Text(p, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          )).toList(),
          child: _filterChip(
            icon: Icons.location_on_outlined,
            label: _selectedPos,
            active: _selectedPos != 'Semua Pos',
          ),
        )),
        const SizedBox(width: 10),
        Expanded(child: PopupMenuButton<String>(
          onSelected: (v) => setState(() => _selectedStatus = v),
          offset: const Offset(0, 48),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'Semua Status', child: Text('Semua Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            PopupMenuItem(value: 'HADIR',        child: Text('Hadir',        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            PopupMenuItem(value: 'TERLAMBAT',    child: Text('Terlambat',    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            PopupMenuItem(value: 'ALPHA',        child: Text('Alpha',        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            PopupMenuItem(value: 'MENUNGGU',     child: Text('Menunggu',     style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            PopupMenuItem(value: 'LIBUR',        child: Text('Libur',        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          ],
          child: _filterChip(
            icon: Icons.badge_outlined,
            label: _selectedStatus,
            active: _selectedStatus != 'Semua Status',
          ),
        )),
      ]),
    );
  }

  Widget _filterChip({required IconData icon, required String label, required bool active}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEBF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: active ? _blue : const Color(0xFFB8C1CC), width: 1.2),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: active ? _blue : const Color(0xFF4A4F59)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: active ? _blue : const Color(0xFF2F333B)))),
        Icon(Icons.keyboard_arrow_down, size: 18,
            color: active ? _blue : const Color(0xFF667085)),
      ]),
    );
  }

  Widget _buildListHeader(String title, IconData icon) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        Icon(icon, color: Colors.white.withAlpha(224), size: 24),
      ]),
    );
  }

  Widget _buildCardPetugas(JadwalData data, {bool showTanggal = false}) {
    final badge = _badgeStyle(data.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0,2))],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _buildAvatar(data),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.nama, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF102033))),
            const SizedBox(height: 2),
            Text(data.pos, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF3F4652), fontSize: 12, fontWeight: FontWeight.w500)),
            if (showTanggal) ...[
              const SizedBox(height: 3),
              Text(data.tanggal, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF1969C9), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ])),
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: badge.$1, borderRadius: BorderRadius.circular(14)),
            child: Text(data.status, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: badge.$2, fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ]),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE6EEF8))),
        Row(children: [
          const Icon(Icons.access_time, size: 16, color: Color(0xFF4A4F59)),
          const SizedBox(width: 5),
          Expanded(child: Text('${data.shift} • ${data.waktu}', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF102033)))),
          const SizedBox(width: 8),
          SizedBox(
            width: 72, height: 34,
            child: ElevatedButton(
              // ← PERBAIKAN: teruskan jamMasuk & jamPulang ke DetailAbsensiPage
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailAbsensiPage(
                nama: data.nama,
                tanggal: data.tanggal,
                shift: data.shift,
                waktu: data.waktu,
                pos: data.pos,
                status: data.status,
                jamMasuk: data.jamMasuk,
                jamPulang: data.jamPulang,
                fotoAbsensiMasuk: data.fotoAbsensiMasuk,
                fotoAbsensiPulang: data.fotoAbsensiPulang,
              ))),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
              child: const Text('Lihat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildAvatar(JadwalData data) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFE8EEF7),
      backgroundImage: data.fotoProfil != null ? NetworkImage(data.fotoProfil!) : null,
      child: data.fotoProfil == null
          ? Text(data.nama.isNotEmpty ? data.nama[0].toUpperCase() : '?',
              style: const TextStyle(color: _blue, fontSize: 15, fontWeight: FontWeight.w800))
          : null,
    );
  }

  (Color, Color) _badgeStyle(String s) => switch (s) {
    'HADIR'     => (const Color(0xFFD9F8E5), const Color(0xFF1A8A3F)),
    'TERLAMBAT' => (const Color(0xFFFFEBD5), const Color(0xFFD85A1F)),
    'ALPHA'     => (const Color(0xFFFFE2E2), const Color(0xFFD61D1D)),
    'LIBUR'     => (const Color(0xFFECECFF), const Color(0xFF5A4FCF)),
    _           => (const Color(0xFFDCEAFF), const Color(0xFF1E5AE8)),
  };

  Widget _buildRiwayatFilterCard() {
    final tanggalLabel = _historyTanggal != null
        ? '${_historyTanggal!.day.toString().padLeft(2,'0')}/${_historyTanggal!.month.toString().padLeft(2,'0')}/${_historyTanggal!.year}'
        : 'Semua Tanggal';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0,3))],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _historyTanggal ?? DateTime.now().subtract(const Duration(days: 1)),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().subtract(const Duration(days: 1)),
                locale: const Locale('id', 'ID'),
              );
              if (picked != null) setState(() => _historyTanggal = picked);
            },
            child: _filterField(label: 'TANGGAL', value: tanggalLabel,
                icon: Icons.calendar_today_outlined, muted: _historyTanggal == null),
          )),
          const SizedBox(width: 12),
          Expanded(child: PopupMenuButton<String>(
            onSelected: (v) => setState(() => _historyStatus = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Semua',     child: Text('Semua')),
              PopupMenuItem(value: 'HADIR',     child: Text('Hadir')),
              PopupMenuItem(value: 'TERLAMBAT', child: Text('Terlambat')),
              PopupMenuItem(value: 'ALPHA',     child: Text('Alpha')),
              PopupMenuItem(value: 'MENUNGGU',  child: Text('Menunggu')),
              PopupMenuItem(value: 'LIBUR',     child: Text('Libur')),
            ],
            child: _filterField(label: 'STATUS', value: _historyStatus, icon: Icons.keyboard_arrow_down),
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (_historyTanggal != null || _historyStatus != 'Semua') ...[
            Expanded(flex: 1, child: SizedBox(height: 42,
              child: OutlinedButton.icon(
                onPressed: () => setState(() { _historyTanggal = null; _historyStatus = 'Semua'; _riwayatJadwal = null; }),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A4F59),
                    side: const BorderSide(color: Color(0xFFB8C1CC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    padding: EdgeInsets.zero),
              ),
            )),
            const SizedBox(width: 10),
          ],
          Expanded(flex: 2, child: SizedBox(height: 42,
            child: ElevatedButton.icon(
              onPressed: _applyRiwayatFilter,
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Terapkan Filter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
            ),
          )),
        ]),
      ]),
    );
  }

  Widget _filterField({required String label, required String value, required IconData icon, bool muted = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF7A8493))),
      const SizedBox(height: 6),
      Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFD0D5DD))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: muted ? Colors.black45 : const Color(0xFF2F333B), fontSize: 13, fontWeight: FontWeight.w600))),
          Icon(icon, size: 16, color: const Color(0xFF667085)),
        ]),
      ),
    ]);
  }

  Widget _buildMessageCard({required IconData icon, required String title, required String message, Widget? action}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 30, color: const Color(0xFF667085)),
        const SizedBox(height: 6),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
        if (action != null) ...[const SizedBox(height: 8), action],
      ]),
    );
  }
}

// Dart extension helper
extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}