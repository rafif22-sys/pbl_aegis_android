import '../../../core/config/app_config.dart'; // ← sesuaikan path

String? _buildFotoUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;

  // Ganti 127.0.0.1/localhost dengan IP laptop dari AppConfig
  String resolved = raw
      .replaceAll('http://127.0.0.1:54321', AppConfig.supabaseUrl)
      .replaceAll('http://localhost:54321', AppConfig.supabaseUrl);

  // Jika sudah URL penuh, langsung return
  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return resolved;
  }

  // Jika path relatif, bangun URL lengkap
  final cleaned = resolved.startsWith('/') ? resolved.substring(1) : resolved;
  return '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.supabaseBucket}/$cleaned';
}

class BukuTamuModel {
  final int id;
  final int? idUser;
  final String nama;
  final String? alamat;
  final String? keperluan;
  final String? fotoTamu;
  final String waktuMasuk;
  final String? waktuKeluar;
  final String status;
  final String namaUser;

  BukuTamuModel({
    required this.id,
    this.idUser,
    required this.nama,
    this.alamat,
    this.keperluan,
    this.fotoTamu,
    required this.waktuMasuk,
    this.waktuKeluar,
    required this.status,
    this.namaUser = '-',
  });

  factory BukuTamuModel.fromJson(Map<String, dynamic> json) {
    return BukuTamuModel(
      id: json['id'],
      idUser: json['id_user'],
      nama: json['nama'] ?? '',
      alamat: json['alamat'],
      keperluan: json['keperluan'],
      fotoTamu: _buildFotoUrl(json['foto_tamu'] as String?),
      waktuMasuk: json['waktu_masuk'] ?? '',
      waktuKeluar: json['waktu_keluar'],
      status: json['status'] ?? '',
      namaUser: json['user']?['nama'] as String? ?? '-',
    );
  }
}
