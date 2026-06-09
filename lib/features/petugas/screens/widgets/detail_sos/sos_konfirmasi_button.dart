import 'package:flutter/material.dart';
import '../../../../sos/models/sos_model.dart';

class SosKonfirmasiButton extends StatelessWidget {
  final SosModel sos;
  final bool isLoading;
  final VoidCallback onKonfirmasi;

  const SosKonfirmasiButton({
    super.key,
    required this.sos,
    required this.isLoading,
    required this.onKonfirmasi,
  });

  bool get _isSelesai => sos.status == StatusSOS.selesai;

  String _formatWaktu(String raw) {
    try {
      final dt    = DateTime.parse(raw).toLocal();
      const bulan = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei',
        'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${bulan[dt.month]}, '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSelesai) return _buildSelesai();
    return _buildTombol();
  }

  Widget _buildSelesai() {
    final konfirmator     = sos.konfirmator;
    final namaKonfirmator = konfirmator?.nama ?? 'Petugas';
    final fotoKonfirmator = konfirmator?.fotoProfil;
    final waktuKonfirmasi = sos.waktuKonfirmasi != null
        ? _formatWaktu(sos.waktuKonfirmasi!)
        : '-';
    final inisial = namaKonfirmator
        .trim()
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A3FA0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Baris atas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1A3FA0),
              borderRadius: BorderRadius.only(
                topLeft:  Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'SELESAI DITANGANI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: Colors.white.withOpacity(0.15)),

          // Baris bawah: info konfirmator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: fotoKonfirmator != null
                      ? NetworkImage(fotoKonfirmator)
                      : null,
                  child: fotoKonfirmator == null
                      ? Text(
                          inisial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaKonfirmator.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 11, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text(
                            waktuKonfirmasi,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'DIKONFIRMASI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (sos.penanganan != null && sos.penanganan!.isNotEmpty) ...[
            Container(height: 1, color: Colors.white.withOpacity(0.15)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined,
                          size: 13, color: Colors.white60),
                      SizedBox(width: 6),
                      Text(
                        'PENANGANAN',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sos.penanganan!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTombol() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onKonfirmasi,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3FA0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'KONFIRMASI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }
}