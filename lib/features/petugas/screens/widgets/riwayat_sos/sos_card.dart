import 'package:flutter/material.dart';
import '../../../../sos/models/sos_model.dart';
import '../../../../../core/config/app_config.dart'; // ← sesuaikan path

class SosCard extends StatelessWidget {
  final SosModel sos;
  final VoidCallback onTap;

  const SosCard({super.key, required this.sos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMenunggu = sos.status == StatusSOS.menungguBantuan;
    final namaUser   = sos.user?.nama ?? 'Tidak diketahui';
    final String? fotoUrl = sos.user?.fotoProfil
      ?.replaceAll('http://127.0.0.1:54321', AppConfig.supabaseUrl)
      ?.replaceAll('http://localhost:54321', AppConfig.supabaseUrl);

    final dt         = DateTime.tryParse(sos.waktuKirim)?.toLocal();
    final tanggalStr = dt != null ? _formatTanggal(dt) : sos.waktuKirim;
    final jamStr     = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tanggalStr,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                _buildStatusBadge(isMenunggu, sos.status.label.toUpperCase()),
              ],
            ),
            const SizedBox(height: 4),
            Text(jamStr,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(_ikonJenis(sos.jenisKeadaan), size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(sos.jenisKeadaan.label,
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
                if (sos.bantuanWarga) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text('Butuh Warga',
                        style: TextStyle(fontSize: 10, color: Colors.orange)),
                  ),
                ],
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Row(
              children: [
                _buildAvatar(fotoUrl, namaUser),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(namaUser,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87)),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMenunggu ? const Color(0xFF0D47A1) : Colors.grey.shade200,
                  ),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 14,
                      color: isMenunggu ? Colors.white : Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? fotoUrl, String namaUser) {
    Widget inisial = CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFE4F0FB),
      child: Text(
        namaUser.isNotEmpty ? namaUser[0].toUpperCase() : '?',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
      ),
    );

    if (fotoUrl == null) return inisial;

    return ClipOval(
      child: Image.network(
        fotoUrl,
        width: 36, height: 36, fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFE4F0FB), shape: BoxShape.circle),
            child: const Center(
              child: SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF0D47A1)),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => inisial,
      ),
    );
  }

  Widget _buildStatusBadge(bool isMenunggu, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        isMenunggu ? const Color(0xFFFFE5E5) : const Color(0xFFE4F1FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isMenunggu ? Colors.red.shade200 : Colors.blue.shade200),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isMenunggu ? const Color(0xFFD30000) : const Color(0xFF1976D2),
          )),
    );
  }

  IconData _ikonJenis(JenisKeadaan jenis) {
    switch (jenis) {
      case JenisKeadaan.kebakaran:   return Icons.local_fire_department;
      case JenisKeadaan.pencurian:   return Icons.person_off_outlined;
      case JenisKeadaan.hewanLiar:   return Icons.pets;
      case JenisKeadaan.bencanaAlam: return Icons.thunderstorm;
      case JenisKeadaan.lainnya:     return Icons.warning_amber_rounded;
    }
  }

  String _formatTanggal(DateTime dt) {
    const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const hari  = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return '${bulan[dt.month]} ${dt.day}, ${dt.year}, ${hari[dt.weekday % 7]}';
  }
}