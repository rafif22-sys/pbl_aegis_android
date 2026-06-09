import 'package:flutter/material.dart';

class TopBarScreen extends StatelessWidget {
  const TopBarScreen({super.key});

  static const String logoUrl =
      'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/new_logo.png';

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top; // ambil tinggi status bar / notch

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 10, // konten turun sejauh status bar + 10px
        left: 24,
        right: 24,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // LOGO
          Image.network(
            logoUrl,
            height: 30,
            width: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) {
              return const Icon(
                Icons.security,
                color: Colors.lightBlueAccent,
                size: 40,
              );
            },
          ),

          const SizedBox(width: 10),

          // TEXT
          const Flexible(
            child: Text(
              'ADVANCED EMERGENCY & GUARD INFORMATION SYSTEM',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}