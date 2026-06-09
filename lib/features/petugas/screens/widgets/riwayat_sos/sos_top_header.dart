import 'package:flutter/material.dart';

class SosTopHeader extends StatelessWidget {
  const SosTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/new_logo.png',
            height: 30,
            width: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.pets, color: Colors.lightBlueAccent, size: 40),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'ADVANCED EMERGENCY & GUARD INFORMATION SYSTEM',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}