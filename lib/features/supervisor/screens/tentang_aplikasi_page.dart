import 'package:flutter/material.dart';
import 'widgets/aegis_top_header.dart';

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({super.key});

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
                    const SizedBox(height: 8),
                    _buildAboutContent(),
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
            'Tentang Aplikasi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: const Text(
        'AEGIS (Advanced Emergency & Guard Information System) adalah aplikasi patroli keamanan berbasis digital yang dirancang untuk meningkatkan efektivitas, transparansi, dan respons dalam pengawasan lingkungan perumahan maupun kawasan industri.\n\n'
        'Aplikasi ini menggantikan sistem manual seperti buku jaga dengan platform terintegrasi yang memungkinkan petugas keamanan melakukan absensi, patroli, pencatatan tamu, serta pelaporan insiden secara real-time. Dengan dukungan teknologi seperti GPS, unggah foto, dan notifikasi langsung, setiap aktivitas keamanan dapat dipantau dan terdokumentasi secara akurat.\n\n'
        'AEGIS juga dilengkapi dengan fitur darurat (SOS) yang memungkinkan petugas mengirimkan sinyal bantuan beserta lokasi secara instan kepada supervisor, sehingga respons terhadap situasi kritis dapat dilakukan dengan cepat dan tepat.\n\n'
        'Melalui sistem ini, pengelolaan keamanan menjadi lebih terstruktur, efisien, dan dapat dipertanggungjawabkan, baik untuk petugas di lapangan maupun pihak pengawas.',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF475569),
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}