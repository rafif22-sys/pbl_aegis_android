import 'package:flutter/material.dart';

class MessageFilterTab extends StatelessWidget {
  const MessageFilterTab({
    super.key,
    required this.index,
    required this.label,
    required this.selectedIndex,
    required this.onTap,
  });

  final int index;
  final String label;
  final int selectedIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff093A9C)
                : const Color(0xffD0E1F4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}