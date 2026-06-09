import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_client.dart';
import '../models/jadwal_model.dart';

class JadwalRepository {
  static String get _base => ApiClient.baseUrl;

  Future<Map<String, dynamic>> getJadwalMingguan({
    required String token,
    String? tanggal,
  }) async {
    final params = tanggal != null ? {'tanggal': tanggal} : null;
    final uri = Uri.parse('$_base/petugas/jadwal/mingguan')
        .replace(queryParameters: params);

    final res = await http.get(uri,
        headers: ApiClient.headers(token: token));

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat jadwal (${res.statusCode})');
    }

    final body = jsonDecode(res.body);
    final List raw = body['data'] ?? [];

    return {
      'minggu_mulai': body['minggu_mulai'],
      'minggu_akhir': body['minggu_akhir'],
      'data': raw.map((e) => JadwalModel.fromJson(e)).toList(),
    };
  }

  Future<List<JadwalModel>> getRiwayatAbsensi({
    required String token,
    String? tanggal,
    String? status,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (tanggal != null) params['tanggal'] = tanggal;
    if (status != null) params['status']   = status.toLowerCase();

    final uri = Uri.parse('$_base/petugas/jadwal/absensi')
        .replace(queryParameters: params);

    final res = await http.get(uri,
        headers: ApiClient.headers(token: token));

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat riwayat (${res.statusCode})');
    }

    final body  = jsonDecode(res.body);
    final List raw = body['data']?['data'] ?? [];
    return raw.map((e) => JadwalModel.fromJson(e)).toList();
  }
}