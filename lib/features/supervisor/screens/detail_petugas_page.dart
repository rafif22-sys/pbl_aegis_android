import 'package:flutter/material.dart';
import 'widgets/aegis_top_header.dart';

class DetailPetugasPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String imgUrl;

  const DetailPetugasPage({super.key, required this.data, required this.imgUrl});

  // Helper untuk baca data kosong biar nggak error
  String val(String key) => data[key]?.toString() ?? '-';

  // Helper untuk ubah format tanggal (2026-04-30 jadi 30/04/2026)
  String formatTgl(String dateStr) {
    if (dateStr.isEmpty || dateStr == '-') return '-';
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) return '${parts[2].substring(0,2)}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB),
      body: SafeArea(
        child: Column(
          children: [
            const AegisTopHeader(),
            _buildTitleBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildInformasiPribadi(),
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
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 16),
          const Text(
            'Data Petugas',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), // Bentuk squircle sesuai Figma
            color: Colors.grey.shade300,
            image: DecorationImage(
              image: NetworkImage(imgUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
          ),
        ),
        const SizedBox(height: 16),
        Text(val('nama'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 4),
        Text(
          'ID PETUGAS : ${val('id').padLeft(3, '0')}', 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    // Tangkap angka dinamis yang dikirim dari Laravel
    // Kalau ternyata datanya kosong, kita kasih default '0'
    String kehadiran = data['total_kehadiran']?.toString() ?? '0';
    String patroli = data['patroli_selesai']?.toString() ?? '0';

    return Row(
      children: [
        _buildStatBox('TOTAL\nKEHADIRAN', kehadiran), // 👈 Angka 124 diganti variabel kehadiran
        const SizedBox(width: 16),
        _buildStatBox('PATROLI\nSELESAI', patroli),    // 👈 Angka 200 diganti variabel patroli
      ],
    );
  }

  Widget _buildStatBox(String title, String count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1976D2), // Biru Figma
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildInformasiPribadi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: Colors.black54, size: 20),
              SizedBox(width: 8),
              Text('Informasi Pribadi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          _buildInfoRow('Nama', val('nama')),
          _buildInfoRow('Tanggal Lahir', formatTgl(val('tanggal_lahir'))),
          _buildInfoRow('Alamat', val('alamat')),
          _buildInfoRow('Email', val('email')),
          _buildInfoRow('No. HP', val('no_hp')),
          _buildInfoRow('Bergabung', formatTgl(val('tanggal_bergabung'))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100, // Lebar fixed untuk label agar sejajar rapi
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right, // Teks value nempel di kanan
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}