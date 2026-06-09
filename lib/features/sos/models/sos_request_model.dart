// features/sos/models/sos_request_model.dart

import 'sos_model.dart';

/// Payload untuk POST /api/sos (kirim SOS baru)
class SosRequestModel {
  final double latitude;
  final double longitude;
  final JenisKeadaan jenisKeadaan;
  final String? deskripsi;
  final bool bantuanWarga;

  SosRequestModel({
    required this.latitude,
    required this.longitude,
    required this.jenisKeadaan,
    this.deskripsi,
    this.bantuanWarga = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude':      latitude,
      'longitude':     longitude,
      'jenis_keadaan': jenisKeadaan.toApiString(),
      'bantuan_warga': bantuanWarga,
      if (deskripsi != null && deskripsi!.isNotEmpty) 'deskripsi': deskripsi,
    };
  }
}

/// Payload untuk PATCH /api/{role}/sos/{id} (update SOS)
class SosUpdateRequestModel {
  final String? status;
  final bool? bantuanWarga;
  final String? deskripsi;
  final double? latitudePetugas;
  final double? longitudePetugas;
  final String? penanganan; // ✅ tambahkan

  SosUpdateRequestModel({
    this.status,
    this.bantuanWarga,
    this.deskripsi,
    this.latitudePetugas,
    this.longitudePetugas,
    this.penanganan, // ✅ tambahkan
  });

  Map<String, dynamic> toJson() {
    return {
      if (status != null)            'status':             status,
      if (bantuanWarga != null)      'bantuan_warga':      bantuanWarga,
      if (deskripsi != null)         'deskripsi':          deskripsi,
      if (latitudePetugas != null)   'latitude_petugas':   latitudePetugas,
      if (longitudePetugas != null)  'longitude_petugas':  longitudePetugas,
      if (penanganan != null)        'penanganan':         penanganan,
    };
  }
}