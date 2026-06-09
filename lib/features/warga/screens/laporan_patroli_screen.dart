import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/laporan_patroli_service.dart';
import '../models/laporan_patroli_model.dart';

import '../widgets/laporan_patroli/patroli_stat_card.dart';

class LaporanPatroliScreen extends StatefulWidget {
  const LaporanPatroliScreen({super.key});

  @override
  State<LaporanPatroliScreen> createState() => _LaporanPatroliScreenState();
}

class _LaporanPatroliScreenState extends State<LaporanPatroliScreen> {
  final _service = LaporanPatroliService();
  List<LaporanPatroliModel> _data = [];
  bool _isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final tanggal = _selectedDate != null
          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
          : null;
      _data = await _service.getLaporanPatroli(token: token, tanggal: tanggal);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat laporan patroli')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showDatePickerBottomSheet() {
    DateTime tempDate = _selectedDate ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, size: 24),
                        ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_today,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TERPILIH',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  '${tempDate.day} ${_getMonthName(tempDate.month)} ${tempDate.year}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() => _selectedDate = tempDate);
                          Navigator.pop(context);
                          _fetchData();
                        },
                        child: const Text('Tampilkan Laporan',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
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
            _buildSectionTitle('Riwayat Laporan'),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _data.isEmpty
                      ? const Center(
                          child: Text('Belum ada laporan patroli',
                              style: TextStyle(color: Colors.black45)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: _data.length,
                          itemBuilder: (context, index) =>
                              _buildReportCard(_data[index]),
                        ),
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
            bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Image.network(
            'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/new_logo.png',
            height: 24,
            width: 24,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.pets, color: Colors.lightBlueAccent, size: 24),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ADVANCED EMERGENCY & GUARD INFORMATION SYSTEM',
              style: TextStyle(
                  color: Colors.white70, fontSize: 10, letterSpacing: 0.5),
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
          const Text(
            'Laporan Patroli',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
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
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _showDatePickerBottomSheet,
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
            Icon(Icons.calendar_month_outlined,
                color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null
                  ? 'Cari Tanggal'
                  : '${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}',
              style: TextStyle(
                color: _selectedDate == null
                    ? Colors.grey.shade500
                    : Colors.black87,
                fontWeight: _selectedDate == null
                    ? FontWeight.normal
                    : FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(LaporanPatroliModel data) {
    return GestureDetector(
      onTap: () => _showDetail(data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 85,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Shift ${data.shift}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.tanggal,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, height: 1.2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  children: [
                    _buildStatRow(Icons.check_circle_outline,
                        'Total Patroli', data.totalPetugas),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.person_outline,
                        'Petugas', data.totalPetugas),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.location_on_outlined,
                        'Total Checkpoint', data.totalCheckpoint),
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
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Text(value.toString(),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87)),
        const SizedBox(width: 16),
      ],
    );
  }

  void _showDetail(LaporanPatroliModel laporan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Detail Patroli — Shift ${laporan.shift}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              laporan.tanggal,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PatroliStatCard(
                  value: '${laporan.totalPetugas}',
                  label: 'Petugas',
                  bgColor: const Color(0xFFe0e0f8),
                  icon: Icons.person_outline,
                ),
                PatroliStatCard(
                  value: '${laporan.totalCheckpoint}',
                  label: 'Checkpoint',
                  bgColor: const Color(0xFFd1e7dd),
                  icon: Icons.location_on,
                ),
              ],
            ),
            if (laporan.petugasList.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Petugas Bertugas:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...laporan.petugasList.map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        p.aman ? Icons.check_circle : Icons.warning,
                        color: p.aman ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(p.nama,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(p.waktu,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
