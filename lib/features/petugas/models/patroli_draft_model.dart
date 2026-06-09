// lib/features/petugas/models/patroli_draft_model.dart

import 'dart:convert';

/// Model untuk satu draft laporan checkpoint yang tersimpan lokal di HP.
/// Digunakan sebelum semua checkpoint selesai dan laporan dikirim ke server.
class PatroliDraftModel {
  final int    idJadwalAbsensi;
  final int    idRuteCheckpoint;
  final String kondisi;
  final String catatan;
  final String waktuLaporan;     // ISO string, dicatat saat "Simpan Lokal"
  final double petugasLatitude;  // posisi petugas saat "Simpan Lokal" (sudah divalidasi 30m)
  final double petugasLongitude;
  final List<String> fotoPaths;  // path file lokal di storage HP (maks 6)

  const PatroliDraftModel({
    required this.idJadwalAbsensi,
    required this.idRuteCheckpoint,
    required this.kondisi,
    required this.catatan,
    required this.waktuLaporan,
    required this.petugasLatitude,
    required this.petugasLongitude,
    required this.fotoPaths,
  });

  // ── Serialisasi ke/dari JSON untuk SharedPreferences ──────────────────────

  Map<String, dynamic> toJson() => {
        'id_jadwal_absensi'   : idJadwalAbsensi,
        'id_rute_checkpoint'  : idRuteCheckpoint,
        'kondisi'             : kondisi,
        'catatan'             : catatan,
        'waktu_laporan'       : waktuLaporan,
        'petugas_latitude'    : petugasLatitude,
        'petugas_longitude'   : petugasLongitude,
        'foto_paths'          : fotoPaths,
      };

  String toJsonString() => jsonEncode(toJson());

  factory PatroliDraftModel.fromJson(Map<String, dynamic> json) {
    return PatroliDraftModel(
      idJadwalAbsensi   : json['id_jadwal_absensi']  as int,
      idRuteCheckpoint  : json['id_rute_checkpoint'] as int,
      kondisi           : json['kondisi']             as String,
      catatan           : json['catatan']             as String? ?? '',
      waktuLaporan      : json['waktu_laporan']       as String,
      petugasLatitude   : (json['petugas_latitude']  as num).toDouble(),
      petugasLongitude  : (json['petugas_longitude'] as num).toDouble(),
      fotoPaths         : List<String>.from(json['foto_paths'] as List? ?? []),
    );
  }

  factory PatroliDraftModel.fromJsonString(String jsonStr) =>
      PatroliDraftModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  /// Buat salinan dengan perubahan field tertentu
  PatroliDraftModel copyWith({
    String?       kondisi,
    String?       catatan,
    String?       waktuLaporan,
    double?       petugasLatitude,
    double?       petugasLongitude,
    List<String>? fotoPaths,
  }) {
    return PatroliDraftModel(
      idJadwalAbsensi  : idJadwalAbsensi,
      idRuteCheckpoint : idRuteCheckpoint,
      kondisi          : kondisi          ?? this.kondisi,
      catatan          : catatan          ?? this.catatan,
      waktuLaporan     : waktuLaporan     ?? this.waktuLaporan,
      petugasLatitude  : petugasLatitude  ?? this.petugasLatitude,
      petugasLongitude : petugasLongitude ?? this.petugasLongitude,
      fotoPaths        : fotoPaths        ?? this.fotoPaths,
    );
  }
}
