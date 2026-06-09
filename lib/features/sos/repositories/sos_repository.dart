// features/sos/repositories/sos_repository.dart

import '../models/sos_model.dart';
import '../models/sos_request_model.dart';
import '../services/sos_service.dart';

class SosRepository {
  /// Kirim SOS baru
  Future<SosModel> kirimSOS({
    required String token,
    required double latitude,
    required double longitude,
    required JenisKeadaan jenisKeadaan,
    String? deskripsi,
    bool bantuanWarga = false,
  }) async {
    if (jenisKeadaan == JenisKeadaan.lainnya &&
        (deskripsi == null || deskripsi.trim().isEmpty)) {
      throw Exception('Deskripsi wajib diisi untuk jenis keadaan lainnya');
    }

    final request = SosRequestModel(
      latitude:     latitude,
      longitude:    longitude,
      jenisKeadaan: jenisKeadaan,
      deskripsi:    deskripsi,
      bantuanWarga: bantuanWarga,
    );

    return SosService.kirimSOS(token: token, request: request);
  }

  /// Update status SOS oleh petugas atau supervisor (umum)
  Future<SosModel> updateSOS({
    required String token,
    required String role,
    required int sosId,
    String? status,
    bool? bantuanWarga,
    String? deskripsi,
  }) async {
    final request = SosUpdateRequestModel(
      status:       status,
      bantuanWarga: bantuanWarga,
      deskripsi:    deskripsi,
    );

    return SosService.updateSOS(
      token:   token,
      role:    role,
      sosId:   sosId,
      request: request,
    );
  }

  /// Konfirmasi SOS selesai ditangani — menyertakan koordinat petugas/supervisor
  /// BE memvalidasi jarak Haversine ≤ 50 m dari lokasi SOS.
  /// Jika > 50 m, BE return 422 dan Exception berisi pesan jarak.
  Future<SosModel> konfirmasiSOS({
    required String token,
    required String role,
    required int    sosId,
    required double latitudePetugas,
    required double longitudePetugas,
    required String penanganan, 
  }) async {
    final request = SosUpdateRequestModel(
      status:            'selesai',
      latitudePetugas:   latitudePetugas,
      longitudePetugas:  longitudePetugas,
      penanganan:        penanganan, 
    );

    return SosService.updateSOS(
      token:   token,
      role:    role,
      sosId:   sosId,
      request: request,
    );
  }

  /// Ambil list SOS
  Future<List<SosModel>> getListSOS({
    required String token,
    String? filterStatus,
  }) async {
    return SosService.getListSOS(
      token:        token,
      filterStatus: filterStatus,
    );
  }

  /// Ambil detail satu SOS
  Future<SosModel> getSOS({
    required String token,
    required int sosId,
  }) async {
    return SosService.getSOS(token: token, sosId: sosId);
  }
}