import 'package:flutter/material.dart';

class PatroliStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;
  final IconData icon;

  const PatroliStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Icon(icon, size: 20, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
