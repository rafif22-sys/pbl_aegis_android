import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _token != null && _user != null;

  // ── Dipanggil AuthWrapper saat app dibuka ──────────────
  Future<void> checkAuthStatus() async {
    final cache = await AuthService.getLocalSession();

    if (cache.token == null || cache.user == null) {
      notifyListeners();
      return;
    }

    _token = cache.token;
    _user = cache.user;
    notifyListeners();

    _syncWithServer(cache.token!);
    _sendFcmToken(cache.token!);
  }

  Future<void> _syncWithServer(String token) async {
    try {
      final freshUser = await AuthService.getMe(token);
      _user = freshUser;

      // Simpan role terbaru ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', freshUser.role);

      notifyListeners();
    } on Exception catch (e) {
      if (e.toString().contains('unauthorized')) {
        await _forceLogout();
      }
    }
  }

  // ── Login normal ───────────────────────────────────────
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.login(email, password);

      if (response['token'] != null && response['user'] != null) {
        _token = response['token'] as String;
        _user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

        // Simpan role ke SharedPreferences setelah login berhasil
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', _user!.role);

        await AuthService.saveSession(_token!, _user!);
        _sendFcmToken(_token!);

      } else {
        _errorMessage =
            (response['message'] as String?) ?? 'Login gagal, coba lagi.';
      }
    } on SocketException {
      _errorMessage = 'Tidak ada koneksi internet.';
    } on TimeoutException {
      _errorMessage = 'Server tidak merespons.';
    } catch (e) {
      _errorMessage = 'Tidak dapat terhubung ke server.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Kirim FCM token ke Laravel ─────────────────────────
  Future<void> _sendFcmToken(String authToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      await AuthService.saveFcmToken(authToken, fcmToken);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        AuthService.saveFcmToken(authToken, newToken);
      });

    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  // ── Logout normal ──────────────────────────────────────
  Future<void> logout() async {
    final token = _token;
    _clearState();
    notifyListeners();
    if (token != null) await AuthService.logout(token);
  }

  // ── Paksa logout karena 401 ────────────────────────────
  Future<void> _forceLogout() async {
    await AuthService.clearSession();
    _clearState();
    notifyListeners();
  }

  void _clearState() {
    _token        = null;
    _user         = null;
    _errorMessage = null;

    // Hapus role dari SharedPreferences saat logout
    SharedPreferences.getInstance().then((p) => p.remove('user_role'));
  }
}
