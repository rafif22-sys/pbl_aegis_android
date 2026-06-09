// features/petugas/screens/widgets/sos_bantuan_warga_toggle.dart
import 'package:flutter/material.dart';

/// Toggle YA / TIDAK untuk pilihan bantuan warga.
class SosBantuanWargaToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SosBantuanWargaToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildOption(label: 'TIDAK', isActive: !value, onTap: () => onChanged(false)),
          _buildOption(label: 'YA',    isActive: value,  onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}