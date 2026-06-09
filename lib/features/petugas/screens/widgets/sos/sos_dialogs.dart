// features/petugas/screens/widgets/sos_dialogs.dart
import 'package:flutter/material.dart';

/// Kumpulan dialog GPS — dipisah dari screen agar mudah ditest & dibaca.
class SosDialogs {
  static Future<bool?> showEnableGps(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Color(0xFFD30000)),
            SizedBox(width: 8),
            Text('GPS Tidak Aktif', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Fitur SOS membutuhkan lokasi GPS Anda untuk mengirim bantuan '
          'ke posisi yang tepat.\n\nAktifkan GPS sekarang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD30000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Aktifkan GPS',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog izin lokasi diblokir permanen.
  /// Return: true = buka app settings, false/null = nanti.
  static Future<bool?> showPermissionPermanentlyDenied(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Color(0xFFD30000)),
            SizedBox(width: 8),
            Text('Izin Lokasi Diblokir', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Izin lokasi diblokir secara permanen.\n\n'
          'Buka Pengaturan Aplikasi → Izin → Lokasi, lalu pilih "Izinkan".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Buka Pengaturan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}