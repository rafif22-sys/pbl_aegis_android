import 'package:camera/camera.dart';

class TamuRequestModel {
  final String nama;
  final String alamat;
  final String keperluan;
  final XFile fotoTamu;
  final String status;
  final String? estimasiKeluar; // ← tambahkan

  const TamuRequestModel({
    required this.nama,
    required this.alamat,
    required this.keperluan,
    required this.fotoTamu,
    this.status = 'masuk',
    this.estimasiKeluar, // ← tambahkan
  });

  Map<String, String> toFields() {
    final fields = {
      'nama': nama,
      'alamat': alamat,
      'keperluan': keperluan,
      'status': status,
    };

    // Kirim estimasi keluar jika ada (format HH:mm)
    if (estimasiKeluar != null) {
      fields['estimasi_keluar'] = estimasiKeluar!;
    }

    return fields;
  }
}

class TamuUpdateRequestModel {
  final String status;
  final DateTime? waktuKeluar;

  const TamuUpdateRequestModel({required this.status, this.waktuKeluar});

  Map<String, String> toFields() {
    final fields = <String, String>{'status': status};

    if (waktuKeluar != null) {
      fields['waktu_keluar'] = waktuKeluar!.toIso8601String();
      fields['jam_keluar'] =
          '${waktuKeluar!.hour.toString().padLeft(2, '0')}:'
          '${waktuKeluar!.minute.toString().padLeft(2, '0')}';
    }

    return fields;
  }
}