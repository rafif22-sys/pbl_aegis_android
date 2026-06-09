import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/aegis_top_header.dart';
import '../../auth/providers/auth_provider.dart';

class DataDiriScreen extends StatelessWidget {
  const DataDiriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB),
      body: SafeArea(
        child: Column(
          children: [
            const AegisTopHeader(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Avatar + name
            Column(
              children: [
                Container(
                  height: 120,
                  width: 120,
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: user?.fotoProfil == null
                      ? const Icon(Icons.person, size: 64, color: Color(0xFF1976D2))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.nama ?? '-',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Warga',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nama Lengkap'),
                    const SizedBox(height: 6),
                    _readOnlyField(user?.nama ?? ''),
                    const SizedBox(height: 12),
                    _label('Nomor Telepon'),
                    const SizedBox(height: 6),
                    _readOnlyField(user?.noHp ?? ''),
                    const SizedBox(height: 12),
                    _label('Gmail'),
                    const SizedBox(height: 6),
                    _readOnlyField(user?.email ?? ''),
                    const SizedBox(height: 12),
                    _label('Alamat'),
                    const SizedBox(height: 6),
                    _readOnlyField(user?.alamat ?? '', maxLines: 4),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
    );
  }

  Widget _readOnlyField(String value, {int maxLines = 1}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value.isNotEmpty ? value : '-',
        style: const TextStyle(fontSize: 14),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
