import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/services/api_client.dart';
import '../models/absensi_model.dart';

class AbsensiRepository {
  static String get _base => ApiClient.baseUrl;

  // ── GET jadwal absensi hari ini ──────────────────────────────────────────
  Future<AbsensiModel?> getHariIni({required String token}) async {
    final res = await http.get(
      Uri.parse('$_base/petugas/absensi/hari-ini'),
      headers: ApiClient.headers(token: token),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat data absensi (${res.statusCode})');
    }

    final body = jsonDecode(res.body);
    if (body['status'] == false || body['data'] == null) return null;
    return AbsensiModel.fromJson(body['data']);
  }

  // ── POST absen masuk ─────────────────────────────────────────────────────
  Future<AbsensiModel> absenMasuk({
    required String token,
    required File foto,
    required double latitude,
    required double longitude,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/petugas/absensi/masuk'),
    )
      ..headers.addAll(ApiClient.headersMultipart(token: token))
      ..fields['latitude']  = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..files.add(await http.MultipartFile.fromPath('foto', foto.path));

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    final body     = jsonDecode(res.body);

    if (res.statusCode != 200 || body['status'] == false) {
      throw Exception(body['message'] ?? 'Gagal absen masuk');
    }
    return AbsensiModel.fromJson(body['data']);
  }

  // ── POST absen pulang ────────────────────────────────────────────────────
  Future<AbsensiModel> absenPulang({
    required String token,
    required File foto,
    required double latitude,
    required double longitude,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/petugas/absensi/pulang'),
    )
      ..headers.addAll(ApiClient.headersMultipart(token: token))
      ..fields['latitude']  = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..files.add(await http.MultipartFile.fromPath('foto', foto.path));

    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    final body     = jsonDecode(res.body);

    if (res.statusCode != 200 || body['status'] == false) {
      throw Exception(body['message'] ?? 'Gagal absen pulang');
    }
    return AbsensiModel.fromJson(body['data']);
  }
}