import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../sos/providers/sos_provider.dart';

class SosSummaryCards extends StatelessWidget {
  const SosSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SosProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.state == SosListState.loading;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _SosStatCard(
                  label:       'Total Pesan SOS',
                  value:       isLoading ? '-' : '${provider.totalSos}',
                  valueColor:  const Color(0xFF0F172A),
                  borderColor: const Color(0xFF0D47A1),
                  icon:        Icons.bar_chart,
                  iconColor:   Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SosStatCard(
                  label:       'SOS Dikonfirmasi',
                  value:       isLoading ? '-' : '${provider.totalSelesai}',
                  valueColor:  Colors.green,
                  borderColor: Colors.green,
                  icon:        Icons.check_circle_outline,
                  iconColor:   Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SosStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;

  const _SosStatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: valueColor)),
              Icon(icon, color: iconColor),
            ],
          ),
        ],
      ),
    );
  }
}