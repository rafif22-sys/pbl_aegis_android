import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_client.dart';
import '../models/pesan_model.dart'; 

class PesanProvider extends ChangeNotifier {
  List<PesanModel> _pesanList = [];
  List<PesanModel> get pesanList => _pesanList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  String _activeFetchFilter = ''; // Penjaga agar tab tidak tertukar (Race Condition)

  // 1. AMBIL DAFTAR PESAN
  Future<void> fetchPesan({required String token, String filter = 'semua'}) async {
    _activeFetchFilter = filter; 
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/pesan?filter=$filter'),
        headers: ApiClient.headers(token: token),
      );

      if (_activeFetchFilter == filter) {
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body['success'] == true) {
            final List data = body['data'] ?? [];
            _pesanList = data.map((e) => PesanModel.fromJson(e)).toList();
          }
        }
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (_activeFetchFilter == filter) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // 2. TOGGLE BINTANG FAVORIT
  Future<void> toggleFavorit({required String token, required int pesanId}) async {
    final index = _pesanList.indexWhere((p) => p.id == pesanId);
    if (index == -1) return;

    // Ubah UI seketika tanpa menunggu server (Optimistic Update)
    _pesanList[index] = _pesanList[index].copyWith(isStarred: !_pesanList[index].isStarred);
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/pesan/$pesanId/favorit'),
        headers: ApiClient.headers(token: token),
      );
      final body = jsonDecode(response.body);
      
      if (body['success'] != true) throw Exception();
    } catch (e) {
      // Jika gagal, kembalikan bintang ke semula
      if (index != -1) {
        _pesanList[index] = _pesanList[index].copyWith(isStarred: !_pesanList[index].isStarred);
        notifyListeners();
      }
    }
  }

  // 3. TANDAI SUDAH DIBACA (LOKAL)
  void markAsReadLocal(int id, String filter) {
    final index = _pesanList.indexWhere((p) => p.id == id);
    if (index != -1) {
      _pesanList[index] = _pesanList[index].copyWith(isUnread: false);
      decrementUnreadCount();
      notifyListeners();
    }
  }

  // 4. KIRIM PESAN BARU (KHUSUS SUPERVISOR)
  Future<bool> kirimPesan({required String token, required String isiPesan}) async {
    try {
      final Map<String, String> headerPesan = ApiClient.headers(token: token);
      headerPesan['Content-Type'] = 'application/json';

      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/supervisor/pesan'),
        headers: headerPesan,
        body: jsonEncode({'pesan': isiPesan}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 5. HITUNG JUMLAH NOTIFIKASI MERAH
  Future<void> fetchUnreadCount({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/pesan/unread-count'),
        headers: ApiClient.headers(token: token),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          _unreadCount = body['count'] ?? 0;
          notifyListeners();
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> markAllRead({required String token}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/pesan/mark-read'),
        headers: ApiClient.headers(token: token),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          _unreadCount = 0;
          notifyListeners();
        }
      }
    } catch (e) {
      // ignore
    }
  }

  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }
  
  void clearUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }
}
