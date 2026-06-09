import 'package:flutter/material.dart';
import '../../../../sos/models/sos_model.dart';

class SosDetailPengirimCard extends StatelessWidget {
  final SosModel sos;
  final String waktuFormatted;

  const SosDetailPengirimCard({
    super.key,
    required this.sos,
    required this.waktuFormatted,
  });

  static const TextStyle _labelStyle = TextStyle(
    color: Colors.grey,
    fontSize: 9,
    letterSpacing: 2,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final pengirim = sos.user;
    final inisial  = (pengirim?.nama ?? '?')
        .trim()
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pengirim
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PENGIRIM', style: _labelStyle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFDDE8F8),
                      backgroundImage: pengirim?.fotoProfil != null
                          ? NetworkImage(pengirim!.fotoProfil!)
                          : null,
                      child: pengirim?.fotoProfil == null
                          ? Text(
                              inisial,
                              style: const TextStyle(
                                color: Color(0xFF1A3FA0),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      pengirim?.nama ?? 'Tidak diketahui',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider vertikal
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Waktu
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WAKTU', style: _labelStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    waktuFormatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}