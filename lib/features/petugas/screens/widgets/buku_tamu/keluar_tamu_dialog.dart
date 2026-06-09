import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../models/tamu_model.dart';
import '../../../providers/tamu_provider.dart';

class KeluarTamuDialog extends StatefulWidget {
  const KeluarTamuDialog({super.key, required this.tamu});

  final TamuModel tamu;

  @override
  State<KeluarTamuDialog> createState() => _KeluarTamuDialogState();
}

class _KeluarTamuDialogState extends State<KeluarTamuDialog> {
  late final TextEditingController _jamCtrl;
  late final TextEditingController _menitCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill dengan estimasi keluar jika ada, fallback ke jam sekarang
    final waktu =
        (widget.tamu.status == 'masuk' && widget.tamu.waktuKeluar != null)
            ? widget.tamu.waktuKeluar!
            : DateTime.now();

    _jamCtrl = TextEditingController(
      text: waktu.hour.toString().padLeft(2, '0'),
    );
    _menitCtrl = TextEditingController(
      text: waktu.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _jamCtrl.dispose();
    _menitCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpanKeluar() async {
    if (_isSaving) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) {
      _showMessage('Sesi login tidak ditemukan.');
      return;
    }

    final jam = int.tryParse(_jamCtrl.text.trim());
    final menit = int.tryParse(_menitCtrl.text.trim());

    if (jam == null ||
        menit == null ||
        jam < 0 ||
        jam > 23 ||
        menit < 0 ||
        menit > 59) {
      _showMessage('Jam keluar tidak valid.');
      return;
    }

    final now = DateTime.now();
    final waktuKeluar = DateTime(now.year, now.month, now.day, jam, menit);

    setState(() => _isSaving = true);
    try {
      final result = await context.read<TamuProvider>().markKeluar(
            token: token,
            tamuId: widget.tamu.id,
            waktuKeluar: waktuKeluar,
          );

      if (!result.success) throw Exception(result.message);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.tamu.nama,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            widget.tamu.keperluan,
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 18),

          // ── Input Jam Keluar ──
          const Text(
            'Jam Keluar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _timeField(controller: _jamCtrl, hint: 'HH')),
              const SizedBox(width: 10),
              const Text(
                ':',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Expanded(child: _timeField(controller: _menitCtrl, hint: 'MM')),
            ],
          ),

          const SizedBox(height: 20),

          // ── Tombol Simpan ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _simpanKeluar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2EB24F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(_isSaving ? 'Menyimpan...' : 'Tamu Keluar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 2,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}