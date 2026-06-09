import 'package:flutter/material.dart';
import 'widgets/aegis_top_header.dart';

class DetailSosPage extends StatefulWidget {
  final String nama;
  final String waktu;
  final String initialStatus;

  const DetailSosPage({
    super.key,
    required this.nama,
    required this.waktu,
    required this.initialStatus,
  });

  @override
  State<DetailSosPage> createState() => _DetailSosPageState();
}

class _DetailSosPageState extends State<DetailSosPage> {
  late String status;

  @override
  void initState() {
    super.initState();
    status =
        widget.initialStatus; // Set status awal (MENUNGGU BANTUAN / SELESAI)
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildDetailCard(),
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
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 16),
          const Text(
            'PESAN SOS',
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

  Widget _buildDetailCard() {
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
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Merah
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFD30000), // Merah SOS
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PESAN SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'ID: SOS-992384-TX',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CRITICAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Gambar Peta Placeholder
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white54,
                  BlendMode.lighten,
                ),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.warning,
                color: Colors.deepOrange.shade400,
                size: 60,
              ),
            ),
          ),

          // Info Petugas & Waktu
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PETUGAS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFFE4F0FB),
                                child: const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WAKTU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.waktu,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Deskripsi Kejadian
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DESKRIPSI KEJADIAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: '"Terdapat '),
                            TextSpan(
                              text: 'kebakaran',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' pada lokasi tersebut, pengirim memerlukan bantuan ',
                            ),
                            TextSpan(
                              text: 'satpam',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            TextSpan(text: ' dan '),
                            TextSpan(
                              text: 'warga',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            TextSpan(text: ' segera."'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Dinamis (Berubah sesuai status)
                SizedBox(
                  width: double.infinity,
                  child: status == 'MENUNGGU BANTUAN'
                      ? ElevatedButton.icon(
                          onPressed: () {
                            // Ubah status menjadi selesai saat diklik
                            setState(() {
                              status = 'SELESAI';
                            });
                          },
                          icon: const Text(
                            'KONFIRMASI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          label: const Icon(Icons.check_circle, size: 20),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: null, // Tombol mati kalau sudah selesai
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF5C8DF6,
                            ), // Biru lebih terang
                            disabledBackgroundColor: const Color(0xFF5C8DF6),
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'SELESAI DITANGANI OLEH\nPETUGAS ANDI SIRANDI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
