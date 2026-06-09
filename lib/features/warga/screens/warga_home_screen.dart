import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sos/providers/sos_provider.dart';
import '../../sos/models/sos_model.dart';
import 'sos_form_screen.dart';
import 'buku_tamu_screen.dart';
import 'laporan_patroli_screen.dart';
import 'riwayat_sos_screen.dart';
import 'profil_screen.dart';

class WargaHomeScreen extends StatefulWidget {
  const WargaHomeScreen({super.key});

  @override
  State<WargaHomeScreen> createState() => _WargaHomeScreenState();
}

class _WargaHomeScreenState extends State<WargaHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SizedBox(),
    const RiwayatSosScreen(),
    const ProfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch data SOS saat pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSos());
  }

  Future<void> _fetchSos() async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    await context.read<SosProvider>().fetchListSOS(token: token);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String namaWarga = authProvider.user?.nama ?? 'Warga';

    // Cek apakah ada SOS yang masih menunggu
    final sosProvider   = context.watch<SosProvider>();
    final adaSosMenunggu = sosProvider.sosList
        .any((s) => s.status == StatusSOS.menungguBantuan);

    return Scaffold(
      backgroundColor: const Color(0xFFDCEFFE),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  _buildHeader(namaWarga),
                  const SizedBox(height: 50),
                  _buildSOSButton(),
                  const SizedBox(height: 45),
                  _buildActionButtons(),
                  const SizedBox(height: 10),
                ],
              ),
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(adaSosMenunggu),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(String namaWarga) {
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
            namaWarga,
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
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 13, color: Colors.orange),
                SizedBox(width: 5),
                Text(
                  'Warga',
                  style: TextStyle(
                    color: Colors.orange,
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

  // ── SOS BUTTON ─────────────────────────────────────────────────────────────
  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SosFormScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF09FA6).withOpacity(0.5),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(Icons.shield_outlined, size: 34, color: Colors.white),
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

  // ── ACTION BUTTONS ─────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BukuTamuScreen()),
              ),
              child: _buildMenuCard(
                icon: Icons.badge_outlined,
                title: 'Buku Tamu',
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LaporanPatroliScreen()),
              ),
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

  Widget _buildMenuCard({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF90C2F9).withOpacity(0.5),
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
              child: Icon(icon, size: 36, color: const Color(0xFF1A67DD)),
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

  // ── BOTTOM NAV ─────────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar(bool adaSosMenunggu) {
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(
            icon: Icons.home_filled,
            label: 'Beranda',
            index: 0,
            showBadge: false,
          ),
          _buildBottomNavItem(
            icon: Icons.warning_amber_rounded,
            label: 'Riwayat',
            index: 1,
            showBadge: adaSosMenunggu, // ← badge merah jika ada SOS menunggu
          ),
          _buildBottomNavItem(
            icon: Icons.person_outline,
            label: 'Profil',
            index: 2,
            showBadge: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool showBadge,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE4F1FA)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isSelected
                        ? const Color(0xFF2280F0)
                        : Colors.grey.shade400,
                  ),
                ),

                
                if (showBadge)
                  Positioned(
                    top: 2,
                    right: 10,
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