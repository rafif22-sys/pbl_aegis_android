import '../../../core/config/app_config.dart';

String? _buildFotoUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;

  // Ganti 127.0.0.1/localhost dengan IP dari AppConfig
  String resolved = raw
      .replaceAll('http://127.0.0.1:54321', AppConfig.supabaseUrl)
      .replaceAll('http://localhost:54321', AppConfig.supabaseUrl);

  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return resolved;
  }

  final cleaned = resolved.startsWith('/') ? resolved.substring(1) : resolved;
  return '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.supabaseBucket}/$cleaned';
}

class UserModel {
  final int id;
  final String nama;
  final String email;
  final String role;
  final String? tanggalLahir;
  final String? alamat;
  final String? noHp;
  final String? fotoProfil;
  final String? tanggalBergabung;
  final String? wilayahPengawasan;
  final Map<String, dynamic>? supervisor;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.tanggalLahir,
    this.alamat,
    this.noHp,
    this.fotoProfil,
    this.tanggalBergabung,
    this.wilayahPengawasan,
    this.supervisor,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      role: json['role'],
      tanggalLahir: json['tanggal_lahir'],
      alamat: json['alamat'],
      noHp: json['no_hp'],
      fotoProfil: _buildFotoUrl(json['foto_profil'] as String?),
      tanggalBergabung: json['tanggal_bergabung'],
      wilayahPengawasan: json['wilayah_pengawasan'],
      supervisor: json['supervisor'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'role': role,
        'tanggal_lahir': tanggalLahir,
        'alamat': alamat,
        'no_hp': noHp,
        'foto_profil': fotoProfil,
        'tanggal_bergabung': tanggalBergabung,
        'wilayah_pengawasan': wilayahPengawasan,
        'supervisor': supervisor,
      };
}