import 'package:flutter/material.dart';

class SosEmptyState extends StatelessWidget {
  const SosEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.black26),
            SizedBox(height: 12),
            Text('Belum ada data SOS.',
                style: TextStyle(color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

class SosErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SosErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}