import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../auth/providers/auth_provider.dart';
import 'sos_form_screen.dart';
import 'riwayat_sos_screen.dart';
import 'jadwal_screen.dart';
import 'buku_tamu_screen.dart';
import '../../sos/providers/sos_provider.dart';
import 'pesan_screen.dart';
import '../providers/pesan_provider.dart';
import '../../../core/services/notification_service.dart';
import 'dart:async';
import 'absensi_screen.dart';
import 'profil_petugas_screen.dart';

class PetugasHomeScreen extends StatefulWidget {
  final int initialIndex;
  const PetugasHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<PetugasHomeScreen> createState() => _PetugasHomeScreenState();
}

class _PetugasHomeScreenState extends State<PetugasHomeScreen>
  with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late StreamSubscription _tabSub;

  final List<Widget> _pages = [
    const SizedBox(), // Index 0: Beranda (dihandle di body)
    const JadwalScreen(), // Index 1: Jadwal
    const RiwayatSosScreen(), // Index 2: Riwayat
    const MessageScreen(), // Index 3: Pesan
    const ProfilPetugasScreen(), // Index 4: Profil
  ];

  late AnimationController _animController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late Animation<double> _sosFade;
  late Animation<double> _sosScale;

  late Animation<double> _menuFade;
  late Animation<Offset> _menuSlide;

  StreamSubscription? _fcmSub; // ← TAMBAH INI

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _tabSub = NotificationService.tabStream.stream.listen((index) {
      if (mounted) setState(() => _selectedIndex = index);
    });

    // ← TAMBAH BLOK INI
    _fcmSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        final token = context.read<AuthProvider>().token;
        if (token != null) {
          context.read<PesanProvider>().fetchUnreadCount(token: token);
          context.read<SosProvider>().fetchListSOS(token: token);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<SosProvider>().fetchListSOS(token: token);
        context.read<PesanProvider>().fetchUnreadCount(token: token);
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
          ),
        );

    _sosFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _sosScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _menuFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
    _menuSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
          ),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _tabSub.cancel();
    _fcmSub?.cancel(); // ← TAMBAH INI
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final String namaPetugas = user?.nama ?? 'Petugas';

    return Scaffold(
      backgroundColor: const Color(0xFFDCEFFE), // ← sesuai
      body: _selectedIndex == 0
          ? Column(
              children: [
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _buildHeader(namaPetugas),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _sosFade,
                          child: ScaleTransition(
                            scale: _sosScale,
                            child: _buildSOSButton(),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeTransition(
                          opacity: _menuFade,
                          child: SlideTransition(
                            position: _menuSlide,
                            child: _buildActionButtons(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader(String namaPetugas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 55, bottom: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF142940),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Image.network(
            'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/logo_aegis_full.png',
            height: 160,
            fit: BoxFit.contain,
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
          Text(
            namaPetugas,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: Colors.lightBlueAccent,
                ),
                SizedBox(width: 5),
                Text(
                  'Petugas Keamanan',
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

  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SOSFormScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF09FA6).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Container(
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
                color: Colors.redAccent.withValues(alpha: 0.4),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BukuTamuPage()),
              );

              // Navigator.push(context,
              //   MaterialPageRoute(builder: (_) => const BukuTamuPetugasPage()));
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
                MaterialPageRoute(builder: (_) => const AbsensiScreen()),
              );
            },
            child: _buildMenuCard(
              icon: Icons.fact_check_outlined,
              title: 'Presensi',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF90C2F9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E8DF7), Color(0xFF1A67DD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF1A67DD)),
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

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(icon: Icons.home_filled, label: 'Beranda', index: 0),
          _buildNavItem(icon: Icons.calendar_month, label: 'Jadwal', index: 1),
          _buildNavItem(
            icon: Icons.warning_amber_rounded,
            label: 'Riwayat',
            index: 2,
          ),
          _buildNavItem(icon: Icons.info_outline, label: 'Informasi', index: 3),
          _buildNavItem(icon: Icons.person_outline, label: 'Profil', index: 4),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    final bool hasMenungguBantuan = label == 'Riwayat' && context.watch<SosProvider>().totalMenunggu > 0;
    final bool hasUnreadPesan = label == 'Informasi' && context.watch<PesanProvider>().unreadCount > 0;

    return GestureDetector(
      onTap: () {
        if (_selectedIndex == 3 && index != 3) {
          final token = context.read<AuthProvider>().token;
          if (token != null && context.read<PesanProvider>().unreadCount > 0) {
            context.read<PesanProvider>().markAllRead(token: token);
          }
        }
        setState(() => _selectedIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // ← naik dari 12,7
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE4F1FA) : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 26, // ← naik dari 24
                    color: isSelected ? const Color(0xFF2280F0) : Colors.grey.shade400,
                  ),
                  if (hasMenungguBantuan || hasUnreadPesan)
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
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12, // ← naik dari 11
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF2280F0) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
