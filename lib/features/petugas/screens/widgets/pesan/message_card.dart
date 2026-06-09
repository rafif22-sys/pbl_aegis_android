import 'package:flutter/material.dart';
import '../../../models/pesan_model.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.index,
    required this.message,
    required this.onToggleFavorit,
  });

  final int index;
  final PesanModel message;
  final VoidCallback onToggleFavorit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris atas: nama + waktu + unread dot ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    message.sender,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade300,
                  ),
                ),
                if (message.isUnread) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // ── Isi pesan ──
            Text(
              message.content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 10),

            // ── Baris bawah: role badge (kiri) + bintang (kanan) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (message.roleLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: message.roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: message.roleColor.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      message.roleLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: message.roleColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                else
                  const SizedBox(),

                GestureDetector(
                  onTap: onToggleFavorit,
                  child: Icon(
                    message.isStarred ? Icons.star : Icons.star_border,
                    color: message.isStarred
                        ? Colors.yellow.shade700
                        : Colors.black54,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}