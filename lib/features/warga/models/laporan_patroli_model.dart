// lib/features/warga/models/laporan_patroli_model.dart

/// Model ringkasan harian dari endpoint GET /warga/laporan-patroli
/// Response: { tanggal, hari, total_patroli, total_petugas, total_checkpoint }
class LaporanPatroliModel {
  final String tanggal;
  final String hari;
  final int totalPatroli;
  final int totalPetugas;
  final int totalCheckpoint;

  const LaporanPatroliModel({
    required this.tanggal,
    required this.hari,
    required this.totalPatroli,
    required this.totalPetugas,
    required this.totalCheckpoint,
  });

  factory LaporanPatroliModel.fromJson(Map<String, dynamic> json) {
    return LaporanPatroliModel(
      tanggal:          json['tanggal']          as String,
      hari:            (json['hari']             as String?) ?? '',
      totalPatroli:    (json['total_patroli']    as num?)?.toInt() ?? 0,
      totalPetugas:    (json['total_petugas']    as num?)?.toInt() ?? 0,
      totalCheckpoint: (json['total_checkpoint'] as num?)?.toInt() ?? 0,
    );
  }
}