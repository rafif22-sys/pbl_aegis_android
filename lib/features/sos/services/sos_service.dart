// features/sos/services/sos_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:android_aegis/core/services/api_client.dart';
import '../models/sos_model.dart';
import '../models/sos_request_model.dart';

class SosService {
  /// POST /api/sos — Kirim SOS baru
  /// Response: { success, message, data: sos + user{id,nama} }  → 201
  static Future<SosModel> kirimSOS({
    required String token,
    required SosRequestModel request,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/sos'),
      headers: ApiClient.headers(token: token),
      body: jsonEncode(request.toJson()),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Lempar exception jika API return success: false
    if (json['success'] != true) {
      throw Exception(json['message'] ?? 'Gagal mengirim SOS');
    }

    return SosModel.fromJson(json['data']);
  }

  /// PATCH /api/{role}/sos/{id} — Update status SOS (petugas / supervisor)
  /// Response: { success, message, data: sos + user{id,nama} }
  static Future<SosModel> updateSOS({
    required String token,
    required String role,   // 'petugas' atau 'supervisor'
    required int sosId,
    required SosUpdateRequestModel request,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiClient.baseUrl}/$role/sos/$sosId'),
      headers: ApiClient.headers(token: token),
      body: jsonEncode(request.toJson()),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['success'] != true) {
      throw Exception(json['message'] ?? 'Gagal memperbarui SOS');
    }

    return SosModel.fromJson(json['data']);
  }

  /// GET /api/sos/{id} — Detail satu SOS
  /// Response: { success, data: sos + user{id,nama} }
  static Future<SosModel> getSOS({
    required String token,
    required int sosId,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/sos/$sosId'),
      headers: ApiClient.headers(token: token),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['success'] != true) {
      throw Exception(json['message'] ?? 'Data SOS tidak ditemukan');
    }

    return SosModel.fromJson(json['data']);
  }

  /// GET /api/sos — List semua SOS (semua role)
  static Future<List<SosModel>> getListSOS({
    required String token,
    String? filterStatus,
  }) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/sos').replace(
      queryParameters: filterStatus != null ? {'status': filterStatus} : null,
    );

    final response = await http.get(uri, headers: ApiClient.headers(token: token));
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['success'] != true) {
      throw Exception(json['message'] ?? 'Gagal mengambil data SOS');
    }

    final List data = json['data'] as List;
    return data.map((e) => SosModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}