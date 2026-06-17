import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/laporan_provider.dart';
import '../models/laporan_model.dart';
import 'detail_patroli_page.dart';
import 'widgets/aegis_top_header.dart';

class LaporanHarianPage extends StatefulWidget {
  final String tanggal;

  const LaporanHarianPage({super.key, required this.tanggal});

  @override
  State<LaporanHarianPage> createState() => _LaporanHarianPageState();
}

class _LaporanHarianPageState extends State<LaporanHarianPage> {
  late LaporanProvider _provider;
  bool _isInit = false;
  String _activeShift = 'Shift 1'; // Default Shift 1

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = LaporanProvider(
        token: context.read<AuthProvider>().token ?? '',
      );
      _provider.fetchDetailHarian(widget.tanggal);
      setState(() {
        _isInit = true;
      });
    });
  }

  // --- HELPER UNTUK FORMAT TANGGAL ---
  String _formatTanggal(String tanggal) {
    try {
      DateTime parsedDate = DateTime.parse(tanggal);
      
      List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      List<String> bulan = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];

      String namaHari = hari[parsedDate.weekday - 1];
      String namaBulan = bulan[parsedDate.month - 1];

      return '$namaHari, ${parsedDate.day} $namaBulan ${parsedDate.year}';
    } catch (e) {
      // Jika parsing gagal (misal format dari API bukan standar DateTime), 
      // kembalikan string aslinya sebagai fallback
      return tanggal; 
    }
  }

  // --- HELPER UNTUK FORMAT JAM ---
  String _formatJam(String jam) {
    try {
      // 1. Ekstrak bagian waktunya saja jika ada tanggal 
      // (misal: "2026-06-17T07:00:00" diubah menjadi "07:00:00")
      String timeString = jam;
      if (jam.contains('T')) {
        timeString = jam.split('T').last;
      } else if (jam.contains(' ')) {
        timeString = jam.split(' ').last;
      }

      // 2. Memecah "07:00:00" menjadi ["07", "00", "00"]
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}.${parts[1]}'; // Menggunakan titik (.) sesuai desain
      }
      
      // Jika formatnya bukan titik dua, kembalikan string waktunya langsung
      return timeString;
    } catch (e) {
      // Jika terjadi error, kembalikan data asli sebagai fallback
      return jam;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        backgroundColor: Color(0xFFE4F0FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4F0FB), // Background biru muda
        body: SafeArea(
          child: Consumer<LaporanProvider>(
            builder: (context, prov, child) {
              final loading = prov.loadingDetail;
              final error = prov.errorDetail;
              final detail = prov.detailHarian;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AegisTopHeader(),
                  _buildTitleBar(context),

                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : error != null
                            ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
                            : detail == null
                                ? const Center(child: Text('Data tidak ditemukan'))
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Tanggal Laporan (Sudah Diformat)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            _formatTanggal(widget.tanggal), // Menggunakan helper format
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Kotak Summary 2x2
                                        _buildSummaryGrid(detail.ringkasan),
                                        const SizedBox(height: 24),

                                        // Toggle Shift (Dinamis dari data)
                                        _buildShiftToggle(detail.detailPetugas),
                                        const SizedBox(height: 20),

                                        // List Laporan per Shift
                                        _buildPatrolList(detail.detailPetugas),
                                        const SizedBox(height: 30),
                                      ],
                                    ),
                                  ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- WIDGET JUDUL HALAMAN ---
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
            'Laporan Harian',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET KOTAK SUMMARY (2x2) ---
  Widget _buildSummaryGrid(RingkasanStatistik ringkasan) {
    int totalIsu = ringkasan.totalCheckpoint - ringkasan.checkpointAman;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '${ringkasan.totalPatroli}',
                  'Total Patroli',
                  Icons.verified_user_outlined,
                  const Color(0xFFDDF3F5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  '${ringkasan.totalCheckpoint}',
                  'Total Checkpoint',
                  Icons.location_on_outlined,
                  const Color(0xFFBDE8C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '${ringkasan.totalPetugas}',
                  'Petugas',
                  Icons.person,
                  const Color(0xFFBDCBE1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  '$totalIsu',
                  'Isu',
                  Icons.error_outline,
                  const Color(0xFFFDE1E1),
                  iconColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String value,
    String label,
    IconData icon,
    Color bgColor, {
    Color iconColor = Colors.black54,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // --- WIDGET TOGGLE SHIFT ---
  Widget _buildShiftToggle(List<DetailPetugas> petugasList) {
    final shifts = petugasList.map((e) => e.shift).toSet().toList();
    if (shifts.isEmpty) return const SizedBox();

    shifts.sort();
    
    if (!shifts.contains(_activeShift) && shifts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _activeShift = shifts.first;
        });
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: shifts.map((shiftName) {
          return _buildShiftTab(shiftName, shiftName);
        }).toList(),
      ),
    );
  }

  Widget _buildShiftTab(String shiftName, String label) {
    bool isActive = _activeShift == shiftName;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeShift = shiftName;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.black : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET LIST LAPORAN BERDASARKAN SHIFT ---
  Widget _buildPatrolList(List<DetailPetugas> petugasList) {
    final filteredList = petugasList.where((p) => p.shift == _activeShift).toList();

    if (filteredList.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Tidak ada petugas pada shift ini'),
      ));
    }

    return Column(
      children: filteredList.map((petugas) {
        int isu = petugas.checkpoints.where((c) => c.kondisi.toLowerCase() != 'aman').length;
        String statusText;
        Color statusColor;
        
        if (isu > 0) {
          statusText = 'Terdapat $isu Isu';
          statusColor = const Color(0xFFD30000);
        } else if (petugas.checkpoints.isNotEmpty) {
          statusText = 'Aman';
          statusColor = const Color(0xFF34A853);
        } else {
          statusText = 'Belum Laporan';
          statusColor = Colors.grey;
        }

        return _buildPatrolCard(
          petugas: petugas,
          status: statusText,
          statusColor: statusColor,
        );
      }).toList(),
    );
  }

  Widget _buildPatrolCard({
    required DetailPetugas petugas,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
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
      child: Column(
        children: [
          // Banner Atas (Status & Checkpoint)
          Container(
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4FB), 
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (status.isNotEmpty) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${petugas.checkpoints.length} checkpoint',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail Petugas dan Jadwal
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Petugas
                Row(
                  children: [
                    _buildFotoProfil(petugas.petugas.fotoProfil),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Petugas: ${petugas.petugas.nama}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Info Waktu & Tombol Detail sejajar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(builder: (_) {
                      // Ambil semua checkpoint yang punya waktu_laporan
                      final cpDenganWaktu = petugas.checkpoints
                          .where((c) => c.waktuLaporan != null &&
                              c.waktuLaporan!.isNotEmpty)
                          .toList();

                      if (cpDenganWaktu.isEmpty) {
                        // Fallback ke jam shift jika belum ada laporan
                        return Text(
                          'Waktu: ${_formatJam(petugas.jamMulai)} - ${_formatJam(petugas.jamSelesai)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        );
                      }

                      final waktuMulai  = cpDenganWaktu.first.waktuLaporan!;
                      final waktuSelesai = cpDenganWaktu.last.waktuLaporan!;

                      return Text(
                        'Waktu: $waktuMulai - $waktuSelesai',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPatroliPage(
                              petugasData: petugas, 
                            ), 
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            size: 16,
                            color: Colors.blue.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Detail',
                            style: TextStyle(
                              color: Colors.blue.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
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
  // --- HELPER: Foto Profil ---
  Widget _buildFotoProfil(String? fotoProfil) {
    if (fotoProfil != null && fotoProfil.isNotEmpty) {
      final url =
          '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.supabaseBucket}/$fotoProfil';
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFF0D47A1),
      child: const Icon(Icons.person, size: 22, color: Colors.white),
    );
  }
}