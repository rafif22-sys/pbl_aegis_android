import 'package:flutter/material.dart';
import 'laporan_harian_page.dart'; 
import 'widgets/aegis_top_header.dart';

// --- KELAS UNTUK DATA DUMMY LAPORAN ---
class ReportData {
  final String day;
  final String date;
  final int totalPatroli;
  final int petugas;
  final int checkpoint;

  ReportData({
    required this.day,
    required this.date,
    this.totalPatroli = 10,
    this.petugas = 24,
    this.checkpoint = 24,
  });
}

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  DateTime? _selectedDate; 

  // Data Dummy untuk "Minggu Ini"
  final List<ReportData> mingguIniData = [
    ReportData(day: 'Jumat', date: '14 April\n2026'),
    ReportData(day: 'Kamis', date: '13 April\n2026'),
    ReportData(day: 'Rabu', date: '12 April\n2026'), 
  ];

  // Data Dummy untuk "Riwayat Laporan"
  List<ReportData> riwayatData = [
    ReportData(day: 'Minggu', date: '12 April\n2026'),
    ReportData(day: 'Sabtu', date: '11 April\n2026'),
    ReportData(day: 'Jumat', date: '10 April\n2026'),
    ReportData(day: 'Kamis', date: '09 April\n2026'), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB), 
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AegisTopHeader(),
            _buildTitleBar(context),
            
            _buildSectionTitle('Minggu Ini'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: mingguIniData.length,
                itemBuilder: (context, index) {
                  return _buildReportCard(mingguIniData[index]);
                },
              ),
            ),

            _buildSectionTitle('Riwayat Laporan'),
            _buildSearchBar(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: riwayatData.length,
                itemBuilder: (context, index) {
                  return _buildReportCard(riwayatData[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 16),
          const Text(
            'Laporan Patroli',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
            Text(
              _selectedDate == null 
                  ? 'Cari Tanggal' 
                  : '${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}',
              style: TextStyle(
                color: _selectedDate == null ? Colors.grey.shade500 : Colors.black87,
                fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET KARTU LAPORAN YANG SUDAH DIPERBAIKI ---
  Widget _buildReportCard(ReportData data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaporanHarianPage(
              tanggal: '${data.day}, ${data.date.replaceAll('\n', ' ')}',
            ),
          ),
        );
      },
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
                    data.day,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.date,
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
                    _buildStatRow(Icons.person_outline, 'Petugas', data.petugas),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.location_on_outlined, 'Total Checkpoint', data.checkpoint),
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
          child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(width: 16), 
      ],
    );
  }

  void _showDatePickerBottomSheet(BuildContext context) {
    DateTime tempSelectedDate = _selectedDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builderContext) {
        return StatefulBuilder( 
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text('Pilih Tanggal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                  CalendarDatePicker(
                    initialDate: tempSelectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    onDateChanged: (DateTime newDate) {
                      setModalState(() {
                        tempSelectedDate = newDate;
                      });
                    },
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
                              decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
                              child: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TERPILIH', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                Text(
                                  '${tempSelectedDate.day} ${_getMonthName(tempSelectedDate.month)} ${tempSelectedDate.year}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('TOTAL LAPORAN', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text('14 Ditemukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
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
                          setState(() {
                            _selectedDate = tempSelectedDate;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Tampilkan Laporan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return months[month - 1];
  }
}