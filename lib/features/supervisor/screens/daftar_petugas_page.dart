import 'package:flutter/material.dart';
import 'detail_petugas_page.dart';
import 'widgets/aegis_top_header.dart';

// Model data petugas
class PetugasData {
  final String nama;
  final String id;
  final String masaKerja;
  final String imgUrl;

  PetugasData({required this.nama, required this.id, required this.masaKerja, required this.imgUrl});
}

class DaftarPetugasPage extends StatefulWidget {
  const DaftarPetugasPage({super.key});

  @override
  State<DaftarPetugasPage> createState() => _DaftarPetugasPageState();
}

class _DaftarPetugasPageState extends State<DaftarPetugasPage> {
  // Data Dummy sesuai gambar
  final List<PetugasData> listPetugas = [
    PetugasData(nama: 'Budi Prakoso', id: 'ID. 001', masaKerja: 'Masa kerja : 1 Tahun', imgUrl: 'https://randomuser.me/api/portraits/men/11.jpg'),
    PetugasData(nama: 'Andi Surandi', id: 'ID. 002', masaKerja: 'Masa kerja : 2 Tahun', imgUrl: 'https://randomuser.me/api/portraits/men/32.jpg'),
    PetugasData(nama: 'Susilo Putra', id: 'ID. 003', masaKerja: 'Masa kerja : 6 Bulan', imgUrl: 'https://randomuser.me/api/portraits/men/44.jpg'),
    PetugasData(nama: 'Mikael Putra', id: 'ID. 004', masaKerja: 'Masa kerja : 5 Tahun', imgUrl: 'https://randomuser.me/api/portraits/men/55.jpg'),
    PetugasData(nama: 'Putra Pratama', id: 'ID. 005', masaKerja: 'Masa kerja : 3 Tahun', imgUrl: 'https://randomuser.me/api/portraits/men/62.jpg'),
    PetugasData(nama: 'Ahmad Wijaya', id: 'ID. 006', masaKerja: 'Masa kerja : 1 Tahun', imgUrl: 'https://randomuser.me/api/portraits/men/71.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB),
      body: SafeArea(
        child: Column(
          children: [
            const AegisTopHeader(),
            // _buildTopHeader(),
            _buildTitleBar(context),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: ListView.builder(
                  itemCount: listPetugas.length,
                  itemBuilder: (context, index) {
                    return _buildPetugasCard(listPetugas[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildTopHeader() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //     decoration: const BoxDecoration(
  //       color: Color(0xFF0F172A),
  //       borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
  //     ),
  //     child: Row(
  //       children: [
  //         // Logo Kecil dari Supabase
  //         Image.network(
  //           'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/aegis-nobg.png',
  //           height: 24,
  //           width: 24,
  //           fit: BoxFit.contain,
  //           errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.lightBlueAccent, size: 24), // Fallback kalau internet mati
  //         ),
  //         const SizedBox(width: 8),
  //         const Expanded(
  //           child: Text(
  //             'ADVANCED EMERGENCY & GUARD INFORMATION SYSTEM',
  //             style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.5),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
            'Daftar Petugas',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Masukkan nama petugas',
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPetugasCard(PetugasData data) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke Detail Petugas
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPetugasPage(
              nama: data.nama,
              idPetugas: data.id.replaceAll('ID. ', ''), // Mengambil angkanya saja
              masaKerja: data.masaKerja,
              imgUrl: data.imgUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: NetworkImage(data.imgUrl), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(data.masaKerja, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text(data.id, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}