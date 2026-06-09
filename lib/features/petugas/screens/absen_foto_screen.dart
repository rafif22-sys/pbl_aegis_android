import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';



class AbsenFotoScreen extends StatefulWidget {
  final String tipeAbsen; // 'Absen Masuk' | 'Absen Pulang'
  final String namaShift;
  final String jamMulai;
  final String posJaga;

  const AbsenFotoScreen({
    super.key,
    required this.tipeAbsen,
    required this.namaShift,
    required this.jamMulai,
    required this.posJaga,
  });

  @override
  State<AbsenFotoScreen> createState() => _AbsenFotoScreenState();
}

class _AbsenFotoScreenState extends State<AbsenFotoScreen> {
  // ── Warna ──────────────────────────────────────────────────────────────────
  static const Color _bgPage   = Color(0xFFDCEFFE);
  static const Color _blue     = Color(0xFF1565C0);
  static const Color _textDark = Color(0xFF0F2A44);
  static const Color _textGray = Color(0xFF94A3B8);
  static const Color _green    = Color(0xFF22C55E);

  static const String _logoUrl =
      'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/new_logo.png';

  // ── State ──────────────────────────────────────────────────────────────────
  CameraController? _ctrl;
  Future<void>?     _initFuture;
  File?             _foto;
  bool              _capturing  = false;
  bool              _kameraReady = false;
  String?           _kameraError;
  late String       _jamBuka;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _jamBuka = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _initKamera();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  // ── Init kamera depan ──────────────────────────────────────────────────────

  Future<void> _initKamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _kameraError = 'Kamera tidak tersedia.');
        return;
      }

      final kamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _ctrl = CameraController(kamera, ResolutionPreset.high, enableAudio: false);
      _initFuture = _ctrl!.initialize();
      await _initFuture;

      if (mounted) setState(() => _kameraReady = true);
    } catch (e) {
      if (mounted) setState(() => _kameraError = e.toString());
    }
  }

  // ── Aksi ───────────────────────────────────────────────────────────────────

  Future<void> _ambilFoto() async {
    if (_capturing || _ctrl == null || !_kameraReady) return;
    setState(() => _capturing = true);
    try {
      final foto = await _ctrl!.takePicture();
      if (mounted) setState(() { _foto = File(foto.path); _capturing = false; });
    } catch (e) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _ambilUlang() => setState(() => _foto = null);

  void _konfirmasi() {
    if (_foto == null) return;
    Navigator.pop(context, _foto);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get _isAbsenMasuk => widget.tipeAbsen == 'Absen Masuk';

  Color get _headerColor => _isAbsenMasuk ? _green : _blue;

  IconData get _headerIcon =>
      _isAbsenMasuk ? Icons.login_rounded : Icons.logout_rounded;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [
          _buildTopBar(topPadding),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderAbsen(),
                  const SizedBox(height: 20),
                  _buildCardFoto(),
                  const SizedBox(height: 16),
                  _buildInfoLokasi(),
                  const SizedBox(height: 20),
                  _buildTombolKonfirmasi(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(double topPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 10, left: 24, right: 24, bottom: 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            _logoUrl,
            height: 30, width: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.security, color: Colors.lightBlueAccent, size: 30),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'ADVANCED EMERGENCY & GUARD INFORMATION SYSTEM',
              style: TextStyle(
                color: Colors.white70, fontSize: 9,
                fontWeight: FontWeight.w600, letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header Absen ───────────────────────────────────────────────────────────

  Widget _buildHeaderAbsen() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _headerColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_headerIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.tipeAbsen,
                style: const TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _jamBuka,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card Foto ──────────────────────────────────────────────────────────────

  Widget _buildCardFoto() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          const Text(
            'Upload Foto',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14, color: _textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Pastikan wajah anda terlihat',
            style: TextStyle(fontSize: 12, color: _textGray),
          ),
          const SizedBox(height: 14),

          // Preview area
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 280, // tinggi tetap, overflow tersembunyi oleh ClipRRect
              child: _buildPreviewArea(),
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Ambil Foto / Ambil Ulang
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _capturing
                  ? null
                  : _foto != null
                      ? _ambilUlang
                      : _ambilFoto,
              icon: _capturing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: _blue, strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text(
                _capturing
                    ? 'Mengambil...'
                    : _foto != null
                        ? 'Ambil Ulang'
                        : 'Ambil Foto',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBDEFB),
                foregroundColor: _blue,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: _textGray,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    // Sudah ada foto — tampilkan preview normal
    if (_foto != null) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0), 
      child: Image.file(_foto!, fit: BoxFit.cover),
    );
  }

    // Error kamera
    if (_kameraError != null) {
      return Container(
        color: const Color(0xFFE2E8F0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 40, color: _textGray),
              const SizedBox(height: 8),
              Text(
                _kameraError!,
                style: const TextStyle(color: _textGray, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Kamera sedang init
    if (!_kameraReady) {
      return Container(
        color: const Color(0xFFE2E8F0),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _blue),
              SizedBox(height: 10),
              Text('Memuat kamera...',
                  style: TextStyle(color: _textGray, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            color: const Color(0xFFE2E8F0),
            child: const Center(child: CircularProgressIndicator(color: _blue)),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final previewRatio = _ctrl!.value.previewSize!.height /
                _ctrl!.value.previewSize!.width;
            final containerRatio = constraints.maxWidth / constraints.maxHeight;

            double scale = previewRatio / containerRatio;
            if (scale < 1) scale = 1 / scale;

            return Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(_ctrl!),
              ),
            );
          },
        );
      },
    );
  }
  // ── Info Lokasi ────────────────────────────────────────────────────────────

  Widget _buildInfoLokasi() {
    return Row(
      children: [
        const Icon(Icons.location_on_rounded,
            color: Color(0xFFDC2626), size: 20),
        const SizedBox(width: 6),
        Text(
          widget.posJaga,
          style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  // ── Tombol Konfirmasi ──────────────────────────────────────────────────────

  Widget _buildTombolKonfirmasi() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _foto != null ? _konfirmasi : null,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: const Text(
          'Konfirmasi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFBBDEFB),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}