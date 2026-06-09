import 'package:flutter/material.dart';
import '../../../../sos/models/sos_model.dart';

class SosDetailHeader extends StatelessWidget {
  final SosModel sos;
  final Color statusColor;

  const SosDetailHeader({
    super.key,
    required this.sos,
    required this.statusColor,
  });

  IconData get _jenisIcon {
    switch (sos.jenisKeadaan) {
      case JenisKeadaan.kebakaran:   return Icons.local_fire_department;
      case JenisKeadaan.pencurian:   return Icons.person_off;
      case JenisKeadaan.hewanLiar:   return Icons.pets;
      case JenisKeadaan.bencanaAlam: return Icons.thunderstorm;
      case JenisKeadaan.lainnya:     return Icons.warning_amber_rounded;
    }
  }

  bool get _isSelesai => sos.status == StatusSOS.selesai;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: const BorderRadius.only(
          topLeft:  Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_jenisIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sos.jenisKeadaan.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: SOS-${sos.id.toString().padLeft(6, '0')}',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white60, width: 1),
            ),
            child: Text(
              _isSelesai ? 'SELESAI' : 'MENUNGGU',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}