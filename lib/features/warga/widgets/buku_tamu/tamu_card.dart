import 'package:flutter/material.dart';
import '../../models/buku_tamu_model.dart';

class TamuCard extends StatelessWidget {
  final BukuTamuModel tamu;

  const TamuCard({super.key, required this.tamu});

  @override
  Widget build(BuildContext context) {
    final isMasuk = tamu.status.toLowerCase() == 'masuk';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${tamu.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tamu.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.login, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      tamu.waktuMasuk,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    if (tamu.waktuKeluar != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.logout, size: 14, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        tamu.waktuKeluar!,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isMasuk
                  ? const Color(0xFFe8f5e9)
                  : const Color(0xFFffebee),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tamu.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isMasuk
                    ? const Color(0xFF2e7d32)
                    : const Color(0xFFc62828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
