import 'package:flutter/material.dart';
import 'detail_patroli_page.dart';
import 'widgets/aegis_top_header.dart';

class LaporanHarianPage extends StatefulWidget {
  final String tanggal;

  const LaporanHarianPage({super.key, required this.tanggal});

  @override
  State<LaporanHarianPage> createState() => _LaporanHarianPageState();
}

class _LaporanHarianPageState extends State<LaporanHarianPage> {
  int _activeShift = 1; // Default Shift 1

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB), // Background biru muda
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AegisTopHeader(),
            _buildTitleBar(context),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal Laporan
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        widget.tanggal,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Kotak Summary 2x2
                    _buildSummaryGrid(),
                    const SizedBox(height: 24),

                    // Toggle Shift 1, 2, 3
                    _buildShiftToggle(),
                    const SizedBox(height: 20),

                    // List Laporan per Shift
                    _buildPatrolList(),
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
  Widget _buildSummaryGrid() {
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
                  '10',
                  'Total Patroli',
                  Icons.verified_user_outlined,
                  const Color(0xFFDDF3F5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  '24',
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
                  '24',
                  'Petugas',
                  Icons.person,
                  const Color(0xFFBDCBE1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  '24',
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
  Widget _buildShiftToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2), // Background abu-abu
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildShiftTab(1, 'Shift 1'),
          _buildShiftTab(2, 'Shift 2'),
          _buildShiftTab(3, 'Shift 3'),
        ],
      ),
    );
  }

  Widget _buildShiftTab(int shiftNumber, String label) {
    bool isActive = _activeShift == shiftNumber;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeShift = shiftNumber;
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
  Widget _buildPatrolList() {
    // Logika sederhana untuk menampilkan data berbeda sesuai tab shift
    if (_activeShift == 1) {
      return Column(
        children: [
          _buildPatrolCard(
            'Aman',
            'Budi Santoso',
            '07.00 - 09.00',
            '5 checkpoint',
            const Color(0xFF34A853),
          ),
          _buildPatrolCard(
            'Terdapat isu',
            'Andi Wijaya',
            '08.30 - 11.00',
            '3 checkpoint',
            const Color(0xFFD30000),
          ),
        ],
      );
    } else if (_activeShift == 2) {
      return Column(
        children: [
          _buildPatrolCard(
            'Aman',
            'John Doe',
            '15.30 - 17.45',
            '5 checkpoint',
            const Color(0xFF34A853),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildPatrolCard(
            '',
            'Budi Santoso',
            '23.00 - 02.00',
            '5 checkpoint',
            Colors.transparent,
          ),
        ],
      );
    }
  }

  Widget _buildPatrolCard(
    String status,
    String nama,
    String waktu,
    String checkpoint,
    Color statusColor,
  ) {
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
              color: Color(0xFFEAF4FB), // Biru sangat muda
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (status
                    .isNotEmpty) // Tampilkan kotak warna hanya jika ada status
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: Text(
                      checkpoint,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail Petugas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade300,
                    ), // Foto placeholder
                    const SizedBox(width: 12),
                    Text(
                      'Petugas: $nama',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Cari baris kode ini di dalam _buildPatrolCard:
                Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 14,
                      color: Colors.blue.shade300,
                    ),
                    const SizedBox(width: 4),
                    // BUNGKUS TEKS DETAIL DENGAN GESTURE DETECTOR
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPatroliPage(
                              namaPetugas: nama,
                            ), // Kirim nama petugasnya
                          ),
                        );
                      },
                      child: Text(
                        'Detail',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
}
