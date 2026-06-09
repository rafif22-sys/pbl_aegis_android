import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/aegis_top_header.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'data_diri_petugas_screen.dart';

class ProfilPetugasScreen extends StatelessWidget {
  const ProfilPetugasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB),
      body: SafeArea(
        child: Column(
          children: [
            const AegisTopHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildProfileHeader(user),
                    const SizedBox(height: 30),
                    _buildMenuContainer(context),
                    const SizedBox(height: 30),
                    const _TombolLogoutPetugas(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    return Column(
      children: [
        Container(
          height: 110,
          width: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            image: user?.fotoProfil != null
                ? DecorationImage(
                    image: NetworkImage(user!.fotoProfil!),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: user?.fotoProfil == null
              ? const Icon(Icons.person, size: 55, color: Color(0xFF1976D2))
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user?.nama ?? '-',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const Text(
          'Petugas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuContainer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person,
            title: 'Data Diri',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DataDiriScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(icon: Icons.lock, title: 'Keamanan', onTap: () {}),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F0FB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Icon(icon, color: const Color(0xFF1976D2), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }
}

class _TombolLogoutPetugas extends StatelessWidget {
  const _TombolLogoutPetugas();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final bool? konfirmasi = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konfirmasi Keluar'),
              content: const Text(
                'Apakah Anda yakin ingin keluar dari akun Petugas?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );

        if (konfirmasi == true && context.mounted) {
          final authProvider = context.read<AuthProvider>();
          await authProvider.logout();

          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200),
        ),
      ),
      icon: const Icon(Icons.logout),
      label: const Text(
        'Keluar Akun',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
