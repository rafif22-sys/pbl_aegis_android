// lib/features/petugas/services/patroli_draft_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/patroli_draft_model.dart';

/// Service untuk menyimpan, membaca, dan menghapus draft laporan checkpoint
/// ke SharedPreferences (local storage HP).
///
/// Key format: `patroli_draft_{idJadwalAbsensi}_{idRuteCheckpoint}`
class PatroliDraftService {
  static const String _prefix = 'patroli_draft_';

  static String _key(int idJadwalAbsensi, int idRuteCheckpoint) =>
      '${_prefix}${idJadwalAbsensi}_$idRuteCheckpoint';

  // ── Simpan / timpa satu draft ─────────────────────────────────────────────

  static Future<void> saveDraft(PatroliDraftModel draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(draft.idJadwalAbsensi, draft.idRuteCheckpoint),
      draft.toJsonString(),
    );
  }

  // ── Baca satu draft (nullable jika belum ada) ─────────────────────────────

  static Future<PatroliDraftModel?> getDraft(
    int idJadwalAbsensi,
    int idRuteCheckpoint,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key(idJadwalAbsensi, idRuteCheckpoint));
    if (raw == null) return null;
    try {
      return PatroliDraftModel.fromJsonString(raw);
    } catch (_) {
      // Data rusak → hapus agar tidak blokir alur
      await prefs.remove(_key(idJadwalAbsensi, idRuteCheckpoint));
      return null;
    }
  }

  // ── Cek apakah draft sudah ada untuk satu checkpoint ─────────────────────

  static Future<bool> hasDraft(
    int idJadwalAbsensi,
    int idRuteCheckpoint,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key(idJadwalAbsensi, idRuteCheckpoint));
  }

  // ── Baca semua draft untuk satu sesi patroli ──────────────────────────────
  /// Mengembalikan Map<idRuteCheckpoint, PatroliDraftModel>
  /// Hanya entry yang benar-benar tersimpan yang dikembalikan.

  static Future<Map<int, PatroliDraftModel>> getAllDrafts(
    int    idJadwalAbsensi,
    List<int> checkpointIds,
  ) async {
    final prefs  = await SharedPreferences.getInstance();
    final result = <int, PatroliDraftModel>{};

    for (final cpId in checkpointIds) {
      final raw = prefs.getString(_key(idJadwalAbsensi, cpId));
      if (raw == null) continue;
      try {
        result[cpId] = PatroliDraftModel.fromJsonString(raw);
      } catch (_) {
        await prefs.remove(_key(idJadwalAbsensi, cpId));
      }
    }

    return result;
  }

  // ── Baca map status draft (cpId → true/false) ─────────────────────────────
  /// Digunakan di SesiPatroliScreen untuk update UI status checkbox.

  static Future<Map<int, bool>> getDraftStatusMap(
    int       idJadwalAbsensi,
    List<int> checkpointIds,
  ) async {
    final prefs  = await SharedPreferences.getInstance();
    final result = <int, bool>{};

    for (final cpId in checkpointIds) {
      result[cpId] = prefs.containsKey(_key(idJadwalAbsensi, cpId));
    }

    return result;
  }

  // ── Hapus satu draft ──────────────────────────────────────────────────────

  static Future<void> deleteDraft(
    int idJadwalAbsensi,
    int idRuteCheckpoint,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(idJadwalAbsensi, idRuteCheckpoint));
  }

  // ── Hapus semua draft untuk satu sesi ────────────────────────────────────
  /// Dipanggil HANYA setelah semua laporan berhasil dikirim ke server.
  /// TIDAK dipanggil saat navigasi ke SOS.

  static Future<void> deleteAllDrafts(
    int       idJadwalAbsensi,
    List<int> checkpointIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    for (final cpId in checkpointIds) {
      await prefs.remove(_key(idJadwalAbsensi, cpId));
    }
  }

  // ── Cek apakah ada setidaknya satu draft untuk sesi ini ──────────────────

  static Future<bool> hasAnyDraft(
    int       idJadwalAbsensi,
    List<int> checkpointIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    for (final cpId in checkpointIds) {
      if (prefs.containsKey(_key(idJadwalAbsensi, cpId))) return true;
    }
    return false;
  }
}
