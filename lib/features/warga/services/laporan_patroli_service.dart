// lib/features/warga/services/laporan_patroli_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_client.dart';
import '../models/laporan_patroli_model.dart';

// Re-export model dari supervisor agar bisa dipakai di halaman warga
// (LaporanHarianDetail, DetailPetugas, dll sudah ada di supervisor)
// Warga menggunakan model yang SAMA karena struktur response identik.
// Import di halaman warga: package supervisor/models/laporan_model.dart

class LaporanPatroliService {
  // ── Riwayat (paginated) ────────────────────────────────────────────────────
  Future<List<LaporanPatroliModel>> getLaporanPatroli({
    required String token,
    String? tanggal,
  }) async {
    final queryParams = <String, String>{};
    if (tanggal != null) queryParams['tanggal'] = tanggal;

    final uri = Uri.parse('${ApiClient.baseUrl}/warga/laporan-patroli')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(
      uri,
      headers: ApiClient.headers(token: token),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List data = body['data']['data'];
      return data.map((e) => LaporanPatroliModel.fromJson(e)).toList();
    }

    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Gagal memuat laporan patroli',
    );
  }

  // ── Minggu Ini ─────────────────────────────────────────────────────────────
  Future<List<LaporanPatroliModel>> getLaporanMingguIni({
    required String token,
  }) async {
    final uri = Uri.parse(
        '${ApiClient.baseUrl}/warga/laporan-patroli/minggu-ini');

    final response = await http.get(
      uri,
      headers: ApiClient.headers(token: token),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List data = body['data'] as List;
      return data.map((e) => LaporanPatroliModel.fromJson(e)).toList();
    }

    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Gagal memuat laporan minggu ini',
    );
  }

  // ── Detail Harian ──────────────────────────────────────────────────────────
  /// Mengembalikan raw Map agar LaporanHarianWargaPage bisa parse sendiri
  /// menggunakan model yang sama dengan supervisor (LaporanHarianDetail).
  Future<Map<String, dynamic>> getLaporanHarian({
    required String token,
    required String tanggal,
  }) async {
    final uri = Uri.parse(
        '${ApiClient.baseUrl}/warga/laporan-patroli/harian/$tanggal');

    final response = await http.get(
      uri,
      headers: ApiClient.headers(token: token),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>;
    }

    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Gagal memuat detail laporan',
    );
  }
}