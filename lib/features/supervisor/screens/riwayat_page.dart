import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/aegis_top_header.dart';

// Import Auth, Provider SOS, dan Model asli Supabase
import '../../auth/providers/auth_provider.dart';
import '../../sos/models/sos_model.dart';
import '../../sos/providers/sos_provider.dart';

// Import halaman Detail SOS khusus Supervisor
import 'supervisor_detail_sos_screen.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRiwayatSos();
    });
  }

  // Menembak API Supabase menggunakan fungsi resmi
  Future<void> _fetchRiwayatSos() async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isNotEmpty) {
      await context.read<SosProvider>().fetchListSOS(token: token);
    }
  }

  // Pemformatan waktu ke standar string (HH:mm)
  String _formatWaktu(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  // Pemformatan tanggal visual
  String _formatTanggal(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const bulan = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei',
        'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${bulan[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return 'Tanggal Tidak Diketahui';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchRiwayatSos,
          color: const Color(0xFF0D47A1),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AegisTopHeader(),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'SINYAL SOS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // MENGGUNAKAN CONSUMER AGAR SUMMARY CARDS DAN LIST RENDER REAL-TIME
                Consumer<SosProvider>(
                  builder: (context, provider, _) {
                    // Menggunakan getter resmi buatan Rafif
                    final totalSos = provider.totalSos;
                    final totalSelesai = provider.totalSelesai;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cetak kartu ringkasan dinamis
                        _buildSummaryCards(totalSos, totalSelesai),
                        const SizedBox(height: 32),

                        // Bagian Header Daftar SOS & Indikator Filter
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daftar SOS',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      provider.activeFilter ?? 'Semua',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.filter_list, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Menentukan render list berdasarkan SosListState
                        _buildDynamicListContent(provider),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIKA RENDER STATE (LOADING, ERROR, KOSONG, DATA) ---
  Widget _buildDynamicListContent(SosProvider provider) {
    // 1. Jika state sedang loading
    if (provider.state == SosListState.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1))),
      );
    }

    // 2. Jika terjadi error dari server
    if (provider.state == SosListState.error) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _fetchRiwayatSos,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Mengambil data menggunakan getter resmi sosList
    final listSos = provider.sosList;

    // 4. Jika datanya kosong
    if (listSos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: Text(
            'Belum ada riwayat sinyal darurat.',
            style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // 5. Cetak daftar kartu SOS
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listSos.length,
      itemBuilder: (context, index) {
        return _buildSosCard(listSos[index]);
      },
    );
  }
  
  // --- WIDGET SUMMARY CARDS DINAMIS ---
  Widget _buildSummaryCards(int total, int selesai) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: Color(0xFF0D47A1), width: 4)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Pesan SOS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        total.toString(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Icon(Icons.bar_chart, color: Colors.blue.shade300),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: Colors.green, width: 4)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SOS Dikonfirmasi',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selesai.toString(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const Icon(Icons.check_circle_outline, color: Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET KARTU SOS DINAMIS ---
  // --- WIDGET KARTU SOS DINAMIS ---
  Widget _buildSosCard(SosModel sos) {
    // Validasi status menggunakan enum resmi buatan Rafif
    bool isMenunggu = sos.status == StatusSOS.menungguBantuan;
    String statusText = isMenunggu ? 'MENUNGGU BANTUAN' : 'SELESAI';
    
    // Membaca data relasi Supabase
    String senderName = sos.user?.nama ?? 'Petugas Lapangan';
    String imgUrl = sos.user?.fotoProfil ?? 'https://randomuser.me/api/portraits/men/${sos.id % 90}.jpg';

    // 1. Tentukan Ikon berdasarkan Jenis Keadaan
    IconData jenisIcon;
    switch (sos.jenisKeadaan) {
      case JenisKeadaan.kebakaran:   jenisIcon = Icons.local_fire_department; break;
      case JenisKeadaan.pencurian:   jenisIcon = Icons.person_off; break;
      case JenisKeadaan.hewanLiar:   jenisIcon = Icons.pets; break;
      case JenisKeadaan.bencanaAlam: jenisIcon = Icons.thunderstorm; break;
      case JenisKeadaan.lainnya:     jenisIcon = Icons.warning_amber_rounded; break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SupervisorDetailSosScreen(sos: sos),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BARIS 1: TANGGAL & STATUS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTanggal(sos.waktuKirim),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMenunggu ? const Color(0xFFFFE5E5) : const Color(0xFFE4F1FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isMenunggu ? Colors.red.shade200 : Colors.blue.shade200),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isMenunggu ? const Color(0xFFD30000) : const Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // --- BARIS 2: JAM ---
            Text(
              _formatWaktu(sos.waktuKirim),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            // --- BARIS 3: BADGE JENIS KEADAAN & BANTUAN WARGA (TAMBAHAN BARU) ---
            Row(
              children: [
                // Badge Jenis Keadaan
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(jenisIcon, size: 14, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text(
                        sos.jenisKeadaan.name.toUpperCase(), 
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge Bantuan Warga (Hanya muncul jika isBantuanWarga bernilai true di database)
                if (sos.bantuanWarga) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'Butuh Warga',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            
            // --- BARIS 4: FOTO & NAMA PENGIRIM ---
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(imgUrl),
                  onBackgroundImageError: (_, _) {},
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    senderName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMenunggu ? const Color(0xFF0D47A1) : Colors.grey.shade200,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isMenunggu ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}