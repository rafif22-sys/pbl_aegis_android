import 'package:flutter/material.dart';

class TamuSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilter;
  final String? selectedDate;

  const TamuSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onFilter,
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Cari nama tamu...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black45),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (selectedDate != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onFilter,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
        ],
      ],
    );
  }
}
