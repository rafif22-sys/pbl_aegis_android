import 'package:flutter/material.dart';

class SosPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const SosPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PageButton(
            icon: Icons.chevron_left,
            label: 'Sebelumnya',
            enabled: currentPage > 1,
            onTap: onPrev,
          ),
          Text('$currentPage / $totalPages',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          _PageButton(
            icon: Icons.chevron_right,
            label: 'Berikutnya',
            enabled: currentPage < totalPages,
            onTap: onNext,
            iconOnRight: true,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool iconOnRight;

  const _PageButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.iconOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color     = enabled ? const Color(0xFF0D47A1) : Colors.grey.shade300;
    final textColor = enabled ? Colors.white : Colors.grey.shade500;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [BoxShadow(
                  color: const Color(0xFF0D47A1).withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconOnRight
              ? [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(width: 4),
                  Icon(icon, size: 16, color: textColor),
                ]
              : [
                  Icon(icon, size: 16, color: textColor),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                ],
        ),
      ),
    );
  }
}