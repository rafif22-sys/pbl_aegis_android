// features/petugas/screens/widgets/sos_lainnya_field.dart
import 'package:flutter/material.dart';

/// Checkbox "LAINNYA" + TextField deskripsi.
/// Border merah muncul jika [showError] true (sudah coba kirim tapi kosong).
class SosLainnyaField extends StatelessWidget {
  final bool isChecked;
  final bool showError;         // true = tampilkan border merah
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<bool> onChanged;

  const SosLainnyaField({
    super.key,
    required this.isChecked,
    required this.showError,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox row
        Row(
          children: [
            Checkbox(
              value: isChecked,
              activeColor: const Color(0xFF0D47A1),
              onChanged: (value) => onChanged(value ?? false),
            ),
            const Text(
              'LAINNYA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),

        // TextField deskripsi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: isChecked
                ? Border.all(
                    color: showError
                        ? Colors.red.shade400
                        : Colors.orange.shade400,
                    width: 1.8,
                  )
                : null,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: isChecked,
            maxLines: 2,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Misal: Gangguan kebisingan...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}