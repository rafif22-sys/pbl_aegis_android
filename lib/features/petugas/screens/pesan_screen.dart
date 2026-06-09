import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/services/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/pesan_model.dart';
import '../providers/pesan_provider.dart';
import 'widgets/buku_tamu/top_bar_screen.dart';
import 'widgets/pesan/message_card.dart';
import 'widgets/pesan/message_filter_tab.dart';
import 'widgets/pesan/message_list.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  int _selectedFilterIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<PesanModel> _messages = [];

  static const _filterValues = ['semua', 'belum_dibaca', 'favorit'];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  String get _token =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _markRead() async {
    try {
      await http.post(
        Uri.parse('${ApiClient.baseUrl}/pesan/mark-read'),
        headers: ApiClient.headers(token: _token),
      );
    } catch (_) {}
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filter = _filterValues[_selectedFilterIndex];
      final uri = Uri.parse(
        '${ApiClient.baseUrl}/pesan',
      ).replace(queryParameters: {'filter': filter});

      final response = await http.get(
        uri,
        headers: ApiClient.headers(token: _token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Gagal mengambil pesan.');
      }

      final data = List<Map<String, dynamic>>.from(body['data'] ?? []);

      if (!mounted) return;
      setState(() {
        _messages = data.map(PesanModel.fromJson).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengambil pesan dari admin.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _markRead();
    if (mounted) context.read<PesanProvider>().clearUnreadCount();
    await _fetchMessages();
  }

  Future<void> _toggleFavorit(int index) async {
    final item = _messages[index];
    setState(() {
      _messages[index] = item.copyWith(isStarred: !item.isStarred);
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/pesan/${item.id}/favorit'),
        headers: ApiClient.headers(token: _token),
      );
      final body = jsonDecode(response.body);
      if (body['success'] != true) throw Exception();

      if (_selectedFilterIndex == 2 && body['favorited'] == false) {
        setState(() => _messages.removeAt(index));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages[index] = item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffDCEFFE),
      body: SafeArea(
        child: Column(
          children: [
            const TopBarScreen(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  MessageFilterTab(
                    index: 0,
                    label: 'Semua',
                    selectedIndex: _selectedFilterIndex,
                    onTap: () {
                      if (_selectedFilterIndex != 0) {
                        setState(() => _selectedFilterIndex = 0);
                        _fetchMessages();
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  MessageFilterTab(
                    index: 1,
                    label: 'Belum Dibaca',
                    selectedIndex: _selectedFilterIndex,
                    onTap: () {
                      if (_selectedFilterIndex != 1) {
                        setState(() => _selectedFilterIndex = 1);
                        _fetchMessages();
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  MessageFilterTab(
                    index: 2,
                    label: 'Favorit',
                    selectedIndex: _selectedFilterIndex,
                    onTap: () {
                      if (_selectedFilterIndex != 2) {
                        setState(() => _selectedFilterIndex = 2);
                        _fetchMessages();
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff093A9C)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchMessages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff093A9C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return MessageList(
      messages: _messages,
      selectedFilterIndex: _selectedFilterIndex,
      onRefresh: _onRefresh,
      onToggleFavorit: _toggleFavorit,
    );
  }
}
