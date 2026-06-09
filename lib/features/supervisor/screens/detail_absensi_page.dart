import 'package:flutter/material.dart';
import 'widgets/aegis_top_header.dart';

class DetailAbsensiPage extends StatelessWidget {
  final String nama;
  final String tanggal;
  final String shift;
  final String waktu;
  final String pos;
  final String status;

  const DetailAbsensiPage({
    super.key,
    required this.nama,
    required this.tanggal,
    required this.shift,
    required this.waktu,
    required this.pos,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA DINAMIS BERDASARKAN STATUS ---
    String masukWaktu = '--:--';
    String masukDesc = 'Belum absen';
    Color masukBgColor = Colors.grey.shade400;
    
    String pulangWaktu = '--:--';
    String pulangDesc = 'Belum absen';
    Color pulangBgColor = Colors.grey.shade400;

    String? fotoMasukUrl;
    String? fotoPulangUrl;

    bool isRadiusAman = false;

    if (status == 'HADIR') {
      masukWaktu = '07:55';
      masukDesc = '5 menit awal';
      masukBgColor = const Color(0xFF6FCF73); // Hijau
      
      pulangWaktu = '16:05';
      pulangDesc = 'Tepat waktu';
      pulangBgColor = const Color(0xFFFF6B6B); // Merah
      
      fotoMasukUrl = 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80';
      fotoPulangUrl = 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80';
      isRadiusAman = true;
    } else if (status == 'TERLAMBAT') {
      masukWaktu = '08:20';
      masukDesc = '20 menit telat';
      masukBgColor = const Color(0xFFFFA726); // Oranye
      
      pulangWaktu = '--:--';
      pulangDesc = 'Shift belum selesai';
      pulangBgColor = Colors.grey.shade400; // Abu-abu
      
      fotoMasukUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80';
      fotoPulangUrl = null; // Belum ada foto pulang
      isRadiusAman = true;
    } else {
      // Status MENUNGGU
      isRadiusAman = false;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB),
      body: SafeArea(
        child: Column(
          children: [
            const AegisTopHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleBar(context),
                    
                    // NAMA PETUGAS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoCard(isRadiusAman),
                    const SizedBox(height: 20),
                    
                    // KARTU JAM MASUK & PULANG
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildTimeCard('MASUK', masukWaktu, masukDesc, Icons.login, masukBgColor)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTimeCard('PULANG', pulangWaktu, pulangDesc, Icons.logout, pulangBgColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // FOTO ABSENSI
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 24),
                          SizedBox(width: 8),
                          Text('Foto Absensi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildPhotoCard('FOTO MASUK', fotoMasukUrl)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPhotoCard('FOTO PULANG', fotoPulangUrl)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
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
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 16),
          const Text(
            'Absensi Petugas',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isRadiusAman) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Baris 1: Hari & Tanggal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFE4F0FB), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_today, color: Color(0xFF0D47A1), size: 20),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HARI & TANGGAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(tanggal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          
          // Baris 2: Shift & Lokasi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFE4F0FB), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.access_time, color: Color(0xFF0D47A1), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('JAM SHIFT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(waktu, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFEEEEEE)), // Garis pemisah tengah
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFE4F0FB), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.location_on_outlined, color: Color(0xFF0D47A1), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LOKASI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(pos, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Baris 3: Status Radius Lokasi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  isRadiusAman ? Icons.check_circle_outline : Icons.info_outline, 
                  color: isRadiusAman ? Colors.green : Colors.grey, 
                  size: 16
                ),
                const SizedBox(width: 8),
                Text(
                  isRadiusAman ? 'Radius lokasi sesuai titik penugasan' : 'Data radius belum tersedia',
                  style: TextStyle(fontSize: 12, color: isRadiusAman ? Colors.black87 : Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String title, String time, String desc, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(String label, String? imageUrl) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
            image: imageUrl != null
                ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                : null,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: imageUrl != null
              ? const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ),
                )
              : const Center(
                  child: Icon(Icons.person_off_outlined, size: 40, color: Colors.grey),
                ), // Tampilan kalau foto belum ada
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12)),
      ],
    );
  }
}