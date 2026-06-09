// features/petugas/screens/widgets/sos_gps_status.dart
import 'package:flutter/material.dart';

/// Menampilkan status GPS: loading / terdeteksi / gagal.
/// Semua state diterima via props — widget ini pure UI, tidak ada logika GPS.
class SosGpsStatus extends StatelessWidget {
  final bool isLoading;
  final bool isDetected;  // true jika posisi sudah tersedia
  final VoidCallback onRetry;

  const SosGpsStatus({
    super.key,
    required this.isLoading,
    required this.isDetected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildChip(
        color: Colors.orange,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
            ),
            SizedBox(width: 8),
            Text(
              'Mengambil lokasi GPS...',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      );
    }

    if (isDetected) {
      return _buildChip(
        color: Colors.green,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 6),
            Text(
              'Lokasi terdeteksi ✓',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Icon(Icons.refresh, size: 16, color: Colors.green.shade700),
            ),
          ],
        ),
      );
    }

    // Gagal
    return GestureDetector(
      onTap: onRetry,
      child: _buildChip(
        color: Colors.red,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 14, color: Colors.red.shade700),
            const SizedBox(width: 6),
            Text(
              'Lokasi gagal — Tap untuk coba lagi',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}