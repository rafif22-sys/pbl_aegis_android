import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../auth/providers/auth_provider.dart';
import '../../../providers/tamu_provider.dart';
import 'upload_foto_screen.dart';

class FormulirTamuPage extends StatefulWidget {
  const FormulirTamuPage({super.key});

  @override
  State<FormulirTamuPage> createState() => _FormulirTamuPageState();
}

class _FormulirTamuPageState extends State<FormulirTamuPage> {
  final _namaCtrl      = TextEditingController();
  final _alamatCtrl    = TextEditingController();
  final _keperluanCtrl = TextEditingController();
  final _jamH          = TextEditingController();
  final _jamM          = TextEditingController();

  DateTime? _tanggalKeluar;
  XFile?    _fotoTamu;
  bool      _isSaving = false;

  String? _namaError;
  String? _alamatError;
  String? _keperluanError;
  String? _jamError;
  bool    _fotoError = false;

  bool get _isFormReady =>
      _namaCtrl.text.trim().isNotEmpty &&
      _alamatCtrl.text.trim().isNotEmpty &&
      _keperluanCtrl.text.trim().isNotEmpty &&
      _fotoTamu != null;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _namaCtrl.addListener(() => setState(() {}));
    _alamatCtrl.addListener(() => setState(() {}));
    _keperluanCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _keperluanCtrl.dispose();
    _jamH.dispose();
    _jamM.dispose();
    super.dispose();
  }

  // ── Pilih Tanggal ──────────────────────────────────────────────────────────

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalKeluar ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF034DC0),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggalKeluar = picked);
  }

  // ── Validasi ───────────────────────────────────────────────────────────────

  bool _validate() {
    setState(() {
      _namaError = _namaCtrl.text.trim().isEmpty ? 'Tolong isi nama tamu' : null;
      _alamatError =
          _alamatCtrl.text.trim().isEmpty ? 'Tolong isi alamat tamu' : null;
      _keperluanError =
          _keperluanCtrl.text.trim().isEmpty ? 'Tolong isi keperluan tamu' : null;
      _fotoError = _fotoTamu == null;

      final jamHIsi = _jamH.text.trim().isNotEmpty;
      final jamMIsi = _jamM.text.trim().isNotEmpty;
      if (jamHIsi || jamMIsi) {
        final jamH = int.tryParse(_jamH.text.trim());
        final jamM = int.tryParse(_jamM.text.trim());
        _jamError =
            (jamH == null || jamM == null || jamH < 0 || jamH > 23 || jamM < 0 || jamM > 59)
                ? 'Format jam tidak valid (HH:MM)'
                : null;
      } else {
        _jamError = null;
      }
    });

    return _namaError == null &&
        _alamatError == null &&
        _keperluanError == null &&
        !_fotoError &&
        _jamError == null;
  }

  // ── Simpan ─────────────────────────────────────────────────────────────────

  Future<void> _simpanTamu() async {
    if (_isSaving) return;
    if (!_validate()) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    String? estimasiKeluar;
    final jamHIsi = _jamH.text.trim().isNotEmpty;
    final jamMIsi = _jamM.text.trim().isNotEmpty;
    if (jamHIsi || jamMIsi) {
      final jamH = int.parse(_jamH.text.trim());
      final jamM = int.parse(_jamM.text.trim());
      final tgl  = _tanggalKeluar ?? DateTime.now();
      final tglStr =
          '${tgl.year}-${tgl.month.toString().padLeft(2, '0')}-${tgl.day.toString().padLeft(2, '0')}';
      estimasiKeluar =
          '$tglStr ${jamH.toString().padLeft(2, '0')}:${jamM.toString().padLeft(2, '0')}';
    }

    setState(() => _isSaving = true);
    try {
      final result = await context.read<TamuProvider>().tambahTamu(
            token: token,
            nama: _namaCtrl.text.trim(),
            alamat: _alamatCtrl.text.trim(),
            keperluan: _keperluanCtrl.text.trim(),
            fotoTamu: _fotoTamu!,
            estimasiKeluar: estimasiKeluar,
          );
      if (!result.success) throw Exception(result.message);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _namaError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Helper format tanggal ──────────────────────────────────────────────────

  String _formatTanggal(DateTime tgl) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${tgl.day} ${bulan[tgl.month]} ${tgl.year}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      // Padding atas lebih besar agar dialog terasa lapang
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Formulir Data Tamu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE55C5C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20), // ← lebih tinggi dari sebelumnya (14)

            // ── Nama ──────────────────────────────────────────────────────
            _label('Nama Tamu'),
            const SizedBox(height: 4),
            _field(
              hint: 'Ketikan nama tamu',
              ctrl: _namaCtrl,
              error: _namaError,
              onChanged: (_) => setState(() => _namaError = null),
            ),

            const SizedBox(height: 16),

            // ── Alamat ────────────────────────────────────────────────────
            _label('Alamat'),
            const SizedBox(height: 4),
            _field(
              hint: 'Ketikan alamat',
              ctrl: _alamatCtrl,
              error: _alamatError,
              onChanged: (_) => setState(() => _alamatError = null),
            ),

            const SizedBox(height: 16),

            // ── Keperluan ─────────────────────────────────────────────────
            _label('Keperluan'),
            const SizedBox(height: 4),
            _field(
              hint: 'Ketikan keperluan tamu',
              ctrl: _keperluanCtrl,
              error: _keperluanError,
              onChanged: (_) => setState(() => _keperluanError = null),
            ),

            const SizedBox(height: 22),

            // ── Estimasi Keluar ────────────────────────────────────────────
            _label('Jam & Tanggal Keluar (opsional)'),
            const SizedBox(height: 10),

            // Tombol pilih tanggal — lebih lebar & tinggi
            GestureDetector(
              onTap: _pilihTanggal,
              child: Container(
                width: double.infinity,          // ← full width
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // ← lebih tinggi
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black26),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 20, color: Color(0xFF034DC0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _tanggalKeluar == null
                            ? 'Pilih tanggal (default: hari ini)'
                            : _formatTanggal(_tanggalKeluar!),
                        style: TextStyle(
                          fontSize: 14,
                          color: _tanggalKeluar == null
                              ? Colors.black38
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (_tanggalKeluar != null)
                      GestureDetector(
                        onTap: () => setState(() => _tanggalKeluar = null),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.black38),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Input jam : menit — kotak lebih besar
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _timeBox(_jamH),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    ':',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                _timeBox(_jamM),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    _tanggalKeluar == null
                        ? 'Jam keluar'
                        : 'Keluar ${_formatTanggal(_tanggalKeluar!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (_jamError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _jamError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 22),

            // ── Foto Tamu ─────────────────────────────────────────────────
            _label('Foto Tamu'),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: _fotoError
                    ? Border.all(color: Colors.red, width: 1.5)
                    : Border.all(color: Colors.transparent),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: UploadFotoScreen(
                  onChanged: (foto) => setState(() {
                    _fotoTamu = foto;
                    _fotoError = false;
                  }),
                ),
              ),
            ),
            if (_fotoError)
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  'Tolong ambil foto tamu',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 28),

            // ── Tombol Simpan ─────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: (_isSaving || !_isFormReady) ? null : _simpanTamu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormReady
                      ? const Color(0xFF034DC0)
                      : Colors.grey.shade400,
                  disabledBackgroundColor: _isFormReady
                      ? const Color(0xFF034DC0)
                      : Colors.grey.shade400,
                  minimumSize: const Size(150, 50),  // ← sedikit lebih besar
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      );

  Widget _field({
    required String hint,
    required TextEditingController ctrl,
    String? error,
    ValueChanged<String>? onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ctrl,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: error != null ? Colors.red : Colors.black12,
                  width: error != null ? 1.5 : 1.0,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color:
                      error != null ? Colors.red : const Color(0xFF034DC0),
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      );

  // Kotak input jam/menit — lebih besar dari sebelumnya
  Widget _timeBox(TextEditingController ctrl) => Container(
        width: 64,   // ← sebelumnya 55
        height: 48,  // ← sebelumnya 35
        decoration: BoxDecoration(
          border: Border.all(
            color: _jamError != null ? Colors.red : Colors.black26,
            width: _jamError != null ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF5F5F5),
        ),
        child: TextField(
          controller: ctrl,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          expands: true,
          minLines: null,
          maxLines: null,
          onChanged: (_) => setState(() => _jamError = null),
          style: const TextStyle(fontSize: 18, height: 1),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
        ),
      );
}