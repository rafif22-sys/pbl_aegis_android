class LaporanPatroliModel {
  final int id;
  final String tanggal;
  final String shift;
  final int totalPetugas;
  final int totalCheckpoint;
  final String status;
  final List<PetugasLaporan> petugasList;

  LaporanPatroliModel({
    required this.id,
    required this.tanggal,
    required this.shift,
    required this.totalPetugas,
    required this.totalCheckpoint,
    required this.status,
    required this.petugasList,
  });

  factory LaporanPatroliModel.fromJson(Map<String, dynamic> json) {
    return LaporanPatroliModel(
      id: json['id'],
      tanggal: json['tanggal'],
      shift: json['shift'],
      totalPetugas: json['total_petugas'],
      totalCheckpoint: json['total_checkpoint'],
      status: json['status'],
      petugasList: (json['petugas'] as List?)
              ?.map((e) => PetugasLaporan.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PetugasLaporan {
  final String nama;
  final String waktu;
  final int checkpointDicapai;
  final bool aman;

  PetugasLaporan({
    required this.nama,
    required this.waktu,
    required this.checkpointDicapai,
    required this.aman,
  });

  factory PetugasLaporan.fromJson(Map<String, dynamic> json) {
    return PetugasLaporan(
      nama: json['nama'],
      waktu: json['waktu'],
      checkpointDicapai: json['checkpoint_dicapai'],
      aman: json['aman'],
    );
  }
}
