// lib/features/supervisor/models/laporan_model.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

// ─── Model Ringkasan Per-Hari ─────────────────────────────────────────────────
class LaporanHarianRingkasan {
  final String tanggal;       // "2026-04-14"
  final String hari;          // "Jumat"
  final int totalPatroli;
  final int totalPetugas;
  final int totalCheckpoint;

  const LaporanHarianRingkasan({
    required this.tanggal,
    required this.hari,
    required this.totalPatroli,
    required this.totalPetugas,
    required this.totalCheckpoint,
  });

  factory LaporanHarianRingkasan.fromJson(Map<String, dynamic> json) =>
      LaporanHarianRingkasan(
        tanggal:         json['tanggal']           as String,
        hari:            json['hari']              as String,
        totalPatroli:    (json['total_patroli']    as num).toInt(),
        totalPetugas:    (json['total_petugas']    as num).toInt(),
        totalCheckpoint: (json['total_checkpoint'] as num).toInt(),
      );
}

// ─── Model Detail Harian ──────────────────────────────────────────────────────
class LaporanHarianDetail {
  final String tanggal;
  final String hari;
  final RingkasanStatistik ringkasan;
  final List<DetailPetugas> detailPetugas;

  const LaporanHarianDetail({
    required this.tanggal,
    required this.hari,
    required this.ringkasan,
    required this.detailPetugas,
  });

  factory LaporanHarianDetail.fromJson(Map<String, dynamic> json) =>
      LaporanHarianDetail(
        tanggal:       json['tanggal'] as String,
        hari:          json['hari']    as String,
        ringkasan:     RingkasanStatistik.fromJson(
                           json['ringkasan'] as Map<String, dynamic>),
        detailPetugas: (json['detail_petugas'] as List)
                           .map((e) => DetailPetugas.fromJson(
                                   e as Map<String, dynamic>))
                           .toList(),
      );
}

class RingkasanStatistik {
  final int totalPatroli;
  final int totalPetugas;
  final int totalCheckpoint;
  final int checkpointAman;

  const RingkasanStatistik({
    required this.totalPatroli,
    required this.totalPetugas,
    required this.totalCheckpoint,
    required this.checkpointAman,
  });

  factory RingkasanStatistik.fromJson(Map<String, dynamic> json) =>
      RingkasanStatistik(
        totalPatroli:    (json['total_patroli']    as num).toInt(),
        totalPetugas:    (json['total_petugas']    as num).toInt(),
        totalCheckpoint: (json['total_checkpoint'] as num).toInt(),
        checkpointAman:  (json['checkpoint_aman']  as num).toInt(),
      );
}

class DetailPetugas {
  final int idAbsensi;
  final InfoPetugas petugas;
  final String posJaga;
  final String shift;
  final String jamMulai;
  final String jamSelesai;
  final String? jamMasuk;
  final String? jamPulang;
  final String status;
  final String? fotoMasuk;
  final String? fotoPulang;
  final int totalCheckpoint;
  final List<DetailCheckpoint> checkpoints;

  const DetailPetugas({
    required this.idAbsensi,
    required this.petugas,
    required this.posJaga,
    required this.shift,
    required this.jamMulai,
    required this.jamSelesai,
    this.jamMasuk,
    this.jamPulang,
    required this.status,
    this.fotoMasuk,
    this.fotoPulang,
    required this.totalCheckpoint,
    required this.checkpoints,
  });

  factory DetailPetugas.fromJson(Map<String, dynamic> json) => DetailPetugas(
        idAbsensi:      (json['id_absensi'] as num).toInt(),
        petugas:        InfoPetugas.fromJson(
                            json['petugas'] as Map<String, dynamic>),
        posJaga:        json['pos_jaga']    as String,
        shift:          json['shift']       as String,
        jamMulai:       json['jam_mulai']   as String,
        jamSelesai:     json['jam_selesai'] as String,
        jamMasuk:       json['jam_masuk']   as String?,
        jamPulang:      json['jam_pulang']  as String?,
        status:         json['status']      as String,
        fotoMasuk:      json['foto_masuk']  as String?,
        fotoPulang:     json['foto_pulang'] as String?,
        totalCheckpoint:(json['total_checkpoint'] as num).toInt(),
        checkpoints:    (json['checkpoints'] as List)
                            .map((e) => DetailCheckpoint.fromJson(
                                    e as Map<String, dynamic>))
                            .toList(),
      );
}

class InfoPetugas {
  final int id;
  final String nama;
  final String? fotoProfil;

  const InfoPetugas({required this.id, required this.nama, this.fotoProfil});

  factory InfoPetugas.fromJson(Map<String, dynamic> json) => InfoPetugas(
        id:          (json['id'] as num).toInt(),
        nama:         json['nama'] as String,
        fotoProfil:   json['foto_profil'] as String?,
      );
}

class DetailCheckpoint {
  final int id;
  final String namaCheckpoint;
  final String kondisi;
  final String status;
  final String? catatan;
  final List<String> fotoBukti;
  final String? waktuLaporan;
  final double? latitude;
  final double? longitude;

  const DetailCheckpoint({
    required this.id,
    required this.namaCheckpoint,
    required this.kondisi,
    required this.status,
    this.catatan,
    this.fotoBukti = const [],
    this.waktuLaporan,
    this.latitude,
    this.longitude,
  });

  factory DetailCheckpoint.fromJson(Map<String, dynamic> json) =>
      DetailCheckpoint(
        id:             (json['id'] as num).toInt(),
        namaCheckpoint:  json['nama_checkpoint'] as String,
        kondisi:         json['kondisi']         as String,
        status:          json['status']          as String,
        catatan:         json['catatan']         as String?,
        fotoBukti: _parseFotoBukti(json['foto_bukti']),
        waktuLaporan:    json['waktu_laporan']   as String?,
        latitude:        (json['latitude']  as num?)?.toDouble(),
        longitude:       (json['longitude'] as num?)?.toDouble(),
      );
}

// ─── Model Pagination Riwayat ─────────────────────────────────────────────────
class RiwayatLaporanPaginated {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<LaporanHarianRingkasan> data;

  const RiwayatLaporanPaginated({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory RiwayatLaporanPaginated.fromJson(Map<String, dynamic> json) =>
      RiwayatLaporanPaginated(
        currentPage: (json['current_page'] as num).toInt(),
        lastPage:    (json['last_page']    as num).toInt(),
        perPage:     (json['per_page']     as num).toInt(),
        total:       (json['total']        as num).toInt(),
        data:        (json['data'] as List)
                         .map((e) => LaporanHarianRingkasan.fromJson(
                                 e as Map<String, dynamic>))
                         .toList(),
      );

  bool get hasNextPage => currentPage < lastPage;
}

List<String> _parseFotoBukti(dynamic rawValue) {
  if (rawValue == null) return [];

  String path = '';
  if (rawValue is String) {
    path = rawValue.trim();
  } else if (rawValue is List && rawValue.isNotEmpty) {
    path = rawValue.first.toString().trim();
  }

  if (path.isEmpty) return [];

  // Match "foto_1.jpg" di akhir path, pisahkan base dan ekstensi
  final regex = RegExp(r'(foto_)\d+(\.[a-zA-Z]+)$');
  final match = regex.firstMatch(path);
  if (match != null) {
    final ext  = match.group(2)!;
    final base = path.substring(0, match.start);
    // Maksimal 6 foto, filter yang tidak exist dilakukan di UI
    return List.generate(6, (i) => '${base}foto_${i + 1}$ext');
  }

  return [path];
}