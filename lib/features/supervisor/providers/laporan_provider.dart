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