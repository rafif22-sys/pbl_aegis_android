import 'package:flutter/material.dart';
import 'widgets/aegis_top_header.dart';

class DetailAbsensiPage extends StatelessWidget {
  final String nama;
  final String tanggal;
  final String shift;
  final String waktu;
  final String pos;
  final String status;
  final String? jamMasuk;
  final String? jamPulang;
  final String? fotoAbsensiMasuk;
  final String? fotoAbsensiPulang;

  const DetailAbsensiPage({
    super.key,
    required this.nama,
    required this.tanggal,
    required this.shift,
    required this.waktu,
    required this.pos,
    required this.status,
    this.jamMasuk,
    this.jamPulang,
    this.fotoAbsensiMasuk,
    this.fotoAbsensiPulang,
  });

  @override
  Widget build(BuildContext context) {
    String masukWaktu = '--:--';
    String masukDesc  = 'Belum absen';
    Color  masukBgColor = Colors.grey.shade400;

    String pulangWaktu = '--:--';
    String pulangDesc  = 'Belum absen';
    Color  pulangBgColor = Colors.grey.shade400;

    final normalizedStatus = status.toUpperCase().trim();

    final bool hasMasuk = jamMasuk != null && jamMasuk != '--:--';
    final bool hasPulang = jamPulang != null && jamPulang != '--:--';

    if (normalizedStatus == 'HADIR') {
      masukWaktu   = hasMasuk ? jamMasuk! : '--:--';
      masukDesc    = hasMasuk ? 'Tepat waktu' : 'Belum absen';
      masukBgColor = const Color(0xFF73C87D);

      pulangWaktu   = hasPulang ? jamPulang! : '--:--';
      pulangDesc    = hasPulang ? 'Tepat waktu' : 'Shift belum selesai';
      pulangBgColor = const Color(0xFFFF6B6B);

    } else if (normalizedStatus == 'TERLAMBAT') {
      masukWaktu   = hasMasuk ? jamMasuk! : '--:--';
      masukDesc    = hasMasuk ? 'Terlambat' : 'Belum absen';
      masukBgColor = const Color(0xFFFFA726);

      pulangWaktu   = hasPulang ? jamPulang! : '--:--';
      pulangDesc    = hasPulang ? 'Pulang' : 'Shift belum selesai';
      pulangBgColor = hasPulang
          ? const Color(0xFFFF6B6B)
          : Colors.grey.shade400;

    } else if (normalizedStatus == 'ALPHA') {
      masukWaktu   = '--:--';
      masukDesc    = 'Tidak Hadir';
      masukBgColor = const Color(0xFFD61D1D);

      pulangWaktu   = '--:--';
      pulangDesc    = 'Tidak Hadir';
      pulangBgColor = const Color(0xFFD61D1D);

    } else {
      // MENUNGGU ATAU LAINNYA
      masukWaktu   = hasMasuk ? jamMasuk! : '--:--';
      masukDesc    = hasMasuk ? 'Tepat waktu' : 'Menunggu absensi';
      masukBgColor = hasMasuk ? const Color(0xFF73C87D) : const Color(0xFF1969C9);

      pulangWaktu   = hasPulang ? jamPulang! : '--:--';
      pulangDesc    = hasPulang ? 'Tepat waktu' : 'Belum absen';
      pulangBgColor = hasPulang ? const Color(0xFFFF6B6B) : Colors.grey.shade400;
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

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoCard(),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildTimeCard('MASUK',  masukWaktu,  masukDesc,  Icons.login,  masukBgColor)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTimeCard('PULANG', pulangWaktu, pulangDesc, Icons.logout, pulangBgColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 24),
                          SizedBox(width: 8),
                          Text('Foto Absensi',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildPhotoCard('FOTO MASUK',  fotoAbsensiMasuk)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPhotoCard('FOTO PULANG', fotoAbsensiPulang)),
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

  // Radius dihapus — hanya tampil info tanggal, shift, dan lokasi
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Baris 1: Tanggal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F0FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today, color: Color(0xFF0D47A1), size: 20),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HARI & TANGGAL',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(tanggal,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F0FB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.access_time, color: Color(0xFF0D47A1), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('JAM SHIFT',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(waktu,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFEEEEEE)),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F0FB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on_outlined,
                            color: Color(0xFF0D47A1), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('LOKASI',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(pos,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                    ],
                  ),
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
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(time,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
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
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2));
                        },
                      ),
                      const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('Belum Ada Foto',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12)),
      ],
    );
  }
}