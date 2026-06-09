class JadwalModel {
  final int idJadwalAbsensi;
  final String tanggal;
  final String hari;
  final String posJaga;
  final String jamMulai;
  final String jamSelesai;
  final String namaShift;
  final String status;
  final String? jamMasuk;
  final String? jamPulang;

  JadwalModel({
    required this.idJadwalAbsensi,
    required this.tanggal,
    required this.hari,
    required this.posJaga,
    required this.jamMulai,
    required this.jamSelesai,
    required this.namaShift,
    required this.status,
    this.jamMasuk,
    this.jamPulang,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    return JadwalModel(
      idJadwalAbsensi: json['id_jadwal_absensi'],
      tanggal:         json['tanggal'] ?? '',
      hari:            json['hari'] ?? '',
      posJaga:         json['pos_jaga'] ?? '-',
      jamMulai:        json['jam_mulai'] ?? '-',
      jamSelesai:      json['jam_selesai'] ?? '-',
      namaShift:       json['nama_shift'] ?? '-',
      status:          json['status'] ?? 'menunggu',
      jamMasuk:        json['jam_masuk'],
      jamPulang:       json['jam_pulang'],
    );
  }
}