// lib/features/petugas/repositories/patroli_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_client.dart';
import '../models/patroli_model.dart';

class PatroliRepository {
  static String get _base => ApiClient.baseUrl;

  // ── GET sesi patroli ─────────────────────────────────────────────────────
  Future<PatroliModel> getSesi({
    required String token,
    required int idJadwalAbsensi,
  }) async {
    final res = await http.get(
      Uri.parse('$_base/petugas/patroli/$idJadwalAbsensi'),
      headers: ApiClient.headers(token: token),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body['status'] == false) {
      throw Exception(body['message'] ?? 'Gagal memuat sesi patroli');
    }

    return PatroliModel.fromJson(body['data']);
  }

  // ── POST update lokasi petugas (periodik) ────────────────────────────────
  Future<void> updateLokasi({
    required String token,
    required int    idJadwalAbsensi,
    required double latitude,
    required double longitude,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/petugas/patroli/$idJadwalAbsensi/lokasi'),
      headers: ApiClient.headers(token: token),
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body['status'] == false) {
      throw Exception(body['message'] ?? 'Gagal update lokasi');
    }
  }

  // ── POST buat laporan checkpoint ─────────────────────────────────────────
  /// Dipanggil saat "Kirim Laporan" (batch) dari SesiPatroliScreen.
  /// [photos] bisa berupa XFile dari path lokal draft yang tersimpan.
  /// [skipDistanceCheck] = true karena jarak sudah divalidasi saat "Simpan Lokal".
  Future<void> buatLaporan({
    required String      token,
    required int         idJadwalAbsensi,
    required int         idRuteCheckpoint,
    required String      kondisi,
    required String      catatan,
    required double      petugasLatitude,
    required double      petugasLongitude,
    required List<XFile> photos,
    required String      waktuLaporan,
    required String      namaPetugas,    // ← untuk path folder di Supabase (nama checkpoint ditambahkan otomatis oleh backend)
    bool                 skipDistanceCheck = false, // ← true saat kirim batch
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/petugas/patroli/$idJadwalAbsensi/laporan/$idRuteCheckpoint'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept']        = 'application/json'
      ..fields['latitude']             = petugasLatitude.toString()
      ..fields['longitude']            = petugasLongitude.toString()
      ..fields['kondisi']              = kondisi
      ..fields['catatan']              = catatan
      ..fields['waktu_laporan']        = waktuLaporan
      ..fields['nama_petugas']         = namaPetugas
      ..fields['skip_distance_check']  = skipDistanceCheck ? '1' : '0';

    // Lampirkan foto yang file-nya masih ada di storage lokal
    for (final file in photos) {
      final f = File(file.path);
      if (await f.exists()) {
        req.files.add(
          await http.MultipartFile.fromPath('foto[]', file.path),
        );
      }
    }

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res      = await http.Response.fromStream(streamed);
    final body     = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 201 || body['status'] == false) {
      throw Exception(body['message'] ?? 'Gagal menyimpan laporan');
    }
  }
}