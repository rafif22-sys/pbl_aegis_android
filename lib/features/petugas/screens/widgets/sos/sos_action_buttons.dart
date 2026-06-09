// features/petugas/screens/widgets/sos_action_buttons.dart
import 'package:flutter/material.dart';

/// Baris tombol Batal dan Kirim di bagian bawah form SOS.
class SosActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool isLoadingGps;
  final bool hasSelectedCategory;
  final VoidCallback onBatal;
  final VoidCallback onKirim;

  const SosActionButtons({
    super.key,
    required this.isLoading,
    required this.isLoadingGps,
    required this.hasSelectedCategory,
    required this.onBatal,
    required this.onKirim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Tombol Batal ──────────────────────────────────────
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onBatal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD30000),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'BATAL',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ── Tombol Kirim ──────────────────────────────────────
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: hasSelectedCategory
                  ? [
                      BoxShadow(
                        color: const Color(0xFF28A745).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: (isLoading || isLoadingGps) ? null : onKirim,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSelectedCategory
                    ? const Color(0xFF28A745)
                    : Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'KIRIM',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasSelectedCategory
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.send,
                          color: hasSelectedCategory
                              ? Colors.white
                              : Colors.grey.shade500,
                          size: 16,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}