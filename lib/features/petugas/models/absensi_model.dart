class AbsensiModel {
  final int idJadwalAbsensi;
  final String tanggal;
  final String hari;
  final String posJaga;
  final double? posJagaLat;
  final double? posJagaLng;
  final String namaShift;
  final String jamMulai;
  final String jamSelesai;
  final String status;
  final String? jamMasuk;
  final String? jamPulang;
  final String? fotoMasuk;
  final String? fotoPulang;
  final RuteInfo? rute;          // ← dari String? menjadi RuteInfo?
  final bool bolehAbsenMasuk;
  final bool bolehAbsenPulang;
  final String waktuBukaMasuk;
  final String waktuBukaPulang;
  final String batasPulang;

  AbsensiModel({
    required this.idJadwalAbsensi,
    required this.tanggal,
    required this.hari,
    required this.posJaga,
    this.posJagaLat,
    this.posJagaLng,
    required this.namaShift,
    required this.jamMulai,
    required this.jamSelesai,
    required this.status,
    this.jamMasuk,
    this.jamPulang,
    this.fotoMasuk,
    this.fotoPulang,
    this.rute,
    required this.bolehAbsenMasuk,
    required this.bolehAbsenPulang,
    required this.waktuBukaMasuk,
    required this.waktuBukaPulang,
    required this.batasPulang,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
    return AbsensiModel(
      idJadwalAbsensi:  json['id_jadwal_absensi'],
      tanggal:          json['tanggal']    ?? '',
      hari:             json['hari']       ?? '',
      posJaga:          json['pos_jaga']   ?? '-',
      posJagaLat:       (json['pos_jaga_lat'] as num?)?.toDouble(),
      posJagaLng:       (json['pos_jaga_lng'] as num?)?.toDouble(),
      namaShift:        json['nama_shift'] ?? '-',
      jamMulai:         json['jam_mulai']  ?? '-',
      jamSelesai:       json['jam_selesai'] ?? '-',
      status:           json['status']     ?? 'menunggu',
      jamMasuk:         json['jam_masuk'],
      jamPulang:        json['jam_pulang'],
      fotoMasuk:        json['foto_masuk'],
      fotoPulang:       json['foto_pulang'],
      // parse object {id, nama_rute, jumlah_checkpoint} — null jika belum ada rute
      rute: json['rute'] != null && json['rute'] is Map
          ? RuteInfo.fromJson(json['rute'] as Map<String, dynamic>)
          : null,
      bolehAbsenMasuk:  json['boleh_absen_masuk']  ?? false,
      bolehAbsenPulang: json['boleh_absen_pulang'] ?? false,
      waktuBukaMasuk:   json['waktu_buka_masuk']   ?? '-',
      waktuBukaPulang:  json['waktu_buka_pulang']  ?? '-',
      batasPulang:      json['batas_pulang']        ?? '-',
    );
  }

  bool get sudahMasuk  => jamMasuk  != null;
  bool get sudahPulang => jamPulang != null;
}

class RuteInfo {
  final int id;
  final String namaRute;
  final int jumlahCheckpoint;
  final int jumlahDilaporkan;

  const RuteInfo({
    required this.id,
    required this.namaRute,
    required this.jumlahCheckpoint,
    this.jumlahDilaporkan = 0,
  });

  factory RuteInfo.fromJson(Map<String, dynamic> json) => RuteInfo(
        id:                json['id']                as int,
        namaRute:          json['nama_rute']         as String,
        jumlahCheckpoint:  json['jumlah_checkpoint'] as int? ?? 0,
        jumlahDilaporkan:  json['jumlah_dilaporkan'] as int? ?? 0,
      );
}