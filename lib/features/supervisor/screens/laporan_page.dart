import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Wajib import Supabase
import 'laporan_harian_page.dart'; 
import 'widgets/aegis_top_header.dart';

// --- KELAS UNTUK DATA LAPORAN ---
class ReportData {
  final String day;
  final String date;
  final int totalPatroli;
  final int petugas;
  final int checkpoint;

  ReportData({
    required this.day,
    required this.date,
    this.totalPatroli = 0,
    this.petugas = 0,
    this.checkpoint = 0,
  });
}

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  DateTime? _selectedDate; 
  bool _isLoading = true; // Indikator loading saat narik data
  
  // List yang tadinya dummy, sekarang dikosongkan untuk diisi dari database
  List<ReportData> mingguIniData = [];
  List<ReportData> riwayatData = [];

  // Inisialisasi koneksi Supabase
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Jalankan fungsi penarikan data saat halaman pertama kali dibuka
    _fetchLaporanDariSupabase();
  }

  // --- FUNGSI UTAMA PENARIKAN DATA SUPABASE ---
  // --- FUNGSI UTAMA PENARIKAN DATA SUPABASE (MURNI DATABASE) ---
  Future<void> _fetchLaporanDariSupabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. TARIK DATA ASLI DARI TABEL 'laporan_checkpoint'
      final List<dynamic> rawData = await supabase
          .from('laporan_checkpoint')
          .select('id, id_jadwal_absensi, status, waktu_laporan, point')
          .order('waktu_laporan', ascending: false);

      // Kosongkan list setiap kali fetch ulang agar tidak ada data nyangkut
      mingguIniData = [];
      riwayatData = [];

      // 2. JIKA ADA DATA (Setelah kamu tes absen/patroli)
      if (rawData.isNotEmpty) {
        // Logika untuk mengelompokkan data berdasarkan Tanggal
        Map<String, List<dynamic>> groupedByDate = {};
        
        for (var row in rawData) {
          // Ambil tanggal (YYYY-MM-DD) dari waktu_laporan atau created_at
          String rawDate = row['waktu_laporan'] ?? row['created_at'];
          DateTime parsedDate = DateTime.parse(rawDate);
          String dateKey = '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
          
          if (!groupedByDate.containsKey(dateKey)) {
            groupedByDate[dateKey] = [];
          }
          groupedByDate[dateKey]!.add(row);
        }

        // 3. MAPPING DATA ASLI KE UI
        List<ReportData> realReports = [];
        groupedByDate.forEach((dateKey, rows) {
          DateTime dateObj = DateTime.parse(dateKey);
          
          // Hitung unik sesi patroli berdasarkan id_jadwal_absensi
          Set<String> uniquePatrols = {};
          for (var r in rows) {
            if (r['id_jadwal_absensi'] != null) {
              uniquePatrols.add(r['id_jadwal_absensi'].toString());
            }
          }

          realReports.add(ReportData(
            day: _getDayName(dateObj.weekday), 
            date: '${dateObj.day} ${_getMonthName(dateObj.month)}\n${dateObj.year}',
            totalPatroli: uniquePatrols.length, // Total sesi patroli aktif hari itu
            petugas: uniquePatrols.length, // Asumsi 1 sesi = 1 petugas
            checkpoint: rows.length, // Total semua checkpoint yang di-scan hari itu
          ));
        });

        // Pisahkan 3 teratas ke "Minggu Ini", sisanya ke "Riwayat"
        mingguIniData = realReports.take(3).toList();
        riwayatData = realReports.skip(3).toList();
      }

    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data dari Supabase: $error')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  // Fungsi tambahan untuk menerjemahkan angka hari menjadi nama hari
  String _getDayName(int weekday) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[weekday - 1];
  }

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
            
            // Tampilkan animasi loading berputar jika data masih ditarik
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
                ),
              )
            else ...[
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