import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'supervisor_sos_form_screen.dart';
import 'laporan_page.dart';
import 'jadwal_page.dart';
import 'riwayat_page.dart';
import 'profil_page.dart';
import 'informasi_page.dart';
import 'buku_tamu_page.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sos/providers/sos_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../petugas/providers/pesan_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class SupervisorHomePage extends StatefulWidget {
  final int initialIndex;
  const SupervisorHomePage({super.key, this.initialIndex = 0});

  @override
  State<SupervisorHomePage> createState() => _SupervisorHomePageState();
}

class _SupervisorHomePageState extends State<SupervisorHomePage> {
  // Variabel untuk melacak tab yang aktif di Bottom Navigation
  late int _selectedIndex;
  late StreamSubscription _tabSub;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    
    _tabSub = NotificationService.tabStream.stream.listen((index) {
      if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<SosProvider>().fetchListSOS(token: token);
        context.read<PesanProvider>().fetchUnreadCount(token: token); 
      }
    });

    // --- TAMBAHAN BARU: MENDENGARKAN PESAN MASUK SAAT APLIKASI DIBUKA ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        final token = context.read<AuthProvider>().token;
        if (token != null) {
          // Diam-diam update titik merah Pesan & SOS di latar belakang
          context.read<PesanProvider>().fetchUnreadCount(token: token);
          context.read<SosProvider>().fetchListSOS(token: token);
        }
      }
    });
  }

  // Daftar halaman untuk setiap tab di Bottom Navigation
  final List<Widget> _pages = [
    const SizedBox(), // Index 0: Dikosongkan sementara untuk Beranda (Dashboard)
    const JadwalPage(), // Index 1: Halaman Jadwal
    const RiwayatPage(), // Index 2
    const InformasiPage(), // Index 3
    const ProfilPage(), // Index 4
    const BukuTamuPage(), // Index 5: Halaman Buku Tamu
    const LaporanPage(), // Index 6: Halaman Laporan
  ];

  @override
  void dispose() {
    _tabSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. Mengambil data dari provider dan mendefinisikan variabel namaSupervisor:
    final authProvider = Provider.of<AuthProvider>(context);
    final String namaSupervisor = authProvider.user?.nama ?? 'Supervisor';

    return Scaffold(
      backgroundColor: const Color(0xFFE6F2F9),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
              // Padding bawah dikurangi agar tidak terlalu jauh dari Bottom Nav Bar
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  // ✅ Variabel namaSupervisor kini sudah terisi dan siap ditampilkan
                  _buildHeader(namaSupervisor),

                  const SizedBox(
                    height: 50,
                  ), // Jarak agak dijauhkan sedikit dari header
                  // MEMANGGIL TOMBOL SOS
                  _buildSOSButton(),

                  const SizedBox(
                    height: 45,
                  ), // Jarak antara SOS dan Menu 2 Kotak
                  // MEMANGGIL MENU BUKU TAMU & LAPORAN
                  _buildActionButtons(),

                  // SizedBox yang sebelumnya 40 kita hapus atau jadikan sangat kecil
                  const SizedBox(height: 10),
                ],
              ),
            )
          : _pages[_selectedIndex],

      // MEMANGGIL CUSTOM BOTTOM NAV BUATANMU
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- WIDGET HEADER (Bagian Biru Tua & Logo Supabase) ---
  Widget _buildHeader(String namaSupervisor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 55,
        bottom: 28,
      ), // Mengikuti standar padding baru
      decoration: const BoxDecoration(
        color: Color(0xFF142940), // Warna biru dongker
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          // Mengambil logo langsung dari Storage Supabase
          Image.network(
            'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/logo_aegis_full.png',
            height: 160, // Silakan sesuaikan tingginya jika kurang besar/kecil
            fit: BoxFit.contain,
            // Tambahkan loading builder biar nggak blank saat internet lambat
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.lightBlueAccent,
                  ),
                ),
              );
            },
            // Penanganan jika link error/berubah
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 70,
              );
            },
          ),
          const SizedBox(height: 4),
          const Text(
            'Selamat Datang,',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Menampilkan nama Supervisor secara dinamis
          Text(
            namaSupervisor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          // Badge Role khusus Supervisor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.lightBlueAccent.withOpacity(0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 13,
                  color: Colors.lightBlueAccent,
                ), // Ikon disesuaikan
                SizedBox(width: 5),
                Text(
                  'Supervisor', // Teks role disesuaikan
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET TOMBOL SOS ---
  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SupervisorSOSFormScreen(),
          ),
        );
      },
      child: Container(
        // Tetap menggunakan margin agar posisinya sejajar dan konsisten 
        // dengan batas tepi Action Buttons di bawahnya
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF09FA6).withOpacity(0.5),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Container(
          // Padding vertikal disesuaikan menjadi 22 agar seragam dengan petugas
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFED4D5C), Color(0xFFF27855)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'KIRIM SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Lingkaran latar putih transparan di belakang ikon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(
                    Icons.shield_outlined, 
                    size: 34, 
                    color: Colors.white,
                  ),
                  const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET TOMBOL MENU (Buku Tamu & Laporan) ---
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BukuTamuPage()),
                );
              },
              child: _buildMenuCard(
                icon: Icons.badge_outlined,
                title: 'Buku Tamu',
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LaporanPage()),
                );
              },
              child: _buildMenuCard(
                icon: Icons.insert_chart_outlined,
                title: 'Laporan',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Komponen satuan untuk Tombol Menu
  Widget _buildMenuCard({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.all(8), // Padding untuk efek border tebal
      decoration: BoxDecoration(
        color: const Color(
          0xFF90C2F9,
        ).withOpacity(0.5), // Border luar biru muda pudar
        borderRadius: BorderRadius.circular(35),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E8DF7), Color(0xFF1A67DD)], // Gradient Biru
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFF1A67DD), // Icon berwarna biru
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CUSTOM BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBottomNavItem(
            icon: Icons.home_filled,
            label: 'Beranda',
            index: 0,
          ),
          _buildBottomNavItem(
            icon: Icons.calendar_month,
            label: 'Jadwal',
            index: 1,
          ),
          _buildBottomNavItem(
            icon: Icons.warning_amber_rounded,
            label: 'Riwayat',
            index: 2,
          ),
          _buildBottomNavItem(
            icon: Icons.info_outline,
            label: 'Informasi',
            index: 3,
          ),
          _buildBottomNavItem(
            icon: Icons.person_outline,
            label: 'Profil',
            index: 4,
          ),
        ],
      ),
    );
  }

  // Komponen satuan untuk item Bottom Navigation
  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;
    bool hasMenungguBantuan = label == 'Riwayat' && 
        context.watch<SosProvider>().totalMenunggu > 0;
    
    // ← TAMBAHKAN INI
    bool hasUnreadPesan = label == 'Informasi' && 
        context.watch<PesanProvider>().unreadCount > 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE4F1FA) : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: isSelected
                        ? const Color(0xFF2280F0)
                        : Colors.grey.shade400,
                  ),
                  if (hasMenungguBantuan)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  // ← TAMBAHKAN INI
                  if (hasUnreadPesan)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF2280F0)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
