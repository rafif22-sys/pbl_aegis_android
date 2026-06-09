import 'package:flutter/material.dart';
import 'detail_absensi_page.dart';
import 'widgets/aegis_top_header.dart';

// --- DATA DUMMY PETUGAS ---
class JadwalData {
  final String nama;
  final String pos;
  final String tanggal;
  final String shift;
  final String waktu;
  final String status;

  JadwalData({
    required this.nama,
    required this.pos,
    required this.tanggal,
    required this.shift,
    required this.waktu,
    required this.status,
  });
}

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  String _activeDay = 'Senin';

  // Data Dummy untuk Daftar Petugas
  final List<JadwalData> daftarPetugas = [
    JadwalData(
      nama: 'Budi Santoso',
      pos: 'Pos Jaga Lt. 4 - 8',
      tanggal: 'Senin, 24 Mei 2026',
      shift: 'Shift 1',
      waktu: '06:00 - 14:00',
      status: 'HADIR',
    ),
    JadwalData(
      nama: 'Andi Putra',
      pos: 'Pos Jaga Lobby Utama',
      tanggal: 'Senin, 24 Mei 2026',
      shift: 'Shift 1',
      waktu: '06:00 - 14:00',
      status: 'MENUNGGU',
    ),
    JadwalData(
      nama: 'Andi Wijaya',
      pos: 'Pos Jaga Area Parkir',
      tanggal: 'Senin, 24 Mei 2026',
      shift: 'Shift 2',
      waktu: '14:00 - 22:00',
      status: 'TERLAMBAT',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB), // Background biru muda
      body: SafeArea(
        child: Column(
          children: [
            const AegisTopHeader(),

            // Bungkus dengan Expanded & SingleChildScrollView agar seluruh halaman bisa di-scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: 100,
                ), // Jarak agar tidak tertutup Bottom Nav
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSectionTitle(
                      'Jadwal Minggu Ini',
                      subtitle: 'Monitoring kehadiran petugas',
                    ),
                    const SizedBox(height: 16),

                    _buildSummaryCards(),
                    const SizedBox(height: 20),

                    _buildDaysFilter(),
                    const SizedBox(height: 16),

                    _buildLocationFilter(),
                    const SizedBox(height: 20),

                    // LIST DAFTAR PETUGAS
                    _buildListHeader(
                      'DAFTAR PETUGAS',
                      Icons.people_alt_outlined,
                    ),
                    _buildJadwalList(daftarPetugas),
                    const SizedBox(height: 32),

                    // BAGIAN RIWAYAT JADWAL (Di bawahnya)
                    _buildSectionTitle('RIWAYAT JADWAL'),
                    const SizedBox(height: 16),
                    _buildRiwayatFilterCard(),
                    const SizedBox(height: 20),

                    // LIST RIWAYAT PETUGAS (Pakai data yang sama sebagai contoh)
                    _buildJadwalList(daftarPetugas),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET JUDUL SECTION DENGAN GARIS BIRU ---
  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: subtitle != null ? 38 : 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1964D4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET KOTAK 4 SUMMARY ---
  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  'TOTAL HADIR',
                  '24',
                  Icons.check_circle,
                  const Color(0xFFBCE3C6),
                  const Color(0xFF1A7B36),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryBox(
                  'TERLAMBAT',
                  '03',
                  Icons.access_time_filled,
                  const Color(0xFFFFEAD1),
                  const Color(0xFFA66421),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  'ALPHA',
                  '01',
                  Icons.cancel,
                  const Color(0xFFFFDEDE),
                  const Color(0xFFC02A2A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  // Khusus Menunggu ada garis pinggir biru tuanya
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2E3F4),
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF0F172A), width: 4),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MENUNGGU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            '08',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.more_horiz,
                            size: 20,
                            color: Colors.blue.shade800,
                          ),
                        ],
                      ),
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

  Widget _buildSummaryBox(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET TOGGLE HARI (Bisa di-scroll ke samping) ---
  Widget _buildDaysFilter() {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          bool isActive = _activeDay == days[index];
          return GestureDetector(
            onTap: () => setState(() => _activeDay = days[index]),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1964D4) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isActive
                    ? null
                    : Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                days[index],
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET DROPDOWN POS & FILTER ---
  Widget _buildLocationFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: Colors.black54,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Pos Utama',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.tune, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HEADER BIRU UNTUK LIST ---
  Widget _buildListHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1964D4),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          Icon(icon, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  // --- WIDGET DAFTAR KARTU JADWAL (Mencegah scroll bersarang) ---
  Widget _buildJadwalList(List<JadwalData> data) {
    return ListView.builder(
      shrinkWrap: true, // WAJIB agar menyatu dengan scroll utama
      physics:
          const NeverScrollableScrollPhysics(), // Mematikan scroll bawaan ListView
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: data.length,
      itemBuilder: (context, index) {
        return _buildCardPetugas(data[index]);
      },
    );
  }

  // --- WIDGET KARTU PETUGAS ---
  Widget _buildCardPetugas(JadwalData data) {
    // Menentukan warna badge status
    Color badgeBgColor;
    Color badgeTextColor;
    if (data.status == 'HADIR') {
      badgeBgColor = const Color(0xFFE0F8E6);
      badgeTextColor = const Color(0xFF1A7B36);
    } else if (data.status == 'TERLAMBAT') {
      badgeBgColor = const Color(0xFFFFF0D4);
      badgeTextColor = const Color(0xFFA66421);
    } else {
      badgeBgColor = const Color(0xFFE4F0FB);
      badgeTextColor = const Color(0xFF1964D4);
    } // MENUNGGU

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.grey),
              ), // Foto Profil Placeholder
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.pos,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.tanggal,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
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
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data.status,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${data.shift} • ${data.waktu}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                // --- UBAH BAGIAN INI ---
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailAbsensiPage(
                        nama: data.nama,
                        tanggal: data.tanggal,
                        shift: data.shift,
                        waktu: data.waktu,
                        pos: data.pos,
                        status: data
                            .status, // Ini yang akan memicu perubahan UI Hadir/Telat/Menunggu!
                      ),
                    ),
                  );
                },
                // -----------------------
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1964D4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(60, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Lihat',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET KARTU FILTER RIWAYAT JADWAL ---
  Widget _buildRiwayatFilterCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TANGGAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'mm/dd/yyyy',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Semua',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text(
                'Terapkan Filter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1), // Biru gelap
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _tampilkanKalenderBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75, // Tinggi 75% layar
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Garis abu-abu di atas
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                  const Text(
                    'Pilih Tanggal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 24), // Spacer
                ],
              ),
              const SizedBox(height: 20),
              // Kalender Bawaan Flutter
              Expanded(
                child: CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (DateTime newDate) {
                    // Logika saat tanggal dipilih
                  },
                ),
              ),
              // Tombol Tampilkan Laporan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tampilkan Laporan',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
