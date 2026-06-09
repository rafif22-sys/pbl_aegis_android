// features/petugas/screens/widgets/sos_category_grid.dart
import 'package:flutter/material.dart';

class SosCategoryGrid extends StatelessWidget {
  final String selected;
  final bool disabled;
  final ValueChanged<String> onSelect;

  const SosCategoryGrid({
    super.key,
    required this.selected,
    required this.disabled,
    required this.onSelect,
  });

  static const _categories = [
    ('KEBAKARAN',   Icons.local_fire_department_outlined),
    ('PENCURIAN',   Icons.person_off_outlined),
    ('HEWAN LIAR',  Icons.pets_outlined),
    ('BENCANA ALAM', Icons.thunderstorm),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildItem(_categories[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildItem(_categories[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildItem(_categories[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildItem(_categories[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildItem((String, IconData) category) {
    final (title, icon) = category;
    final isSelected = selected == title && !disabled;

    return GestureDetector(
      onTap: disabled ? null : () => onSelect(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D47A1) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}