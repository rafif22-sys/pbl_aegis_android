// features/sos/providers/sos_provider.dart

import 'package:flutter/material.dart';
import '../models/sos_model.dart';
import '../repositories/sos_repository.dart';

enum SosListState { idle, loading, loaded, error }

/// Wrapper hasil konfirmasi — membawa data terbaru atau pesan error BE
class SosResult {
  final bool success;
  final String message;
  final SosModel? data;

  const SosResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class SosProvider extends ChangeNotifier {
  final SosRepository _repo = SosRepository();

  List<SosModel> _allSos = [];
  SosListState _state    = SosListState.idle;
  String _errorMessage   = '';
  String? _activeFilter;

  // ── Getters ──────────────────────────────────────────────
  SosListState get state        => _state;
  String       get errorMessage => _errorMessage;
  String?      get activeFilter => _activeFilter;

  List<SosModel> get sosList {
    if (_activeFilter == null) return _allSos;
    return _allSos
        .where((s) => s.status.toApiString() == _activeFilter)
        .toList();
  }

  int get totalSos      => _allSos.length;
  int get totalSelesai  => _allSos.where((s) => s.status == StatusSOS.selesai).length;
  int get totalMenunggu => _allSos.where((s) => s.status == StatusSOS.menungguBantuan).length;

  // ── Fetch list ───────────────────────────────────────────
  Future<void> fetchListSOS({required String token}) async {
    _state = SosListState.loading;
    notifyListeners();

    try {
      _allSos = await _repo.getListSOS(token: token);
      _state  = SosListState.loaded;
    } catch (e) {
      _state        = SosListState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  // ── Filter ───────────────────────────────────────────────
  void setFilter(String? status) {
    _activeFilter = status;
    notifyListeners();
  }

  // ── Sync satu item setelah patch ─────────────────────────
  void updateSosInList(SosModel updated) {
    final idx = _allSos.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _allSos[idx] = updated;
      notifyListeners();
    }
  }

  // ── Konfirmasi SOS selesai ───────────────────────────────
  /// [role] diambil dari AuthProvider.user!.role ('petugas' / 'supervisor')
  /// BE memvalidasi jarak ≤ 50 m; jika gagal, pesan error BE diteruskan.
  Future<SosResult> konfirmasiSOS({
  required String token,
  required String role,
  required int    sosId,
  required double latitudePetugas,
  required double longitudePetugas,
  required String penanganan, 
  }) async {
    try {
      final updated = await _repo.konfirmasiSOS(
        token:             token,
        role:              role,
        sosId:             sosId,
        latitudePetugas:   latitudePetugas,
        longitudePetugas:  longitudePetugas,
        penanganan:        penanganan, 
      );

      // Sinkron ke list agar RiwayatSosScreen langsung update
      updateSosInList(updated);

      return SosResult(
        success: true,
        message: 'SOS berhasil dikonfirmasi.',
        data:    updated,
      );
    } catch (e) {
      return SosResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}