// lib/features/auth/services/forgot_password_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:android_aegis/core/services/api_client.dart';

class ForgotPasswordService {
  /// STEP 1 — Kirim OTP
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final res = await http.post(
      Uri.parse('${ApiClient.baseUrl}/auth/forgot-password'),
      headers: ApiClient.headers(),
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// STEP 2 — Verifikasi OTP, dapat reset_token
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiClient.baseUrl}/auth/verify-otp'),
      headers: ApiClient.headers(),
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// STEP 3 — Reset password dengan reset_token
  static Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiClient.baseUrl}/auth/reset-password'),
      headers: ApiClient.headers(),
      body: jsonEncode({
        'reset_token':            resetToken,
        'password':               password,
        'password_confirmation':  passwordConfirmation,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}