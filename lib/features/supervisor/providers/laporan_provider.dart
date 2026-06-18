// lib/features/supervisor/providers/laporan_provider.dart

import 'package:flutter/foundation.dart';
import '../models/laporan_model.dart';
import '../repositories/laporan_repository.dart';

class LaporanProvider extends ChangeNotifier {
  final LaporanRepository _repo;
  final String token;

  LaporanProvider({required this.token, LaporanRepository? repo})
      : _repo = repo ?? LaporanRepository();

  // ── State: Minggu Ini ──────────────────────────────────────────────────────
  List<LaporanHarianRingkasan> mingguIniList = [];
  String mingguMulai = '';
  String mingguAkhir = '';
  bool loadingMingguIni = false;
  String? errorMingguIni;

  // ── State: Riwayat ─────────────────────────────────────────────────────────
  List<LaporanHarianRingkasan> riwayatList = [];
  bool loadingRiwayat = false;
  String? errorRiwayat;
  bool _hasNextPage = false;
  int _currentPage = 1;
  bool get hasNextPage => _hasNextPage;

  String? filterTanggal; // "Y-m-d" atau null

  // ── State: Detail Harian ───────────────────────────────────────────────────
  LaporanHarianDetail? detailHarian;
  bool loadingDetail = false;
  String? errorDetail;

  // ──────────────────────────────────────────────────────────────────────────
  // FETCH MINGGU INI
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> fetchMingguIni() async {
    loadingMingguIni = true;
    errorMingguIni   = null;
    notifyListeners();

    try {
      final result = await _repo.getLaporanMingguIni(token: token);
      mingguIniList = result['data'] as List<LaporanHarianRingkasan>;
      mingguMulai   = result['minggu_mulai'] as String;
      mingguAkhir   = result['minggu_akhir'] as String;
    } catch (e) {
      errorMingguIni = e.toString();
    } finally {
      loadingMingguIni = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FETCH RIWAYAT (reset ke halaman 1)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> fetchRiwayat() async {
    _currentPage    = 1;
    loadingRiwayat  = true;
    errorRiwayat    = null;
    riwayatList     = [];
    notifyListeners();

    try {
      final paged = await _repo.getRiwayatLaporan(
        token    : token,
        tanggal  : filterTanggal,
        page     : _currentPage,
      );
      riwayatList  = paged.data;
      _hasNextPage = paged.hasNextPage;
      _currentPage = paged.currentPage;
    } catch (e) {
      errorRiwayat = e.toString();
    } finally {
      loadingRiwayat = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LOAD MORE RIWAYAT (infinite scroll)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> loadMoreRiwayat() async {
    if (!_hasNextPage || loadingRiwayat) return;

    loadingRiwayat = true;
    notifyListeners();

    try {
      final paged = await _repo.getRiwayatLaporan(
        token  : token,
        tanggal: filterTanggal,
        page   : _currentPage + 1,
      );
      riwayatList.addAll(paged.data);
      _hasNextPage = paged.hasNextPage;
      _currentPage = paged.currentPage;
    } catch (e) {
      errorRiwayat = e.toString();
    } finally {
      loadingRiwayat = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FETCH DETAIL HARIAN
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> fetchDetailHarian(String tanggal) async {
    loadingDetail = true;
    errorDetail   = null;
    detailHarian  = null;
    notifyListeners();

    try {
      detailHarian = await _repo.getLaporanHarian(
        token  : token,
        tanggal: tanggal,
      );
    } catch (e) {
      errorDetail = e.toString();
    } finally {
      loadingDetail = false;
      notifyListeners();
    }
  }

  // ── State: Penanganan ──────────────────────────────────────────────────────
bool _savingPenanganan = false;
bool get savingPenanganan => _savingPenanganan;
String? errorPenanganan;

// ──────────────────────────────────────────────────────────────────────────
// UPDATE PENANGANAN CHECKPOINT
// ──────────────────────────────────────────────────────────────────────────
/// Mengirim PATCH ke API, lalu mengupdate [DetailCheckpoint] yang relevan
/// di dalam [detailHarian] secara lokal menggunakan [copyWith].
Future<bool> updatePenanganan({
    required int idAbsensi,
    required int checkpointId,
    required bool selesai,
    String? penanganan,
  }) async {
    _savingPenanganan = true;
    errorPenanganan   = null;
    notifyListeners();

    try {
      await _repo.updatePenanganan(
        token        : token,
        checkpointId : checkpointId,
        selesai      : selesai,
        penanganan   : penanganan,
      );

      // Update lokal: cari petugas → cari checkpoint → copyWith
      if (detailHarian != null) {
        final petugasIndex = detailHarian!.detailPetugas
            .indexWhere((p) => p.idAbsensi == idAbsensi);

        if (petugasIndex != -1) {
          final petugas = detailHarian!.detailPetugas[petugasIndex];
          final cpIndex = petugas.checkpoints
              .indexWhere((c) => c.id == checkpointId);

          if (cpIndex != -1) {
            final updated = petugas.checkpoints[cpIndex].copyWith(
              selesai        : selesai,
              penanganan     : penanganan,
              clearPenanganan: penanganan == null,
            );

            // Buat list checkpoints baru (immutable pattern)
            final newCheckpoints = List<DetailCheckpoint>.from(petugas.checkpoints)
              ..[cpIndex] = updated;

            // Rebuild DetailPetugas dengan checkpoints baru
            final newPetugas = DetailPetugas(
              idAbsensi      : petugas.idAbsensi,
              petugas        : petugas.petugas,
              posJaga        : petugas.posJaga,
              shift          : petugas.shift,
              jamMulai       : petugas.jamMulai,
              jamSelesai     : petugas.jamSelesai,
              jamMasuk       : petugas.jamMasuk,
              jamPulang      : petugas.jamPulang,
              status         : petugas.status,
              fotoMasuk      : petugas.fotoMasuk,
              fotoPulang     : petugas.fotoPulang,
              totalCheckpoint: petugas.totalCheckpoint,
              checkpoints    : newCheckpoints,
            );

            // Rebuild detailHarian dengan list petugas baru
            final newPetugasList =
                List<DetailPetugas>.from(detailHarian!.detailPetugas)
                  ..[petugasIndex] = newPetugas;

            detailHarian = LaporanHarianDetail(
              tanggal      : detailHarian!.tanggal,
              hari         : detailHarian!.hari,
              ringkasan    : detailHarian!.ringkasan,
              detailPetugas: newPetugasList,
            );
          }
        }
      }

      return true;
    } catch (e) {
      errorPenanganan = e.toString();
      return false;
    } finally {
      _savingPenanganan = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Set filter tanggal (format Y-m-d) lalu refresh riwayat
  void setFilterTanggal(String? tanggal) {
    filterTanggal = tanggal;
    fetchRiwayat();
  }

  /// Reset filter lalu refresh
  void clearFilter() => setFilterTanggal(null);

  /// Inisialisasi awal halaman laporan
  Future<void> initAll() async {
    await Future.wait([fetchMingguIni(), fetchRiwayat()]);
  }
}