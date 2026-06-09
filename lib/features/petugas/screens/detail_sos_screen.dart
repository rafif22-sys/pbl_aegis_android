import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../features/sos/models/sos_model.dart';
import '../../../features/sos/providers/sos_provider.dart';
import 'widgets/detail_sos/sos_detail_header.dart';
import 'widgets/detail_sos/sos_detail_map.dart';
import 'widgets/detail_sos/sos_detail_pengirim_card.dart';
import 'widgets/detail_sos/sos_detail_deskripsi_card.dart';
import 'widgets/detail_sos/sos_konfirmasi_button.dart';

class DetailSosScreen extends StatefulWidget {
  final SosModel sos;
  const DetailSosScreen({super.key, required this.sos});

  @override
  State<DetailSosScreen> createState() => _DetailSosScreenState();
}

class _DetailSosScreenState extends State<DetailSosScreen>
    with SingleTickerProviderStateMixin {
  late SosModel _sos;
  bool _isKonfirmasi = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  Color get _statusColor => _sos.status == StatusSOS.selesai
      ? const Color(0xFF1A3FA0)
      : const Color(0xFFD30000);

  IconData get _jenisIcon {
    switch (_sos.jenisKeadaan) {
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
    _sos = widget.sos;
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

  
  Future<String?> _showFormPenanganan() async {
    String inputText = '';

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Deskripsi Penanganan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tuliskan penanganan yang sudah dilakukan:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                TextField(
                  maxLines: 4,
                  maxLength: 1000,
                  onChanged: (val) => inputText = val.trim(),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Sudah memanggil pemadam kebakaran...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1A3FA0)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3FA0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (inputText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Penanganan tidak boleh kosong.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, inputText);
                },
                child: const Text(
                  'Konfirmasi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );

    return result;
  }

  // Ganti _handleKonfirmasi() yang lama dengan ini
  Future<void> _handleKonfirmasi() async {
    // Tampilkan form penanganan dulu
    final penanganan = await _showFormPenanganan();
    if (penanganan == null || !mounted) return; // user tekan batal

    setState(() => _isKonfirmasi = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('GPS tidak aktif.', isError: true);
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showSnack('Izin lokasi ditolak.', isError: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final auth   = context.read<AuthProvider>();
      final result = await context.read<SosProvider>().konfirmasiSOS(
        token:            auth.token!,
        role:             auth.user!.role,
        sosId:            _sos.id,
        latitudePetugas:  position.latitude,
        longitudePetugas: position.longitude,
        penanganan:       penanganan, // ✅ kirim penanganan
      );

      if (!mounted) return;
      if (result.success) {
        setState(() => _sos = result.data!);
        _showSnack('SOS berhasil dikonfirmasi!');
      } else {
        _showSnack(result.message, isError: true);
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isKonfirmasi = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor:
            isError ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFDCEFFE),  
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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

            // ── Konten ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    SosDetailHeader(sos: _sos, statusColor: _statusColor),
                    SosDetailMap(
                      center:      LatLng(_sos.latitude, _sos.longitude),
                      statusColor: _statusColor,
                      jenisIcon:   _jenisIcon,
                      pulseAnim:   _pulseAnim,
                    ),
                    const SizedBox(height: 16),
                    SosDetailPengirimCard(
                      sos:            _sos,
                      waktuFormatted: _formatWaktu(_sos.waktuKirim),
                    ),
                    const SizedBox(height: 12),
                    SosDetailDeskripsiCard(
                      sos:         _sos,
                      statusColor: _statusColor,
                    ),
                    const SizedBox(height: 12),
                    SosKonfirmasiButton(
                      sos:          _sos,
                      isLoading:    _isKonfirmasi,
                      onKonfirmasi: _handleKonfirmasi,
                    ),
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