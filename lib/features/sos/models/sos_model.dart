// features/sos/models/sos_model.dart
import '../../../core/config/app_config.dart';
enum JenisKeadaan {
  kebakaran,
  pencurian,
  hewanLiar,
  bencanaAlam,
  lainnya;

  String toApiString() {
    switch (this) {
      case JenisKeadaan.kebakaran:   return 'kebakaran';
      case JenisKeadaan.pencurian:   return 'pencurian';
      case JenisKeadaan.hewanLiar:   return 'hewan liar';
      case JenisKeadaan.bencanaAlam: return 'bencana alam';
      case JenisKeadaan.lainnya:     return 'lainnya';
    }
  }

  static JenisKeadaan fromString(String value) {
    switch (value) {
      case 'kebakaran':   return JenisKeadaan.kebakaran;
      case 'pencurian':   return JenisKeadaan.pencurian;
      case 'hewan liar':  return JenisKeadaan.hewanLiar;
      case 'bencana alam':return JenisKeadaan.bencanaAlam;
      default:            return JenisKeadaan.lainnya;
    }
  }

  String get label {
    switch (this) {
      case JenisKeadaan.kebakaran:   return 'Kebakaran';
      case JenisKeadaan.pencurian:   return 'Pencurian';
      case JenisKeadaan.hewanLiar:   return 'Hewan Liar';
      case JenisKeadaan.bencanaAlam: return 'Bencana Alam';
      case JenisKeadaan.lainnya:     return 'Lainnya';
    }
  }
}

enum StatusSOS {
  menungguBantuan,
  selesai;

  String toApiString() {
    switch (this) {
      case StatusSOS.menungguBantuan: return 'menunggu bantuan';
      case StatusSOS.selesai:         return 'selesai';
    }
  }

  static StatusSOS fromString(String value) {
    switch (value) {
      case 'selesai': return StatusSOS.selesai;
      default:        return StatusSOS.menungguBantuan;
    }
  }

  String get label {
    switch (this) {
      case StatusSOS.menungguBantuan: return 'Menunggu Bantuan';
      case StatusSOS.selesai:         return 'Selesai';
    }
  }
}

// Base URL Supabase Storage
String? _buildFotoUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;

  String resolved = raw
      .replaceAll('http://127.0.0.1:54321', AppConfig.supabaseUrl)
      .replaceAll('http://localhost:54321', AppConfig.supabaseUrl);

  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return resolved;
  }

  final cleaned = resolved.startsWith('/') ? resolved.substring(1) : resolved;
  return '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.supabaseBucket}/$cleaned';
}


// ── Pelapor SOS (user yang kirim) ───────────────────
class SosPelapor {
  final int id;
  final String nama;
  final String? fotoProfil;

  SosPelapor({required this.id, required this.nama, this.fotoProfil});

  factory SosPelapor.fromJson(Map<String, dynamic> json) {
    return SosPelapor(
      id:         json['id'],
      nama:       json['nama'],
      fotoProfil: _buildFotoUrl(json['foto_profil'] as String?),
    );
  }
}

// ── Konfirmator SOS (petugas/supervisor yang konfirmasi)
class SosKonfirmator {
  final int id;
  final String nama;
  final String? fotoProfil;

  SosKonfirmator({required this.id, required this.nama, this.fotoProfil});

  factory SosKonfirmator.fromJson(Map<String, dynamic> json) {
    return SosKonfirmator(
      id:         json['id'],
      nama:       json['nama'],
      fotoProfil: _buildFotoUrl(json['foto_profil'] as String?),
    );
  }
}

// ── Model utama SOS ──────────────────────────────────
class SosModel {
  final int id;
  final int idUser;
  final double latitude;
  final double longitude;
  final JenisKeadaan jenisKeadaan;
  final String deskripsi;
  final String waktuKirim;
  final StatusSOS status;
  final bool bantuanWarga;
  final int?            dikonfirmasiOleh;
  final String?         waktuKonfirmasi;
  final String?         penanganan;       // ✅ tambahan
  final SosPelapor?     user;
  final SosKonfirmator? konfirmator;

  SosModel({
    required this.id,
    required this.idUser,
    required this.latitude,
    required this.longitude,
    required this.jenisKeadaan,
    required this.deskripsi,
    required this.waktuKirim,
    required this.status,
    required this.bantuanWarga,
    this.dikonfirmasiOleh,
    this.waktuKonfirmasi,
    this.penanganan,                      // ✅ tambahan
    this.user,
    this.konfirmator,
  });

  factory SosModel.fromJson(Map<String, dynamic> json) {
    return SosModel(
      id:               json['id'],
      idUser:           json['id_user'],
      latitude:         (json['latitude'] as num).toDouble(),
      longitude:        (json['longitude'] as num).toDouble(),
      jenisKeadaan:     JenisKeadaan.fromString(json['jenis_keadaan']),
      deskripsi:        json['deskripsi'] ?? '',
      waktuKirim:       json['waktu_kirim'] ?? '',
      status:           StatusSOS.fromString(json['status']),
      bantuanWarga:     json['bantuan_warga'] == true || json['bantuan_warga'] == 1,
      dikonfirmasiOleh: json['dikonfirmasi_oleh'],
      waktuKonfirmasi:  json['waktu_konfirmasi'],
      penanganan:       json['penanganan'],             // ✅ tambahan
      user: json['user'] != null
          ? SosPelapor.fromJson(json['user'])
          : null,
      konfirmator: json['konfirmator'] != null
          ? SosKonfirmator.fromJson(json['konfirmator'])
          : null,
    );
  }
}