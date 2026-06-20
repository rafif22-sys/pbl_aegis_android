// lib/features/warga/screens/laporan_patroli_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/laporan_patroli_service.dart';
import '../models/laporan_patroli_model.dart';
import '../widgets/laporan_patroli/patroli_stat_card.dart';
import 'laporan_harian_warga_page.dart';

class LaporanPatroliScreen extends StatefulWidget {
  const LaporanPatroliScreen({super.key});

  @override
  State<LaporanPatroliScreen> createState() => _LaporanPatroliScreenState();
}

class _LaporanPatroliScreenState extends State<LaporanPatroliScreen> {
  final _service = LaporanPatroliService();

  List<LaporanPatroliModel> _mingguIniList = [];
  bool _loadingMingguIni = true;
  String? _errorMingguIni;

  List<LaporanPatroliModel> _riwayatList = [];
  bool _loadingRiwayat = true;
  String? _errorRiwayat;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchMingguIni();
    _fetchRiwayat();
  }

  Future<void> _fetchMingguIni() async {
    setState(() { _loadingMingguIni = true; _errorMingguIni = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      _mingguIniList = await _service.getLaporanMingguIni(token: token);
    } catch (e) {
      _errorMingguIni = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loadingMingguIni = false);
  }

  Future<void> _fetchRiwayat() async {
    setState(() { _loadingRiwayat = true; _errorRiwayat = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final tanggal = _selectedDate != null
          ? '${_selectedDate!.year}-'
            '${_selectedDate!.month.toString().padLeft(2, '0')}-'
            '${_selectedDate!.day.toString().padLeft(2, '0')}'
          : null;
      _riwayatList = await _service.getLaporanPatroli(
          token: token, tanggal: tanggal);
    } catch (e) {
      _errorRiwayat = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loadingRiwayat = false);
  }

  String _getMonthName(int month) {
    const months = [
      'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember',
    ];
    return months[month - 1];
  }

  String _formatTanggalCard(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day} ${_getMonthName(d.month)}\n${d.year}';
    } catch (_) { return iso; }
  }

  void _goToHarian(String tanggal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LaporanHarianWargaPage(tanggal: tanggal),
      ),
    );
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
            _buildSectionTitle('Minggu Ini'),
            Expanded(child: _buildMingguIniList()),
            _buildSectionTitle('Riwayat Laporan'),
            _buildSearchBar(),
            Expanded(child: _buildRiwayatList()),
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
          const Text('Laporan Patroli',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMingguIniList() {
    if (_loadingMingguIni) return const Center(child: CircularProgressIndicator());
    if (_errorMingguIni != null) return _buildError(_errorMingguIni!, _fetchMingguIni);
    if (_mingguIniList.isEmpty) return _buildEmpty('Tidak ada laporan minggu ini');
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _mingguIniList.length,
      itemBuilder: (_, i) => _buildReportCard(_mingguIniList[i]),
    );
  }

  Widget _buildRiwayatList() {
    if (_loadingRiwayat) return const Center(child: CircularProgressIndicator());
    if (_errorRiwayat != null) return _buildError(_errorRiwayat!, _fetchRiwayat);
    if (_riwayatList.isEmpty) return _buildEmpty('Tidak ada riwayat laporan');
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _riwayatList.length,
      itemBuilder: (_, i) => _buildReportCard(_riwayatList[i]),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => _showDatePickerBottomSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Cari Tanggal'
                    : '${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}',
                style: TextStyle(
                  color: _selectedDate == null ? Colors.grey.shade500 : Colors.black87,
                  fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (_selectedDate != null)
              GestureDetector(
                onTap: () { setState(() => _selectedDate = null); _fetchRiwayat(); },
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(LaporanPatroliModel data) {
    return GestureDetector(
      onTap: () => _goToHarian(data.tanggal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 85,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.hari.isNotEmpty ? data.hari : '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTanggalCard(data.tanggal),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  children: [
                    _buildStatRow(Icons.check_circle_outline, 'Total Patroli', data.totalPatroli),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.person_outline, 'Petugas', data.totalPetugas),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.location_on_outlined, 'Total Checkpoint', data.totalCheckpoint),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Text(value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(width: 16),
      ],
    );
  }

  void _showDatePickerBottomSheet(BuildContext context) {
    DateTime tempDate = _selectedDate ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, size: 24)),
                    const SizedBox(width: 16),
                    const Text('Pilih Tanggal',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              CalendarDatePicker(
                initialDate: tempDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onDateChanged: (d) => setModalState(() => tempDate = d),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
                      child: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TERPILIH',
                            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(
                          '${tempDate.day} ${_getMonthName(tempDate.month)} ${tempDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() => _selectedDate = tempDate);
                      Navigator.pop(ctx);
                      _fetchRiwayat();
                    },
                    child: const Text('Tampilkan Laporan',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(msg, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
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

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}