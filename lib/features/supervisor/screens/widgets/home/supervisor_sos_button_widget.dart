import 'package:flutter/material.dart';
// TODO: Sesuaikan import ini ke lokasi halaman form SOS milikmu
import '../../supervisor_sos_form_screen.dart'; 

class SupervisorSOSButtonWidget extends StatelessWidget {
  const SupervisorSOSButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // MEMBUKA FORM SOS BARU YANG SUDAH TERHUBUNG GPS
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SupervisorSOSFormScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF09FA6).withOpacity(0.5),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFED4D5C), Color(0xFFF27855)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'KIRIM SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(Icons.shield_outlined, size: 34, color: Colors.white),
                  const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}