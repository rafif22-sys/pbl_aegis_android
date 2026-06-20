import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_patroli_page.dart';
import 'widgets/aegis_top_header.dart';

class LaporanHarianPage extends StatefulWidget {
  final String tanggal;

  const LaporanHarianPage({super.key, required this.tanggal});

  @override
  State<LaporanHarianPage> createState() => _LaporanHarianPageState();
}

class _LaporanHarianPageState extends State<LaporanHarianPage> {
  int _activeShift = 1; 
  bool _isLoading = true;
  final supabase = Supabase.instance.client;

  // Variabel untuk nyimpan data
  int totalPatroli = 0;
  int totalCheckpoint = 0;
  int totalPetugas = 0;
  int totalIsu = 0;

  List<dynamic> shift1Data = [];
  List<dynamic> shift2Data = [];
  List<dynamic> shift3Data = [];

  @override
  void initState() {
    super.initState();
    _fetchLaporanHarian();
  }

  Future<void> _fetchLaporanHarian() async {
    setState(() => _isLoading = true);

    try {
      final List<dynamic> rawData = await supabase
          .from('laporan_checkpoint')
          .select('id, id_jadwal_absensi, status, kondisi, waktu_laporan, point')
          .order('waktu_laporan', ascending: false);

      List<dynamic> dataHariIni = rawData.where((row) {
        String rawDate = row['waktu_laporan'] ?? row['created_at'] ?? '';
        if (rawDate.isEmpty) return false;
        
        DateTime d = DateTime.parse(rawDate);
        String formattedDate = '${_getDayName(d.weekday)}, ${d.day} ${_getMonthName(d.month)} ${d.year}';
        return formattedDate == widget.tanggal; // Cocokkan dengan tanggal yang di-klik
      }).toList();

      // Hitung Summary
      Set<String> uniqueJadwal = {};
      int isuCount = 0;

      for (var row in dataHariIni) {
        if (row['id_jadwal_absensi'] != null) {
          uniqueJadwal.add(row['id_jadwal_absensi'].toString());
        }
        if (row['kondisi'] != null && row['kondisi'].toString().toLowerCase() != 'aman') {
          isuCount++;
        }
      }

      totalCheckpoint = dataHariIni.length;
      totalPatroli = uniqueJadwal.length;
      totalPetugas = uniqueJadwal.length; 
      totalIsu = isuCount;

      // Kelompokkan data per jadwal (1 jadwal = 1 kartu patroli)
      Map<String, List<dynamic>> groupedByJadwal = {};
      for (var row in dataHariIni) {
        String jadwalId = row['id_jadwal_absensi'].toString();
        if (!groupedByJadwal.containsKey(jadwalId)) {
          groupedByJadwal[jadwalId] = [];
        }
        groupedByJadwal[jadwalId]!.add(row);
      }

      // Masukkan ke Shift berdasarkan jam patroli pertama
      shift1Data.clear();
      shift2Data.clear();
      shift3Data.clear();

      groupedByJadwal.forEach((jadwalId, rows) {
        DateTime waktu = DateTime.parse(rows.last['waktu_laporan'] ?? rows.last['created_at']);
        int jam = waktu.hour;

        bool adaIsu = rows.any((r) => r['kondisi'].toString().toLowerCase() != 'aman');
        
        Map<String, dynamic> patrolCard = {
          'id_jadwal_absensi': jadwalId,
          'status': adaIsu ? 'Terdapat isu' : 'Aman',
          'statusColor': adaIsu ? const Color(0xFFD30000) : const Color(0xFF34A853),
          'waktu': '${jam.toString().padLeft(2, '0')}.00 - ${(jam + 2).toString().padLeft(2, '0')}.00', // Estimasi
          'checkpoint': '${rows.length} checkpoint',
        };

        if (jam >= 6 && jam < 14) {
          shift1Data.add(patrolCard);
        } else if (jam >= 14 && jam < 22) {
          shift2Data.add(patrolCard);
        } else {
          shift3Data.add(patrolCard);
        }
      });

    } catch (e) {
      debugPrint("Error fetching harian: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getDayName(int weekday) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
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
            const AegisTopHeader(),
            _buildTitleBar(context),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1))))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text(widget.tanggal, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryGrid(),
                      const SizedBox(height: 24),
                      _buildShiftToggle(),
                      const SizedBox(height: 20),
                      _buildPatrolList(),
                      const SizedBox(height: 30),
                    ],
                  ),
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
          InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, size: 28, color: Colors.black)),
          const SizedBox(width: 16),
          const Text('Laporan Harian', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryItem(totalPatroli.toString(), 'Total Patroli', Icons.verified_user_outlined, const Color(0xFFDDF3F5))),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryItem(totalCheckpoint.toString(), 'Total Checkpoint', Icons.location_on_outlined, const Color(0xFFBDE8C0))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryItem(totalPetugas.toString(), 'Petugas', Icons.person, const Color(0xFFBDCBE1))),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryItem(totalIsu.toString(), 'Isu', Icons.error_outline, const Color(0xFFFDE1E1), iconColor: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon, Color bgColor, {Color iconColor = Colors.black54}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildShiftToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFE2E2E2), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildShiftTab(1, 'Shift 1'),
          _buildShiftTab(2, 'Shift 2'),
          _buildShiftTab(3, 'Shift 3'),
        ],
      ),
    );
  }

  Widget _buildShiftTab(int shiftNumber, String label) {
    bool isActive = _activeShift == shiftNumber;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeShift = shiftNumber),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.black : Colors.grey.shade700)),
          ),
        ),
      ),
    );
  }

  Widget _buildPatrolList() {
    List<dynamic> activeData = _activeShift == 1 ? shift1Data : (_activeShift == 2 ? shift2Data : shift3Data);

    if (activeData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("Tidak ada patroli di shift ini.", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: activeData.map((data) {
        return _buildPatrolCard(
          data['status'],
          'Sesi Patroli ${data['id_jadwal_absensi']}', 
          data['waktu'],
          data['checkpoint'],
          data['statusColor'],
          data['id_jadwal_absensi'],
        );
      }).toList(),
    );
  }

  Widget _buildPatrolCard(String status, String nama, String waktu, String checkpoint, Color statusColor, String idJadwal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4FB),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                    ),
                    child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                Expanded(child: Center(child: Text(checkpoint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundColor: Colors.grey.shade300),
                    const SizedBox(width: 12),
                    Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.insert_drive_file_outlined, size: 14, color: Colors.blue.shade300),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // PASSING ID JADWAL KE HALAMAN DETAIL
                            builder: (context) => DetailPatroliPage(idJadwalAbsensi: idJadwal, namaPetugas: nama), 
                          ),
                        );
                      },
                      child: Text('Detail', style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.bold, fontSize: 13)),
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
}