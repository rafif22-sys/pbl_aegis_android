import 'package:flutter/material.dart';

class SOSFormPage extends StatefulWidget {
  const SOSFormPage({super.key});

  @override
  State<SOSFormPage> createState() => _SOSFormPageState();
}

class _SOSFormPageState extends State<SOSFormPage> {
  // Menyimpan pilihan kategori darurat
  String _selectedCategory = 'KEBAKARAN'; // Default terpilih
  bool _isLainnyaChecked = false;
  bool _butuhBantuanWarga = false; // false = TIDAK, true = YA
  final TextEditingController _lainnyaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB), // Background biru sangat muda
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pop(context), // Kembali ke halaman sebelumnya
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon SOS Merah
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD30000), // Merah gelap
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PANGGILAN SOS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih keadaan darurat:',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Grid Pilihan Darurat
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryOption(
                        'KEBAKARAN',
                        Icons.local_fire_department_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryOption(
                        'PENCURIAN',
                        Icons.person_off_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryOption(
                        'HEWAN LIAR',
                        Icons.pets_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryOption(
                        'BENCANA ALAM',
                        Icons.home_work_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Checkbox "Lainnya"
                Row(
                  children: [
                    Checkbox(
                      value: _isLainnyaChecked,
                      onChanged: (value) {
                        setState(() {
                          _isLainnyaChecked = value ?? false;
                          if (_isLainnyaChecked) {
                            _selectedCategory = 'LAINNYA';
                          } else {
                            // Kosongkan isi textfield kalau centang dihilangkan
                            _lainnyaController.clear();
                          }
                        });
                      },
                    ),
                    const Text(
                      'LAINNYA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // TextField Keterangan (Hanya aktif jika "Lainnya" dicentang)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    // Warnanya berubah: terang kalau dicentang, abu-abu gelap kalau nggak
                    color: _isLainnyaChecked
                        ? const Color(0xFFF5F7FA)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller:
                        _lainnyaController, // Pastikan ini ditambahkan ya
                    enabled: _isLainnyaChecked,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Misal: Gangguan kebisingan...',
                      hintStyle: TextStyle(
                        color: _isLainnyaChecked
                            ? Colors.grey
                            : Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bantuan Warga Toggle
                const Text(
                  'APAKAH BUTUH BANTUAN SEMUA WARGA?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Tombol YA
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _butuhBantuanWarga = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _butuhBantuanWarga
                                  ? const Color(0xFF0D47A1)
                                  : Colors.white,
                              border: Border.all(
                                color: const Color(0xFF0D47A1),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'YA',
                                style: TextStyle(
                                  fontWeight: _butuhBantuanWarga
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _butuhBantuanWarga
                                      ? Colors.white
                                      : const Color(0xFF0D47A1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tombol TIDAK
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _butuhBantuanWarga = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_butuhBantuanWarga
                                  ? const Color(0xFF0D47A1)
                                  : Colors.white,
                              border: Border.all(
                                color: const Color(0xFF0D47A1),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'TIDAK',
                                style: TextStyle(
                                  fontWeight: !_butuhBantuanWarga
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: !_butuhBantuanWarga
                                      ? Colors.white
                                      : const Color(0xFF0D47A1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Batal & Kirim
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD30000), // Merah
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'BATAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _kirimSOS, // Memanggil fungsi kirim
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745), // Hijau
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'KIRIM',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.send, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Pembantu untuk Kotak Pilihan Kategori
  Widget _buildCategoryOption(String title, IconData icon) {
    bool isSelected = _selectedCategory == title && !_isLainnyaChecked;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
          _isLainnyaChecked =
              false; // Matikan checkbox lainnya jika milih kategori standar
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D47A1)
              : const Color(0xFFF5F7FA), // Biru gelap jika dipilih
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi Logika saat tombol KIRIM ditekan
  void _kirimSOS() {
    // 1. Tampilkan Notifikasi (Snackbar) Warna Hijau
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PESAN SOS BERHASIL DIKIRIMKAN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10),
            Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
        backgroundColor: const Color(
          0xFF28A745,
        ), // Warna hijau persis seperti desainmu
        behavior: SnackBarBehavior
            .floating, // Supaya melayang (tidak nempel dasar layar)
        margin: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).size.height -150, // Atur angka 150 jika kurang pas posisinya
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3), // Muncul selama 3 detik
      ),
    );

    // 2. Navigasi kembali ke halaman Home (tutup form)
    Navigator.pop(context);
  }
}
