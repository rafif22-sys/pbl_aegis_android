// lib/features/warga/screens/laporan_harian_warga_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../supervisor/models/laporan_model.dart';
import '../services/laporan_patroli_service.dart';
import 'detail_patroli_warga_page.dart';

class LaporanHarianWargaPage extends StatefulWidget {
  final String tanggal;
  const LaporanHarianWargaPage({super.key, required this.tanggal});

  @override
  State<LaporanHarianWargaPage> createState() => _LaporanHarianWargaPageState();
}

class _LaporanHarianWargaPageState extends State<LaporanHarianWargaPage> {
  final _service = LaporanPatroliService();

  LaporanHarianDetail? _detail;
  bool _isLoading = true;
  String? _error;
  String _activeShift = '';

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final raw = await _service.getLaporanHarian(
          token: token, tanggal: widget.tanggal);
      _detail = LaporanHarianDetail.fromJson(raw);
      // Set shift aktif ke shift pertama yang ada
      if (_detail!.detailPetugas.isNotEmpty) {
        final shifts = _detail!.detailPetugas.map((e) => e.shift).toSet().toList()..sort();
        _activeShift = shifts.first;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatTanggal(String tanggal) {
    try {
      final d = DateTime.parse(tanggal);
      const hari  = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
      const bulan = ['Januari','Februari','Maret','April','Mei','Juni',
                     'Juli','Agustus','September','Oktober','November','Desember'];
      return '${hari[d.weekday - 1]}, ${d.day} ${bulan[d.month - 1]} ${d.year}';
    } catch (_) { return tanggal; }
  }

  String _formatJam(String jam) {
    try {
      String t = jam.contains('T') ? jam.split('T').last
                 : jam.contains(' ') ? jam.split(' ').last
                 : jam;
      final parts = t.split(':');
      return parts.length >= 2 ? '${parts[0]}.${parts[1]}' : t;
    } catch (_) { return jam; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(),
            _buildTitleBar(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _detail == null
                          ? const Center(child: Text('Data tidak ditemukan'))
                          : _buildContent(_detail!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Image.network(
            'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/new_logo.png',
            height: 24, width: 24, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.pets, color: Colors.lightBlueAccent, size: 24),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ADVANCED EMERGENCY & GUARD INFORMATION SYSTEM',
              style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 16),
          const Text('Laporan Harian',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildContent(LaporanHarianDetail detail) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanggal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              _formatTanggal(widget.tanggal),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          const SizedBox(height: 8),

          // Summary grid
          _buildSummaryGrid(detail.ringkasan),
          const SizedBox(height: 24),

          // Toggle shift
          _buildShiftToggle(detail.detailPetugas),
          const SizedBox(height: 20),

          // List petugas per shift
          _buildPatrolList(detail.detailPetugas),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ─── Summary Grid ─────────────────────────────────────────────────────────

  Widget _buildSummaryGrid(RingkasanStatistik r) {
    final totalIsu = r.totalCheckpoint - r.checkpointAman;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryItem('${r.totalPatroli}', 'Total Patroli',
                  Icons.verified_user_outlined, const Color(0xFFDDF3F5))),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryItem('${r.totalCheckpoint}', 'Total Checkpoint',
                  Icons.location_on_outlined, const Color(0xFFBDE8C0))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('${r.totalPetugas}', 'Petugas',
                  Icons.person, const Color(0xFFBDCBE1))),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryItem('$totalIsu', 'Isu',
                  Icons.error_outline, const Color(0xFFFDE1E1), iconColor: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon, Color bgColor,
      {Color iconColor = Colors.black54}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  // ─── Shift Toggle ─────────────────────────────────────────────────────────

  Widget _buildShiftToggle(List<DetailPetugas> list) {
    final shifts = list.map((e) => e.shift).toSet().toList()..sort();
    if (shifts.isEmpty) return const SizedBox();

    if (!shifts.contains(_activeShift)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeShift = shifts.first);
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2), borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: shifts.map((s) {
          final isActive = _activeShift == s;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeShift = s),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                      : [],
                ),
                child: Center(
                  child: Text(s,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? Colors.black : Colors.grey.shade700,
                      )),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Patrol List ──────────────────────────────────────────────────────────

  Widget _buildPatrolList(List<DetailPetugas> list) {
    final filtered = list.where((p) => p.shift == _activeShift).toList();
    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Tidak ada petugas pada shift ini'),
        ),
      );
    }

    return Column(
      children: filtered.map((petugas) {
        final isu = petugas.checkpoints
            .where((c) => c.kondisi.toLowerCase() != 'aman')
            .length;
        final String statusText;
        final Color statusColor;

        if (isu > 0) {
          statusText  = 'Terdapat $isu Isu';
          statusColor = const Color(0xFFD30000);
        } else if (petugas.checkpoints.isNotEmpty) {
          statusText  = 'Aman';
          statusColor = const Color(0xFF34A853);
        } else {
          statusText  = 'Belum Laporan';
          statusColor = Colors.grey;
        }

        return _buildPatrolCard(petugas: petugas, status: statusText, statusColor: statusColor);
      }).toList(),
    );
  }

  Widget _buildPatrolCard({
    required DetailPetugas petugas,
    required String status,
    required Color statusColor,
  }) {
    final cpDenganWaktu = petugas.checkpoints
        .where((c) => c.waktuLaporan != null && c.waktuLaporan!.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Banner atas
          Container(
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4FB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16), bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(status,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                Expanded(
                  child: Center(
                    child: Text('${petugas.checkpoints.length} checkpoint',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info petugas
                Row(
                  children: [
                    _buildFotoProfil(petugas.petugas.fotoProfil),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Petugas: ${petugas.petugas.nama}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Waktu + tombol detail
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cpDenganWaktu.isEmpty
                          ? 'Waktu: ${_formatJam(petugas.jamMulai)} - ${_formatJam(petugas.jamSelesai)}'
                          : 'Waktu: ${cpDenganWaktu.first.waktuLaporan!} - ${cpDenganWaktu.last.waktuLaporan!}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailPatroliWargaPage(petugasData: petugas),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file_outlined, size: 16, color: Colors.blue.shade300),
                          const SizedBox(width: 4),
                          Text('Detail',
                              style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoProfil(String? foto) {
    if (foto != null && foto.isNotEmpty) {
      final url = '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.supabaseBucket}/$foto';
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
      );
    }
    return const CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFF0D47A1),
      child: Icon(Icons.person, size: 22, color: Colors.white),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}