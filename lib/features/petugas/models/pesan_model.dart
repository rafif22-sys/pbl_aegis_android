import 'package:flutter/material.dart';

class PesanModel {
  const PesanModel({
    required this.id,
    required this.sender,
    required this.time,
    required this.content,
    required this.isStarred,
    required this.isUnread,
    required this.role,
    this.hasLeftIndicator = false,
  });

  final int id;
  final String sender;
  final String time;
  final String content;
  final bool isStarred;
  final bool isUnread;
  final String role;
  final bool hasLeftIndicator;

  String get roleLabel => switch (role.toLowerCase()) {
    'admin' => 'Admin',
    'supervisor' => 'Supervisor',
    'system' => 'AEGIS',
    _ => '',
  };

  Color get roleColor => switch (role.toLowerCase()) {
    'admin' => const Color(0xFF093A9C),
    'supervisor' => const Color(0xFF7B3FA0),
    'system' => const Color(0xFF0F7B6C),
    _ => Colors.grey,
  };

  PesanModel copyWith({
    bool? isStarred,
    bool? isUnread, // <-- 1. Tambahkan parameter ini di sini
  }) => PesanModel(
    id: id,
    sender: sender,
    time: time,
    content: content,
    isStarred: isStarred ?? this.isStarred,
    isUnread: isUnread ?? this.isUnread, // <-- 2. Ubah baris ini juga
    role: role,
    hasLeftIndicator: hasLeftIndicator,
  );
  factory PesanModel.fromJson(Map<String, dynamic> json) {
    return PesanModel(
      id: json['id'] as int? ?? 0,
      sender: json['sender']?.toString() ?? 'Admin',
      time: json['time']?.toString() ?? '-',
      content: json['content']?.toString() ?? '-',
      isStarred: json['isStarred'] == true,
      isUnread: json['isUnread'] == true,
      role: json['role']?.toString() ?? '',
      hasLeftIndicator: json['hasLeftIndicator'] == true,
    );
  }
}
