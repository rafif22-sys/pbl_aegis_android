import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import 'detail_absensi_page.dart';
import 'widgets/aegis_top_header.dart';

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
    this.fotoAbsensiMasuk,
    this.fotoAbsensiPulang,
  });

  factory JadwalData.fromJson(Map<String, dynamic> json) {
    final petugas =
        _asMap(json['petugas']) ??
        _asMap(json['user']) ??
        _asMap(json['pegawai']) ??
        _asMap(json['anggota']);
    final shift = _asMap(json['shift']);
    final pos =
        _asMap(json['pos_jaga']) ??
        _asMap(json['lokasi']) ??
        _asMap(json['lokasi_jaga']) ??
        _asMap(json['pos']);

    final rawTanggal = _readString(json, ['tanggal', 'date']);
    final rawPos = _readString(pos, ['nama', 'pos_jaga']) ?? _readString(json, ['pos_jaga', 'pos']) ?? 'Pos Utama';
    final rawMulai = _readString(json, ['jam_mulai', 'mulai']) ?? _readString(shift, ['jam_mulai', 'mulai']);
    final rawSelesai = _readString(json, ['jam_selesai', 'selesai']) ?? _readString(shift, ['jam_selesai', 'selesai']);
    final rawStatus = _readString(json, ['status']);

    return JadwalData(
      id: _readInt(json, ['id_jadwal_absensi', 'id']),
      nama: _readString(json, ['nama_petugas', 'nama']) ?? _readString(petugas, ['nama']) ?? 'Petugas',
      pos: rawPos,
      tanggal: _formatTanggal(rawTanggal),
      hari: _namaHari(rawTanggal, _readString(json, ['hari'])),
      shift: _readString(json, ['nama_shift', 'shift']) ?? _readString(shift, ['nama']) ?? 'Shift',
      waktu: '${_formatJam(rawMulai)} - ${_formatJam(rawSelesai)}',
      status: _normalizeStatus(rawStatus),
      fotoProfil: _buildFotoUrl(_readString(json, ['foto_profil']) ?? _readString(petugas, ['foto_profil'])),
      fotoAbsensiMasuk: _buildFotoUrl(_readString(json, ['foto_absensi_masuk']) ?? _readString(json, ['foto_masuk'])),
      fotoAbsensiPulang: _buildFotoUrl(_readString(json, ['foto_absensi_pulang']) ?? _readString(json, ['foto_pulang'])),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _readString(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value != null) {
        final str = value.toString().trim();
        if (str.isNotEmpty) return str;
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is int) return value;
      if (value != null) return int.tryParse(value.toString());
    }
    return null;
  }

  static String _normalizeStatus(String? raw) {
    final value = (raw ?? 'menunggu').toLowerCase().trim();
    if (value.contains('hadir')) return 'HADIR';
    if (value.contains('telat') || value.contains('terlambat')) return 'TERLAMBAT';
    if (value.contains('alpha') || value.contains('alpa')) return 'ALPHA';
    return 'MENUNGGU';
  }

  static String _formatJam(String? raw) {
    if (raw == null || raw.isEmpty || raw == '-') return '--:--';
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1]}';
    return raw;
  }

  static String _formatTanggal(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return raw ?? '-';
    return '${_hariIndonesia(date.weekday)}, ${date.day.toString().padLeft(2, '0')} ${_bulanIndonesia(date.month)} ${date.year}';
  }

  static String _namaHari(String? rawTanggal, String? rawHari) {
    if (rawHari != null && rawHari.trim().isNotEmpty) {
      final lower = rawHari.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }
    final date = DateTime.tryParse(rawTanggal ?? '');
    return _hariIndonesia(date?.weekday ?? 1);
  }

  static String _hariIndonesia(int weekday) {
    const days = {1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis', 5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'};
    return days[weekday] ?? 'Senin';
  }

  static String _bulanIndonesia(int month) {
    const months = {1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April', 5: 'Mei', 6: 'Juni', 7: 'Juli', 8: 'Agustus', 9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember'};
    return months[month] ?? '';
  }

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

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  static const _blue = Color(0xFF1969C9);
  static const _navy = Color(0xFF071B2F);
  static const _bg = Color(0xFFE4F2FD);

  final List<String> _days = const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  String _activeDay = 'Senin';
  String _selectedPos = 'Semua Pos';
  String _historyStatus = 'Semua';
  bool _loading = true;
  String? _error;
  List<JadwalData> _jadwal = [];
  List<String> _masterPos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchJadwal());
  }

  Future<void> _fetchJadwal() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Token login tidak tersedia.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _getSupervisorJadwal(token),
        _getMasterPosJaga(token),
      ]);

      if (!mounted) return;
      setState(() {
        _jadwal = results[0] as List<JadwalData>;
        _masterPos = results[1] as List<String>;
        if (_jadwal.isNotEmpty) {
          _activeDay = _jadwal.first.hari;
        }
        _selectedPos = 'Semua Pos';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<List<JadwalData>> _getSupervisorJadwal(String token) async {
    final endpoints = [
      '${ApiClient.baseUrl}/supervisor/jadwal/mingguan',
      '${ApiClient.baseUrl}/supervisor/jadwal',
    ];

    final results = <JadwalData>[];
    final seenKeys = <String>{};
    Object? lastError;

    for (final endpoint in endpoints) {
      try {
        final uri = Uri.parse(endpoint);
        final response = await http.get(uri, headers: ApiClient.headers(token: token));
        if (response.statusCode != 200) {
          lastError = 'Gagal memuat jadwal (${response.statusCode})';
          continue;
        }

        final body = jsonDecode(response.body);
        final list = _extractList(body);
        for (final item in list.whereType<Map>()) {
          final jsonMap = Map<String, dynamic>.from(item);
          final data = JadwalData.fromJson(jsonMap);
          final key = data.id != null ? 'id:${data.id}' : '${data.pos}|${data.hari}|${data.shift}|${data.nama}';
          if (seenKeys.add(key)) {
            results.add(data);
          }
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (results.isNotEmpty) return results;
    throw Exception(lastError ?? 'Gagal memuat jadwal dari database.');
  }

  Future<List<String>> _getMasterPosJaga(String token) async {
    final endpoint = '${ApiClient.baseUrl}/supervisor/pos-jaga';
    try {
      final response = await http.get(Uri.parse(endpoint), headers: ApiClient.headers(token: token));
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body);
      final list = _extractList(body);
      final dynamicPosNames = <String>{};
      for (final item in list.whereType<Map>()) {
        final jsonMap = Map<String, dynamic>.from(item);
        final namaPos = jsonMap['nama'] ?? jsonMap['nama_pos'];
        if (namaPos != null) dynamicPosNames.add(namaPos.toString().trim());
      }
      final res = dynamicPosNames.toList()..sort();
      return res;
    } catch (_) {
      return [];
    }
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return const [];
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  List<JadwalData> get _filteredJadwal {
    return _jadwal.where((item) {
      final sameDay = item.hari.toLowerCase() == _activeDay.toLowerCase();
      final samePos = _selectedPos == 'Semua Pos' || item.pos.trim().toLowerCase() == _selectedPos.trim().toLowerCase();
      return sameDay && samePos;
    }).toList();
  }

  List<JadwalData> get _historyJadwal {
    if (_historyStatus == 'Semua') return _jadwal;
    return _jadwal.where((item) => item.status == _historyStatus).toList();
  }

  List<String> get _posOptions {
    final base = _masterPos.isNotEmpty ? _masterPos : ['Pos Jaga Utama', 'Pos Jaga Tengah', 'Pos Jaga Selatan'];
    final collected = _jadwal.map((e) => e.pos).where((e) => e.trim().isNotEmpty).toSet();
    final combined = {...base, ...collected}.toList()..sort();
    return ['Semua Pos', ...combined];
  }

  int _count(String status) => _jadwal.where((item) => item.status == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            const AegisTopHeader(),
            Expanded(
              child: RefreshIndicator(
                color: _blue,
                onRefresh: _fetchJadwal,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildSectionTitle('Jadwal Minggu Ini', subtitle: 'Monitoring kehadiran petugas'),
                      const SizedBox(height: 22),
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildDaysFilter(),
                      const SizedBox(height: 18),
                      _buildLocationFilter(),
                      const SizedBox(height: 24),
                      _buildListHeader('DAFTAR PETUGAS', Icons.groups_2_outlined),
                      _buildCurrentList(),
                      const SizedBox(height: 30),
                      _buildSectionTitle('RIWAYAT JADWAL'),
                      const SizedBox(height: 16),
                      _buildRiwayatFilterCard(),
                      const SizedBox(height: 20),
                      _buildJadwalList(_historyJadwal),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentList() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator(color: _blue)));
    }
    if (_error != null) {
      return _buildMessageCard(
        icon: Icons.wifi_off_rounded,
        title: 'Jadwal belum dapat dimuat',
        message: _error!,
        action: TextButton(onPressed: _fetchJadwal, child: const Text('Coba Lagi')),
      );
    }
    return _buildJadwalList(_filteredJadwal);
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: subtitle != null ? 54 : 28, decoration: BoxDecoration(color: const Color(0xFF0D6AE4), borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1, color: Color(0xFF071226))),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle, style: const TextStyle(fontSize: 18, color: Color(0xFF4A5565), fontWeight: FontWeight.w400)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryBox('TOTAL HADIR', _count('HADIR').toString().padLeft(2, '0'), Icons.check_circle, const Color(0xFFB4E5BF), const Color(0xFF087A32))),
              const SizedBox(width: 22),
              Expanded(child: _buildSummaryBox('TERLAMBAT', _count('TERLAMBAT').toString().padLeft(2, '0'), Icons.access_time, const Color(0xFFFFE9CC), const Color(0xFF8E3F0C))),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _buildSummaryBox('ALPHA', _count('ALPHA').toString().padLeft(2, '0'), Icons.cancel_outlined, const Color(0xFFFFE6E7), const Color(0xFFD61D1D))),
              const SizedBox(width: 22),
              Expanded(child: _buildSummaryBox('MENUNGGU', _count('MENUNGGU').toString().padLeft(2, '0'), Icons.more_horiz, const Color(0xFFB5C9E7), _navy, leftBorder: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String value, IconData icon, Color bgColor, Color accent, {bool leftBorder = false}) {
    return Container(
      height: 114,
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: leftBorder ? const Border(left: BorderSide(color: Color(0xFF0A2F50), width: 5)) : null,
        boxShadow: [BoxShadow(color: const Color(0xFF7AA5C7).withAlpha(51), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF3B4250))),
          Row(
            children: [
              Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: accent, height: 1)),
              const SizedBox(width: 10),
              Icon(icon, size: 22, color: accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysFilter() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 36),
        itemCount: _days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final day = _days[index];
          final active = _activeDay == day;
          return GestureDetector(
            onTap: () => setState(() => _activeDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 104,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF075DD9) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: active ? const Color(0xFF075DD9) : const Color(0xFFC1C7D0), width: 1.2),
              ),
              child: Text(day, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: active ? Colors.white : const Color(0xFF4A4F59))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        children: [
          Expanded(
            child: PopupMenuButton<String>(
              onSelected: (val) => setState(() => _selectedPos = val),
              offset: const Offset(0, 52),
              itemBuilder: (context) => _posOptions.map((pos) => PopupMenuItem(value: pos, child: Text(pos, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)))).toList(),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFB8C1CC), width: 1.2)),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 24, color: Color(0xFF4A4F59)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_selectedPos, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2F333B)))),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xFF667085)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFB8C1CC), width: 1.2)),
            child: const Icon(Icons.tune, size: 28, color: Color(0xFF4A4F59)),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(String title, IconData icon) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 36),
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: const BoxDecoration(color: _blue, borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5)),
          Icon(icon, color: Colors.white.withAlpha(224), size: 27),
        ],
      ),
    );
  }

  Widget _buildJadwalList(List<JadwalData> data) {
    if (!_loading && data.isEmpty) {
      return _buildMessageCard(icon: Icons.event_busy_rounded, title: 'Tidak ada jadwal', message: 'Data jadwal untuk filter ini belum tersedia.');
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 36),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(color: Colors.white.withAlpha(183), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        separatorBuilder: (_, _) => const SizedBox(height: 18),
        itemBuilder: (context, index) => _buildCardPetugas(data[index]),
      ),
    );
  }

  Widget _buildCardPetugas(JadwalData data) {
    final badge = _badgeStyle(data.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(28), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(data),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF102033))),
                    const SizedBox(height: 4),
                    Text(data.pos, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF3F4652), fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: badge.$1, borderRadius: BorderRadius.circular(18)),
                child: Text(data.status, style: TextStyle(color: badge.$2, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFE6EEF8))),
          Row(
            children: [
              const Icon(Icons.access_time, size: 22, color: Color(0xFF4A4F59)),
              const SizedBox(width: 7),
              Expanded(child: Text('${data.shift} • ${data.waktu}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF102033)))),
              const SizedBox(width: 10),
              SizedBox(
                width: 92,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailAbsensiPage(
                          nama: data.nama,
                          tanggal: data.tanggal,
                          shift: data.shift,
                          waktu: data.waktu,
                          pos: data.pos,
                          status: data.status,
                          fotoAbsensiMasuk: data.fotoAbsensiMasuk,
                          fotoAbsensiPulang: data.fotoAbsensiPulang,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: const Text('Lihat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(JadwalData data) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: const Color(0xFFE8EEF7),
      backgroundImage: data.fotoProfil != null ? NetworkImage(data.fotoProfil!) : null,
      child: data.fotoProfil == null ? Text(data.nama.isNotEmpty ? data.nama[0].toUpperCase() : '?', style: const TextStyle(color: _blue, fontSize: 18, fontWeight: FontWeight.w900)) : null,
    );
  }

  (Color, Color) _badgeStyle(String status) {
    switch (status) {
      case 'HADIR': return (const Color(0xFFD9F8E5), const Color(0xFF1A8A3F));
      case 'TERLAMBAT': return (const Color(0xFFFFEBD5), const Color(0xFFD85A1F));
      case 'ALPHA': return (const Color(0xFFFFE2E2), const Color(0xFFD61D1D));
      default: return (const Color(0xFFDCEAFF), const Color(0xFF1E5AE8));
    }
  }

  Widget _buildRiwayatFilterCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 36),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _filterField(label: 'TANGGAL', value: 'mm/dd/yyyy', icon: Icons.calendar_today_outlined, muted: true)),
              const SizedBox(width: 12),
              Expanded(
                child: PopupMenuButton<String>(
                  onSelected: (value) => setState(() => _historyStatus = value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Semua', child: Text('Semua')),
                    PopupMenuItem(value: 'HADIR', child: Text('Hadir')),
                    PopupMenuItem(value: 'TERLAMBAT', child: Text('Terlambat')),
                    PopupMenuItem(value: 'ALPHA', child: Text('Alpha')),
                    PopupMenuItem(value: 'MENUNGGU', child: Text('Menunggu')),
                  ],
                  child: _filterField(label: 'STATUS', value: _historyStatus, icon: Icons.keyboard_arrow_down),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.filter_list, size: 20),
              label: const Text('Terapkan Filter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterField({required String label, required String value, required IconData icon, bool muted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF7A8493))),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFD0D5DD))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted ? Colors.black45 : const Color(0xFF2F333B), fontSize: 13, fontWeight: FontWeight.w600))),
              Icon(icon, size: 17, color: const Color(0xFF667085)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 36),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xFF667085)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }
}