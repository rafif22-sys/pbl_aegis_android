// lib/features/petugas/screens/widgets/patroli/camera_capture_widget.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class CameraCaptureWidget {
  /// Buka dialog kamera patroli.
  /// Kembalikan XFile jika foto berhasil diambil, null jika dibatalkan.
  static Future<XFile?> show(
    BuildContext context, {
    String title = 'Foto Checkpoint',
  }) {
    return showDialog<XFile>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CameraCaptureDialog(title: title),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Dialog kamera
// ─────────────────────────────────────────────────────────
class _CameraCaptureDialog extends StatefulWidget {
  final String title;
  const _CameraCaptureDialog({required this.title});

  @override
  State<_CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<_CameraCaptureDialog> {
  CameraController? _cameraController;
  String?           _errorMessage;
  bool              _isInitializing  = true;
  bool              _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'Tidak ada kamera yang tersedia.');
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializing   = false;
      });
    } catch (e) {
      debugPrint('Gagal membuka kamera: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage   = 'Kamera tidak bisa dibuka. Cek izin kamera perangkat.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) return;

    setState(() => _isTakingPicture = true);
    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, photo);
    } catch (e) {
      debugPrint('Gagal mengambil foto: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto gagal diambil. Coba lagi.')),
      );
      setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:  520,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  color: Colors.black,
                  child: _buildCameraContent(),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF0F2A44),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Batal'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isTakingPicture ? null : _takePicture,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text(_isTakingPicture ? 'Memotret...' : 'Ambil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraContent() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Kamera belum siap.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width:  controller.value.previewSize?.height ?? 520,
        height: controller.value.previewSize?.width  ?? 390,
        child: CameraPreview(controller),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Preview foto yang sudah diambil
// ─────────────────────────────────────────────────────────
class PatroliCapturedPhotoPreview extends StatelessWidget {
  final XFile   imageFile;
  final double? width;
  final double? height;
  final BoxFit  fit;

  const PatroliCapturedPhotoPreview({
    super.key,
    required this.imageFile,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Image.file(
        File(imageFile.path),
        width:  width,
        height: height,
        fit:    fit,
      );
    }

    return FutureBuilder(
      future: imageFile.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1565C0)),
          );
        }
        return Image.memory(
          snapshot.data!,
          width:  width,
          height: height,
          fit:    fit,
        );
      },
    );
  }
}