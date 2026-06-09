import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../models/tamu_model.dart';
import '../models/tamu_request_model.dart';

class TamuService {
  static Future<List<TamuModel>> getListTamu({required String token}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/tamu'),
      headers: ApiClient.headers(token: token),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] == false) {
      throw Exception(body['message'] ?? 'Gagal mengambil data tamu.');
    }

    final data = (body['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TamuModel.fromJson)
        .toList();

    return data;
  }

  static Future<TamuModel> store({
    required String token,
    required TamuRequestModel requestModel,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/tamu'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields.addAll(requestModel.toFields());

    final bytes = await requestModel.fotoTamu.readAsBytes();
    final filename = requestModel.fotoTamu.name.isNotEmpty
        ? requestModel.fotoTamu.name
        : 'foto_tamu_${DateTime.now().millisecondsSinceEpoch}.jpg';

    request.files.add(
      http.MultipartFile.fromBytes('foto_tamu', bytes, filename: filename),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['message'] ?? 'Gagal menyimpan data tamu.');
    }

    return TamuModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<TamuModel> update({
    required String token,
    required int tamuId,
    required TamuUpdateRequestModel requestModel,
  }) async {
    final attempts = <Future<http.Response> Function()>[
      () => http.patch(
        Uri.parse('${ApiClient.baseUrl}/tamu/$tamuId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestModel.toFields(),
      ),
      () => http.post(
        Uri.parse('${ApiClient.baseUrl}/tamu/$tamuId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {'_method': 'PATCH', ...requestModel.toFields()},
      ),
      () => http.put(
        Uri.parse('${ApiClient.baseUrl}/tamu/$tamuId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestModel.toFields(),
      ),
    ];

    Object? lastError;

    for (final request in attempts) {
      final response = await request();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return TamuModel.fromJson(body['data'] as Map<String, dynamic>);
      }

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            lastError = decoded['message'];
          } else {
            lastError = response.body;
          }
        } catch (_) {
          lastError = response.body;
        }
      } else {
        lastError = 'HTTP ${response.statusCode}';
      }
    }

    throw Exception(
      lastError is String && lastError.trim().isNotEmpty
          ? lastError
          : 'Gagal mengubah status tamu.',
    );
  }
}
