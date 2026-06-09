class PatroliModel {
  final int    idJadwalAbsensi;
  final String namaRute;
  final String deskripsiRute;
  final String namaShift;
  final String jamShift;
  final String tanggal;        // ← tambah ini
  final List<CheckpointPatroli> checkpoints;
  final List<PolylinePoint>     polyline;

  PatroliModel({
    required this.idJadwalAbsensi,
    required this.namaRute,
    required this.deskripsiRute,
    required this.namaShift,
    required this.jamShift,
    required this.tanggal,     // ← tambah ini
    required this.checkpoints,
    required this.polyline,
  });

  factory PatroliModel.fromJson(Map<String, dynamic> json) {
    return PatroliModel(
      idJadwalAbsensi: json['id_jadwal_absensi'],
      namaRute:        json['nama_rute']      ?? '',
      deskripsiRute:   json['deskripsi_rute'] ?? '',
      namaShift:       json['nama_shift']     ?? '',
      jamShift:        json['jam_shift']      ?? '',
      tanggal:         json['tanggal']        ?? '', // ← tambah ini
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) => CheckpointPatroli.fromJson(e))
          .toList(),
      polyline: (json['polyline'] as List<dynamic>? ?? [])
          .map((e) => PolylinePoint.fromJson(e))
          .toList(),
    );
  }
}

class CheckpointPatroli {
  final int    id;
  final int    idCheckpoint;
  final int    urutan;
  final String namaCheckpoint;
  final double latitude;
  final double longitude;
  final String? deskripsi;
  LaporanCheckpointStatus? laporan;

  CheckpointPatroli({
    required this.id,
    required this.idCheckpoint,
    required this.urutan,
    required this.namaCheckpoint,
    required this.latitude,
    required this.longitude,
    this.deskripsi,
    this.laporan,
  });

  bool get sudahDilaporkan => laporan?.selesai == true;

  factory CheckpointPatroli.fromJson(Map<String, dynamic> json) {
    return CheckpointPatroli(
      id:             json['id'],
      idCheckpoint:   json['id_checkpoint'],
      urutan:         json['urutan'],
      namaCheckpoint: json['nama_checkpoint'] ?? '',
      latitude:       (json['latitude']  as num).toDouble(),
      longitude:      (json['longitude'] as num).toDouble(),
      deskripsi:      json['deskripsi'],
      laporan: json['laporan'] != null
          ? LaporanCheckpointStatus.fromJson(json['laporan'])
          : null,
    );
  }
}

class LaporanCheckpointStatus {
  final int     id;
  final String  kondisi;
  final String  status;        
  final DateTime? waktuLaporan;

  LaporanCheckpointStatus({
    required this.id,
    required this.kondisi,
    required this.status,
    this.waktuLaporan,
  });

  bool get selesai => status == 'selesai';

  factory LaporanCheckpointStatus.fromJson(Map<String, dynamic> json) {
    return LaporanCheckpointStatus(
      id:      json['id'],
      kondisi: json['kondisi'] ?? '',
      status:  json['status']  ?? 'belum',
      waktuLaporan: json['waktu_laporan'] != null
          ? DateTime.tryParse(json['waktu_laporan'])
          : null,
    );
  }
}

class PolylinePoint {
  final double latitude;
  final double longitude;

  PolylinePoint({required this.latitude, required this.longitude});

  factory PolylinePoint.fromJson(Map<String, dynamic> json) {
    return PolylinePoint(
      latitude:  (json['latitude']  as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}