import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import 'detail_petugas_page.dart';
import 'widgets/aegis_top_header.dart';

class PetugasData {
  final String nama;
  final String id;
  final String masaKerja;
  final String imgUrl;
  final Map<String, dynamic> rawData; // 👈 Tambahan untuk bawa data lengkap

  PetugasData({
    required this.nama,
    required this.id,
    required this.masaKerja,
    required this.imgUrl,
    required this.rawData,
  });

  factory PetugasData.fromJson(Map<String, dynamic> json) {
    // ... (Logika URL foto tetap sama seperti sebelumnya) ...
    String rawFoto = json['foto_profil']?.toString() ?? '';
    String fotoUrl = 'https://ui-avatars.com/api/?name=${json['nama'] ?? 'P'}';
    
    if (rawFoto.isNotEmpty) {
      String resolved = rawFoto
          .replaceAll('http://127.0.0.1:54321', AppConfig.supabaseUrl)
          .replaceAll('http://localhost:54321', AppConfig.supabaseUrl);
      if (resolved.startsWith('http')) {
        fotoUrl = resolved;
      } else {
        String cleaned = resolved.startsWith('/') ? resolved.substring(1) : resolved;
        fotoUrl = '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.supabaseBucket}/$cleaned';
      }
    }

    String masaKerjaText = 'Masa kerja : Baru';
    if (json['tanggal_bergabung'] != null) {
       int tahunMasuk = int.tryParse(json['tanggal_bergabung'].toString().substring(0, 4)) ?? DateTime.now().year;
       int masa = DateTime.now().year - tahunMasuk;
       masaKerjaText = masa > 0 ? 'Masa kerja : $masa Tahun' : 'Masa kerja : < 1 Tahun';
    }

    return PetugasData(
      nama: json['nama']?.toString() ?? 'Petugas Tidak Diketahui',
      id: json['id']?.toString() ?? '000',
      masaKerja: masaKerjaText,
      imgUrl: fotoUrl,
      rawData: json, // 👈 Simpan semua data dari database ke sini
    );
  }
}

class DaftarPetugasPage extends StatefulWidget {
  const DaftarPetugasPage({super.key});

  @override
  State<DaftarPetugasPage> createState() => _DaftarPetugasPageState();
}

class _DaftarPetugasPageState extends State<DaftarPetugasPage> {
  List<PetugasData> _listPetugas = [];
  List<PetugasData> _filteredPetugas = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDaftarPetugas());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPetugas = _listPetugas.where((petugas) {
        return petugas.nama.toLowerCase().contains(query) ||
            petugas.id.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchDaftarPetugas() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesi telah habis, silakan login kembali.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // API Endpoint Laravel: Pastikan backend sudah memfilter petugas berdasarkan ID Supervisor yang login
      final uri = Uri.parse('${ApiClient.baseUrl}/supervisor/petugas');
      final response = await http.get(
        uri,
        headers: ApiClient.headers(token: token),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Ekstraksi array data secara aman
        List<dynamic> dataArray = [];
        if (body is List) {
          dataArray = body;
        } else if (body is Map &&
            body.containsKey('data') &&
            body['data'] is List) {
          dataArray = body['data'];
        }

        final parsedList = dataArray
            .map((json) => PetugasData.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            _listPetugas = parsedList;
            _filteredPetugas = parsedList;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
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
            _buildSearchBar(),

            // --- TAMBAHKAN BAGIAN INI UNTUK MENAMPILKAN TOTAL PETUGAS ---
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 28, top: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt,
                    size: 18,
                    color: Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${_filteredPetugas.length} Petugas',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // -----------------------------------------------------------
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1964D4)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDaftarPetugas,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredPetugas.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada petugas yang ditemukan.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDaftarPetugas,
      child: ListView.builder(
        itemCount: _filteredPetugas.length,
        itemBuilder: (context, index) {
          return _buildPetugasCard(_filteredPetugas[index]);
        },
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
            'Daftar Petugas',
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Masukkan nama petugas',
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPetugasCard(PetugasData data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPetugasPage(
              data: data.rawData, // 👈 Kirim data lengkap ke halaman detail
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
                image: DecorationImage(
                  image: NetworkImage(data.imgUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.masaKerja,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'ID. ${data.id}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
