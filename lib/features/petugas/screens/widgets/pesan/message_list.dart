import 'package:flutter/material.dart';
import '../../../models/pesan_model.dart';
import 'message_card.dart';

class MessageList extends StatelessWidget {
  const MessageList({
    super.key,
    required this.messages,
    required this.selectedFilterIndex,
    required this.onRefresh,
    required this.onToggleFavorit,
  });

  final List<PesanModel> messages;
  final int selectedFilterIndex;
  final Future<void> Function() onRefresh;
  final void Function(int index) onToggleFavorit;

  String get _emptyText => switch (selectedFilterIndex) {
    1 => 'Tidak ada pesan belum dibaca.',
    2 => 'Belum ada pesan favorit.',
    _ => 'Belum ada informasi.',
  };

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 160),
            Center(
              child: Text(
                _emptyText,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: messages.length + 1,
        itemBuilder: (context, i) {
          if (i == messages.length) return const SizedBox(height: 100);
          return MessageCard(
            index: i,
            message: messages[i],
            onToggleFavorit: () => onToggleFavorit(i),
          );
        },
      ),
    );
  }
}