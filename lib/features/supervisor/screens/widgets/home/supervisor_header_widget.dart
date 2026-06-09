import 'package:flutter/material.dart';

class SupervisorHeaderWidget extends StatelessWidget {
  final String namaSupervisor;

  const SupervisorHeaderWidget({super.key, required this.namaSupervisor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 55, bottom: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF142940),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Image.network(
            'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/aegis_full_logo.png',
            height: 160,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.lightBlueAccent),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, color: Colors.white54, size: 70);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Selamat Datang,',
            style: TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            namaSupervisor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          // Badge Role Supervisor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 13, color: Colors.amberAccent),
                SizedBox(width: 5),
                Text(
                  'Supervisor',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}