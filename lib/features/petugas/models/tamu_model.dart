class TamuModel {
  final int id;
  final int idUser;
  final String nama;
  final String alamat;
  final String keperluan;
  final String? fotoTamu;
  final DateTime waktuMasuk;
  final DateTime? waktuKeluar;
  final String status;
  final String namaUser; 

  TamuModel({
    required this.id,
    required this.idUser,
    required this.nama,
    required this.alamat,
    required this.keperluan,
    required this.fotoTamu,
    required this.waktuMasuk,
    required this.waktuKeluar,
    required this.status,
    required this.namaUser, 
  });

  factory TamuModel.fromJson(Map<String, dynamic> json) {
    return TamuModel(
      id: json['id'] as int,
      idUser: json['id_user'] as int,
      nama: json['nama'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      keperluan: json['keperluan'] as String? ?? '',
      fotoTamu: json['foto_tamu'] as String?,
      waktuMasuk: DateTime.parse(json['waktu_masuk'] as String).toLocal(),
      waktuKeluar: json['waktu_keluar'] != null
          ? DateTime.parse(json['waktu_keluar'] as String).toLocal()
          : null,
      status: json['status'] as String? ?? 'masuk',
      namaUser: json['user']?['nama'] as String? ?? 'Tidak diketahui', // ← tambahkan ini
    );
  }
}