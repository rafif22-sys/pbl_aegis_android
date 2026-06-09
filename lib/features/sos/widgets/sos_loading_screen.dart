import 'package:flutter/material.dart';
import '../repositories/sos_repository.dart';
import '../../../features/petugas/screens/detail_sos_screen.dart';
import '../../../features/warga/screens/detail_sos_screen.dart' as warga; // ← tambah ini

class SosLoadingScreen extends StatefulWidget {
  final String sosId;
  final String token;
  final String role;
  final VoidCallback onDone;

  const SosLoadingScreen({
    super.key,
    required this.sosId,
    required this.token,
    required this.role,
    required this.onDone,
  });

  @override
  State<SosLoadingScreen> createState() => _SosLoadingScreenState();
}

class _SosLoadingScreenState extends State<SosLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _fetchAndNavigate();
  }

  Future<void> _fetchAndNavigate() async {
    try {
      final repo = SosRepository();
      final sos = await repo.getSOS(
        token: widget.token,
        sosId: int.parse(widget.sosId),
      );

      if (!mounted) return;

      final navigator = Navigator.of(context);
      widget.onDone();

      navigator.push(
        MaterialPageRoute(
          builder: (_) => widget.role == 'warga'
              ? warga.DetailSosScreen(sos: sos) // ← screen warga (tanpa konfirmasi)
              : DetailSosScreen(sos: sos),       // ← screen petugas/supervisor
        ),
      );

    } catch (e) {
      debugPrint('Fetch SOS gagal: $e');
      if (!mounted) return;
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF041221),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Membuka detail SOS...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}