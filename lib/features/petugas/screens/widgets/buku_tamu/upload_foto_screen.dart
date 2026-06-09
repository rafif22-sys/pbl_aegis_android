import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class UploadFotoScreen extends StatefulWidget {
  const UploadFotoScreen({super.key, this.onChanged});

  final ValueChanged<XFile?>? onChanged;

  @override
  State<UploadFotoScreen> createState() => _UploadFotoScreenState();
}

class _UploadFotoScreenState extends State<UploadFotoScreen> {
  XFile? _imageFile;

  Future<void> _openCameraDialog() async {
    final photo = await showDialog<XFile>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CameraCaptureDialog(),
    );

    if (!mounted || photo == null) return;
    setState(() => _imageFile = photo);
    widget.onChanged?.call(photo);
  }

  @override
  Widget build(BuildContext context) {
    if (_imageFile == null) {
      return ElevatedButton.icon(
        onPressed: _openCameraDialog,
        icon: const Icon(Icons.camera_alt_rounded, size: 18),
        label: const Text('Ambil Foto'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF034DC0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: _CapturedPhotoPreview(imageFile: _imageFile!),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _openCameraDialog,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Foto Ulang'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF034DC0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ],
    );
  }
}

class _CapturedPhotoPreview extends StatelessWidget {
  const _CapturedPhotoPreview({required this.imageFile});

  final XFile imageFile;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Image.file(File(imageFile.path), fit: BoxFit.cover);
    }

    return FutureBuilder(
      future: imageFile.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF034DC0)),
          );
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}

class _CameraCaptureDialog extends StatefulWidget {
  const _CameraCaptureDialog();

  @override
  State<_CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<_CameraCaptureDialog> {
  CameraController? _cameraController;
  String? _errorMessage;
  bool _isInitializing = true;
  bool _isTakingPicture = false;

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
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Gagal membuka kamera: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Kamera tidak bisa dibuka. Cek izin kamera perangkat.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

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
    // Hitung tinggi layar agar dialog menyesuaikan
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: screenHeight * 0.85, // ← beri ruang cukup untuk tombol
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Preview kamera — flex agar tombol tidak tertimpa
            Flexible(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  color: Colors.black,
                  child: _buildCameraContent(),
                ),
              ),
            ),

            // Tombol — selalu tampil di bawah, tidak menimpa preview
            Container(
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
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                        backgroundColor: const Color(0xFF034DC0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Ambil Foto Tamu',
              style: TextStyle(
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
        width: controller.value.previewSize?.height ?? 520,
        height: controller.value.previewSize?.width ?? 390,
        child: CameraPreview(controller),
      ),
    );
  }
}