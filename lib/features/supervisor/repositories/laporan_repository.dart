// lib/features/supervisor/repositories/laporan_repository.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_client.dart';
import '../models/laporan_model.dart';

class LaporanRepository {
  static String get _base => ApiClient.baseUrl;

  // ── Minggu Ini ─────────────────────────────────────────────────────────────
  /// Mengembalikan ringkasan 7 hari (Senin–Minggu berjalan).
  Future<Map<String, dynamic>> getLaporanMingguIni({
    required String token,
  }) async {
    final uri = Uri.parse('$_base/supervisor/laporan/minggu-ini');
    final res = await http.get(uri, headers: ApiClient.headers(token: token));

    _assertOk(res, 'laporan minggu ini');

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List raw = body['data'] as List;

    return {
      'minggu_mulai': body['minggu_mulai'] as String,
      'minggu_akhir': body['minggu_akhir'] as String,
      'data': raw
          .map((e) => LaporanHarianRingkasan.fromJson(e as Map<String, dynamic>))
          .toList(),
    };
  }

  // ── Riwayat (paginated) ────────────────────────────────────────────────────
  /// [tanggal] format "Y-m-d". [page] mulai dari 1.
  Future<RiwayatLaporanPaginated> getRiwayatLaporan({
    required String token,
    String? tanggal,
    int page = 1,
    int perPage = 10,
  }) async {
    final params = <String, String>{
      'page'    : page.toString(),
      'per_page': perPage.toString(),
    };
    if (tanggal != null) params['tanggal'] = tanggal;

    final uri = Uri.parse('$_base/supervisor/laporan/riwayat')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: ApiClient.headers(token: token));

    _assertOk(res, 'riwayat laporan');

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return RiwayatLaporanPaginated.fromJson(
        body['data'] as Map<String, dynamic>);
  }

  // ── Detail Harian ──────────────────────────────────────────────────────────
  /// [tanggal] format "Y-m-d", contoh: "2026-04-14"
  Future<LaporanHarianDetail> getLaporanHarian({
    required String token,
    required String tanggal,
  }) async {
    final uri = Uri.parse('$_base/supervisor/laporan/harian/$tanggal');
    final res = await http.get(uri, headers: ApiClient.headers(token: token));

    _assertOk(res, 'detail laporan harian');

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    // ── DEBUG: cetak foto_bukti dari setiap checkpoint ──────────────────
    if (kDebugMode) {
      try {
        final detailPetugas = body['data']?['detail_petugas'] as List?;
        detailPetugas?.forEach((petugas) {
          final nama = petugas['petugas']?['nama'] ?? '-';
          final checkpoints = petugas['checkpoints'] as List? ?? [];
          for (final cp in checkpoints) {
            final namacp = cp['nama_checkpoint'] ?? '-';
            final fb = cp['foto_bukti'];
            debugPrint('── [DEBUG foto_bukti] petugas=$nama | cp=$namacp');
            debugPrint('   type=${fb.runtimeType} | value=$fb');
          }
        });
      } catch (e) {
        debugPrint('[DEBUG] Error inspecting foto_bukti: $e');
      }
    }
    // ────────────────────────────────────────────────────────────────────

    return LaporanHarianDetail.fromJson(
        body['data'] as Map<String, dynamic>);
  }

  // ── Update Penanganan Checkpoint ───────────────────────────────────────────
  /// PATCH /supervisor/laporan/checkpoint/{id}/penanganan
  Future<Map<String, dynamic>> updatePenanganan({
  required String token,
  required int checkpointId,
  required bool selesai,
  String? penanganan,
  }) async {
    final uri = Uri.parse(
      '$_base/supervisor/laporan/checkpoint/$checkpointId/penanganan',
    );

    final res = await http.patch(
      uri,
      headers: {
        ...ApiClient.headers(token: token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'selesai'   : selesai,
        'penanganan': penanganan,
      }),
    );

    if (res.statusCode == 422) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Validasi gagal');
    }

    _assertOk(res, 'update penanganan checkpoint');

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  // ── Helper ─────────────────────────────────────────────────────────────────
  void _assertOk(http.Response res, String konteks) {
    if (res.statusCode != 200) {
      throw Exception(
          'Gagal memuat $konteks (HTTP ${res.statusCode})');
    }
  }
}