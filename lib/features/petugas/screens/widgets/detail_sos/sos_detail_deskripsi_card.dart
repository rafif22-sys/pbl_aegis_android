import 'package:flutter/material.dart';
import '../../../../sos/models/sos_model.dart';


class SosDetailDeskripsiCard extends StatelessWidget {
  final SosModel sos;
  final Color statusColor;

  const SosDetailDeskripsiCard({
    super.key,
    required this.sos,
    required this.statusColor,
  });

  static const TextStyle _labelStyle = TextStyle(
    color: Colors.grey,
    fontSize: 9,
    letterSpacing: 2,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DESKRIPSI KEJADIAN', style: _labelStyle),
          const SizedBox(height: 10),
          _buildHighlight(),
        ],
      ),
    );
  }

  Widget _buildHighlight() {
    final keywords = [
      sos.jenisKeadaan.label.toLowerCase(),
      'satpam',
      'warga',
      'segera',
    ];

    final words = sos.deskripsi.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word  = words[i];
      final clean = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final isKey = keywords.any((k) => clean == k.toLowerCase());

      spans.add(TextSpan(
        text: i < words.length - 1 ? '$word ' : word,
        style: TextStyle(
          color:      isKey ? statusColor : Colors.black87,
          fontWeight: isKey ? FontWeight.bold : FontWeight.normal,
          fontStyle:  FontStyle.italic,
          fontSize:   13,
          height:     1.7,
        ),
      ));
    }

    return Text.rich(TextSpan(children: [
      const TextSpan(
        text: '"',
        style: TextStyle(
            fontStyle: FontStyle.italic, fontSize: 13, color: Colors.black45),
      ),
      ...spans,
      const TextSpan(
        text: '"',
        style: TextStyle(
            fontStyle: FontStyle.italic, fontSize: 13, color: Colors.black45),
      ),
    ]));
  }
}