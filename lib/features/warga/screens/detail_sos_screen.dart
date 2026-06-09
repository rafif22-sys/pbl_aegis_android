import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../sos/models/sos_model.dart';
import '../../petugas/screens/widgets/detail_sos/sos_detail_header.dart';
import '../../petugas/screens/widgets/detail_sos/sos_detail_map.dart';
import '../../petugas/screens/widgets/detail_sos/sos_detail_pengirim_card.dart';
import '../../petugas/screens/widgets/detail_sos/sos_detail_deskripsi_card.dart';

class DetailSosScreen extends StatefulWidget {
  final SosModel sos;
  const DetailSosScreen({super.key, required this.sos});

  @override
  State<DetailSosScreen> createState() => _DetailSosScreenState();
}

class _DetailSosScreenState extends State<DetailSosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  Color get _statusColor => widget.sos.status == StatusSOS.selesai
      ? const Color(0xFF1A3FA0)
      : const Color(0xFFD30000);

  IconData get _jenisIcon {
    switch (widget.sos.jenisKeadaan) {
      case JenisKeadaan.kebakaran:   return Icons.local_fire_department;
      case JenisKeadaan.pencurian:   return Icons.person_off;
      case JenisKeadaan.hewanLiar:   return Icons.pets;
      case JenisKeadaan.bencanaAlam: return Icons.thunderstorm;
      case JenisKeadaan.lainnya:     return Icons.warning_amber_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.82, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
    final isSelesai = widget.sos.status == StatusSOS.selesai;

    return Scaffold(
      backgroundColor: const Color(0xFFDCEFFE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.black87, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PESAN SOS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Header + Map menempel dalam satu Expanded
            Expanded(
              flex: isSelesai ? 3 : 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SosDetailHeader(
                      sos: widget.sos,
                      statusColor: _statusColor,
                    ),
                    Expanded(
                      child: SosDetailMap(
                        center:      LatLng(widget.sos.latitude, widget.sos.longitude),
                        statusColor: _statusColor,
                        jenisIcon:   _jenisIcon,
                        pulseAnim:   _pulseAnim,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Card area
            Expanded(
              flex: isSelesai ? 5 : 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    SosDetailPengirimCard(
                      sos:            widget.sos,
                      waktuFormatted: _formatWaktu(widget.sos.waktuKirim),
                    ),
                    const SizedBox(height: 12),
                    SosDetailDeskripsiCard(
                      sos:         widget.sos,
                      statusColor: _statusColor,
                    ),

                    if (isSelesai) ...[
                      const SizedBox(height: 12),
                      _KonfirmatorCard(sos: widget.sos),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card konfirmator (read-only, tanpa tombol) ─────────────────────────────
class _KonfirmatorCard extends StatelessWidget {
  final SosModel sos;
  const _KonfirmatorCard({required this.sos});

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
          // Baris atas — label selesai
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

          Container(height: 1, color: Colors.white.withOpacity(0.15)),

          // Info konfirmator
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
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3)),
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

          // Penanganan — hanya muncul jika ada isinya
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
}