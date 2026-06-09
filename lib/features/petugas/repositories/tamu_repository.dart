import 'package:camera/camera.dart';

import '../models/tamu_model.dart';
import '../models/tamu_request_model.dart';
import '../services/tamu_service.dart';

class TamuRepository {
  Future<List<TamuModel>> getListTamu({required String token}) {
    return TamuService.getListTamu(token: token);
  }

  Future<TamuModel> tambahTamu({
    required String token,
    required String nama,
    required String alamat,
    required String keperluan,
    required XFile fotoTamu,
    String? estimasiKeluar, // ← tambahkan
  }) {
    if (nama.trim().isEmpty ||
        alamat.trim().isEmpty ||
        keperluan.trim().isEmpty) {
      throw Exception('Nama, alamat, dan keperluan wajib diisi.');
    }

    final request = TamuRequestModel(
      nama: nama.trim(),
      alamat: alamat.trim(),
      keperluan: keperluan.trim(),
      fotoTamu: fotoTamu,
      estimasiKeluar: estimasiKeluar, // ← tambahkan
    );

    return TamuService.store(token: token, requestModel: request);
  }

  Future<TamuModel> markKeluar({
    required String token,
    required int tamuId,
    required DateTime waktuKeluar,
  }) {
    final request = TamuUpdateRequestModel(
      status: 'keluar',
      waktuKeluar: waktuKeluar,
    );

    return TamuService.update(
      token: token,
      tamuId: tamuId,
      requestModel: request,
    );
  }
}