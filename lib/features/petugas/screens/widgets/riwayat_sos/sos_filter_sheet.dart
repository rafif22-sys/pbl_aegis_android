import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../sos/providers/sos_provider.dart';

class SosDaftarHeader extends StatelessWidget {
  final VoidCallback onFilterTap;

  const SosDaftarHeader({super.key, required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<SosProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daftar SOS',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _filterLabel(provider.activeFilter),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.filter_list, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _filterLabel(String? filter) {
    if (filter == null)               return 'Semua';
    if (filter == 'menunggu bantuan') return 'Menunggu';
    return 'Selesai';
  }
}

// ── Bottom sheet filter ──────────────────────────────
void showSosFilterSheet(
  BuildContext context,
  SosProvider provider,
  void Function(SosProvider, String?) onChanged,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Filter Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _filterOption(context, provider, label: 'Semua',             value: null,               onChanged: onChanged),
            _filterOption(context, provider, label: 'Menunggu Bantuan',  value: 'menunggu bantuan', onChanged: onChanged),
            _filterOption(context, provider, label: 'Selesai',           value: 'selesai',          onChanged: onChanged),
          ],
        ),
      );
    },
  );
}

Widget _filterOption(
  BuildContext context,
  SosProvider provider, {
  required String label,
  required String? value,
  required void Function(SosProvider, String?) onChanged,
}) {
  final isActive = provider.activeFilter == value;
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      color: isActive ? const Color(0xFF0D47A1) : Colors.grey,
    ),
    title: Text(label),
    onTap: () => onChanged(provider, value),
  );
}