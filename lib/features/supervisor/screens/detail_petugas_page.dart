import 'package:flutter/material.dart';
import 'widgets/aegis_top_header.dart';

class DetailPetugasPage extends StatelessWidget {
  final String nama;
  final String idPetugas;
  final String masaKerja;
  final String imgUrl;

  const DetailPetugasPage({
    super.key,
    required this.nama,
    required this.idPetugas,
    required this.masaKerja,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB), // Background biru muda Aegis
      body: SafeArea(
        child: Column(
          children: [
            const AegisTopHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    _buildTitleBar(context),
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildInfoPribadiCard(),
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
            'Data Petugas',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Foto Profil Kotak Rounded
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(imgUrl),
                fit: BoxFit.cover,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
          ),
          const SizedBox(height: 16),
          Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 4),
          Text('ID PETUGAS : $idPetugas', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // Statistik Petugas
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2), // Biru Aegis
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Text('TOTAL\nKEHADIRAN', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('124', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Text('PATROLI\nSELESAI', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('200', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPribadiCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text('Informasi Pribadi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Nama', nama),
          _buildDivider(),
          _buildInfoRow('Tanggal Lahir', '12 Juni 1985'),
          _buildDivider(),
          _buildInfoRow('Alamat', 'Jl. Merdeka No. 123,\nJakarta Pusat', isMultiline: true),
          _buildDivider(),
          _buildInfoRow('Email', '${nama.toLowerCase().split(' ')[0]}@gmail.com'),
          _buildDivider(),
          _buildInfoRow('No. HP', '+62 812-3456-7890'),
          _buildDivider(),
          _buildInfoRow('Bergabung', '15 Januari 2020'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isMultiline = false}) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
    );
  }
}