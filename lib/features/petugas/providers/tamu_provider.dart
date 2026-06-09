import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/tamu_model.dart';
import '../repositories/tamu_repository.dart';

enum TamuListState { idle, loading, loaded, error }

class TamuResult {
  final bool success;
  final String message;
  final TamuModel? data;

  const TamuResult({required this.success, required this.message, this.data});
}

class TamuProvider extends ChangeNotifier {
  final TamuRepository _repo = TamuRepository();

  List<TamuModel> _tamuList = [];
  TamuListState _state = TamuListState.idle;
  String _errorMessage = '';

  List<TamuModel> get tamuList => _tamuList;
  TamuListState get state => _state;
  String get errorMessage => _errorMessage;

  int get totalTamu => _tamuList.length;
  int get totalMasuk =>
      _tamuList.where((tamu) => tamu.status == 'masuk').length;
  int get totalKeluar =>
      _tamuList.where((tamu) => tamu.status == 'keluar').length;

  Future<void> fetchListTamu({required String token}) async {
    _state = TamuListState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _tamuList = await _repo.getListTamu(token: token);
      _state = TamuListState.loaded;
    } catch (e) {
      _state = TamuListState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  Future<TamuResult> tambahTamu({
  required String token,
  required String nama,
  required String alamat,
  required String keperluan,
  required XFile fotoTamu,
  String? estimasiKeluar, // ← tambahkan
}) async {
  try {
    final tamu = await _repo.tambahTamu(
      token: token,
      nama: nama,
      alamat: alamat,
      keperluan: keperluan,
      fotoTamu: fotoTamu,
      estimasiKeluar: estimasiKeluar, // ← tambahkan
    );

    _tamuList = [tamu, ..._tamuList];
    notifyListeners();

    return TamuResult(
      success: true,
      message: 'Data tamu berhasil ditambahkan.',
      data: tamu,
    );
  } catch (e) {
    return TamuResult(
      success: false,
      message: e.toString().replaceFirst('Exception: ', ''),
    );
  }
}

  Future<TamuResult> markKeluar({
    required String token,
    required int tamuId,
    required DateTime waktuKeluar,
  }) async {
    try {
      final updated = await _repo.markKeluar(
        token: token,
        tamuId: tamuId,
        waktuKeluar: waktuKeluar,
      );

      final index = _tamuList.indexWhere((tamu) => tamu.id == updated.id);
      if (index != -1) {
        _tamuList[index] = updated;
      }
      notifyListeners();

      return TamuResult(
        success: true,
        message: 'Berhasil mengubah status tamu.',
        data: updated,
      );
    } catch (e) {
      return TamuResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
