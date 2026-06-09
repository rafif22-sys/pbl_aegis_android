import 'package:flutter/material.dart';

class ProfilHeader extends StatelessWidget {
  final String nama;
  final String role;
  final String? fotoProfil;

  const ProfilHeader({
    super.key,
    required this.nama,
    required this.role,
    this.fotoProfil,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: Colors.orange.shade100,
          child: fotoProfil != null
              ? ClipOval(
                  child: Image.network(
                    fotoProfil!,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 45, color: Colors.orange),
                  ),
                )
              : const Icon(Icons.person, size: 45, color: Colors.orange),
        ),
        const SizedBox(height: 12),
        Text(
          nama,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.5)),
          ),
          child: Text(
            role.toUpperCase(),
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}
