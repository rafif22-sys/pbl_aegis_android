import 'package:flutter/material.dart';
import '../../../models/tamu_model.dart';
import 'helpers.dart';

class DetailTamuDialog extends StatefulWidget {
  const DetailTamuDialog({
    super.key,
    required this.tamu,
    this.onKeluar,
  });

  final TamuModel tamu;

  /// Null = tamu sudah keluar, tombol akan di-disable.
  /// Non-null = callback yang dipanggil saat tombol "Tamu Keluar" ditekan.
  final Future<bool> Function()? onKeluar;

  @override
  State<DetailTamuDialog> createState() => _DetailTamuDialogState();
}

class _DetailTamuDialogState extends State<DetailTamuDialog> {
  bool _isProcessing = false;

  Future<void> _handleKeluar() async {
    if (_isProcessing || widget.onKeluar == null) return;
    setState(() => _isProcessing = true);
    try {
      final berhasil = await widget.onKeluar!();
      if (!mounted) return;
      Navigator.pop(context, berhasil);
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tamu = widget.tamu;
    final fotoUrl = resolveFotoUrl(tamu.fotoTamu);

    final bool sudahKeluar = tamu.status == 'keluar';
    final bool isEstimasi = !sudahKeluar && tamu.waktuKeluar != null;

    final status = sudahKeluar ? 'Keluar' : 'Masuk';
    final statusBgColor =
        sudahKeluar ? const Color(0xFFC8E6C9) : const Color(0xFFBBDEFB);
    final statusTextColor =
        sudahKeluar ? const Color(0xFF2EB24F) : const Color(0xFF034DC0);

    final masuk = tamu.waktuMasuk.toLocal();
    final waktuMasukStr = formatDateTime(masuk);

    final String waktuKeluarStr = sudahKeluar && tamu.waktuKeluar != null
        ? formatDateTime(tamu.waktuKeluar!.toLocal())
        : '-';

    final String? estimasiStr =
        isEstimasi ? formatDateTime(tamu.waktuKeluar!.toLocal()) : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ──
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Informasi Tamu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: _isProcessing ? null : () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE85C5C),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Foto + Info ──
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Foto tamu
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 150,
                      child: fotoUrl == null
                          ? Container(
                              color: const Color(0xFFF0F0F0),
                              child: const Center(
                                child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 44,
                                    color: Colors.grey),
                              ),
                            )
                          : Image.network(
                              fotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF0F0F0),
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      size: 44, color: Colors.grey),
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Info tamu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge status
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: statusTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _infoRow(Icons.person, tamu.nama),
                        const SizedBox(height: 6),
                        _infoRow(Icons.description_outlined, tamu.keperluan),
                        const SizedBox(height: 6),
                        _infoRow(Icons.home_outlined, tamu.alamat),
                        const SizedBox(height: 6),
                        _infoRow(Icons.badge_outlined, tamu.namaUser),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 8),

            // ── Waktu + Tombol ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _timelineItem(
                        label: 'Masuk',
                        value: waktuMasukStr,
                        color: const Color(0xFF2EB24F),
                      ),
                      const SizedBox(height: 6),

                      // Estimasi keluar (kuning) — status masih 'masuk'
                      if (estimasiStr != null) ...[
                        _timelineItem(
                          label: 'Estimasi Keluar',
                          value: estimasiStr,
                          color: const Color(0xFFFF8F00),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Waktu keluar aktual (merah) — status 'keluar'
                      if (sudahKeluar)
                        _timelineItem(
                          label: 'Keluar',
                          value: waktuKeluarStr,
                          color: const Color(0xFFE53935),
                        ),
                    ],
                  ),
                ),

                if (widget.onKeluar != null) ...[
                  const SizedBox(width: 10),

                  // Tombol Tamu Keluar
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed:
                          (sudahKeluar || _isProcessing) ? null : _handleKeluar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EB24F),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFBFE8C8),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Tamu Keluar',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _timelineItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.access_time, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}