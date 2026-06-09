// features/petugas/screens/sos_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../features/sos/models/sos_model.dart';
import '../../../features/sos/repositories/sos_repository.dart';

import 'widgets/sos/sos_action_buttons.dart';
import 'widgets/sos/sos_bantuan_warga_toggle.dart';
import 'widgets/sos/sos_category_grid.dart';
import 'widgets/sos/sos_dialogs.dart';
import 'widgets/sos/sos_gps_status.dart';
import 'widgets/sos/sos_lainnya_field.dart';
import 'widgets/sos/sos_top_toast.dart';

class SOSFormScreen extends StatefulWidget {
  const SOSFormScreen({super.key});

  @override
  State<SOSFormScreen> createState() => _SOSFormScreenState();
}

class _SOSFormScreenState extends State<SOSFormScreen>
    with WidgetsBindingObserver {
  // ── State ─────────────────────────────────────────────────────────────────

  String _selectedCategory = '';
  bool _isLainnyaChecked = false;
  bool _butuhBantuanWarga = false;
  bool _isLoading = false;
  bool _isLoadingGps = false;
  bool _triedToSubmit = false;
  bool _returnedFromSettings = false;

  String? _errorMessage;
  Position? _currentPosition;

  final TextEditingController _deskripsiController = TextEditingController();
  final FocusNode _deskripsiFocusNode = FocusNode();

  // Map label UI → value API (sesuai enum JenisKeadaan di sos_model.dart)
  static const Map<String, String> _categoryApiValue = {
    'KEBAKARAN':   'kebakaran',
    'PENCURIAN':   'pencurian',
    'HEWAN LIAR':  'hewan liar',
    'BENCANA ALAM': 'bencana alam',
  };

  final _sosRepository = SosRepository();

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get _hasSelectedCategory =>
      (_selectedCategory.isNotEmpty && !_isLainnyaChecked) || _isLainnyaChecked;

  bool get _deskripsiError =>
      _isLainnyaChecked && _deskripsiController.text.trim().isEmpty;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deskripsiController.addListener(() => setState(() {}));
    _getLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deskripsiController.dispose();
    _deskripsiFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returnedFromSettings) {
      _returnedFromSettings = false;
      _getLocation();
    }
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingGps = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final shouldOpen = await SosDialogs.showEnableGps(context);
        if (shouldOpen == true) {
          _returnedFromSettings = true;
          await Geolocator.openLocationSettings();
          setState(() {
            _errorMessage = 'Aktifkan GPS lalu kembali ke aplikasi.';
            _isLoadingGps = false;
          });
          return;
        }
        setState(() {
          _errorMessage = 'GPS harus aktif untuk mengirim SOS.';
          _isLoadingGps = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Izin lokasi ditolak. Tidak dapat mengirim SOS.';
            _isLoadingGps = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final shouldOpen =
            await SosDialogs.showPermissionPermanentlyDenied(context);
        if (shouldOpen == true) {
          _returnedFromSettings = true;
          await Geolocator.openAppSettings();
        }
        setState(() {
          _errorMessage =
              'Izin lokasi diblokir permanen. Aktifkan di pengaturan aplikasi.';
          _isLoadingGps = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingGps = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil lokasi: ${e.toString()}';
        _isLoadingGps = false;
      });
    }
  }

  // ── Kirim SOS ──────────────────────────────────────────────────────────────

  Future<void> _kirimSOS() async {
    setState(() => _triedToSubmit = true);

    if (_currentPosition == null) {
      setState(() => _errorMessage = 'Lokasi belum tersedia. Coba lagi.');
      return;
    }

    if (_deskripsiError) {
      _deskripsiFocusNode.requestFocus();
      setState(() => _errorMessage = 'Mohon isi keterangan untuk kategori Lainnya.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthProvider>().token!;

      final jenisKeadaan = _isLainnyaChecked
          ? JenisKeadaan.lainnya
          : JenisKeadaan.fromString(
              _categoryApiValue[_selectedCategory] ?? 'lainnya',
            );

      // Menggunakan SosRepository — tidak lagi pakai ApiService secara langsung
      await _sosRepository.kirimSOS(
        token:        token,
        latitude:     _currentPosition!.latitude,
        longitude:    _currentPosition!.longitude,
        jenisKeadaan: jenisKeadaan,
        deskripsi:    _isLainnyaChecked ? _deskripsiController.text.trim() : null,
        bantuanWarga: _butuhBantuanWarga,
      );

      if (!mounted) return;

      SosTopToast.show(
        context,
        message:         'PESAN SOS BERHASIL DIKIRIMKAN',
        backgroundColor: const Color(0xFF28A745),
        icon:            Icons.check_circle,
      );

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('Exception:')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Tidak dapat terhubung ke server.';
      });
    }

    setState(() => _isLoading = false);
  }

  // ── Handler untuk widget Lainnya ───────────────────────────────────────────

  void _onLainnyaChanged(bool checked) {
    setState(() {
      _isLainnyaChecked = checked;
      if (checked) _selectedCategory = '';
      _triedToSubmit = false;
      _errorMessage = null;
    });
    if (checked) {
      Future.delayed(
        const Duration(milliseconds: 150),
        () => _deskripsiFocusNode.requestFocus(),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,  
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kirim SOS',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD30000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'PANGGILAN SOS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih keadaan darurat:',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),

              // ── Widget: GPS Status ────────────────────────────────────
              SosGpsStatus(
                isLoading:  _isLoadingGps,
                isDetected: _currentPosition != null,
                onRetry:    _getLocation,
              ),
              const SizedBox(height: 12),

              // ── Widget: Grid Kategori ─────────────────────────────────
              SosCategoryGrid(
                selected: _selectedCategory,
                disabled: _isLainnyaChecked,
                onSelect: (title) => setState(() {
                  _selectedCategory = title;
                  _isLainnyaChecked = false;
                  _triedToSubmit = false;
                  _errorMessage = null;
                }),
              ),
              const SizedBox(height: 12),

              // ── Widget: Checkbox Lainnya + TextField ──────────────────
              SosLainnyaField(
                isChecked:  _isLainnyaChecked,
                showError:  _triedToSubmit && _deskripsiError,
                controller: _deskripsiController,
                focusNode:  _deskripsiFocusNode,
                onChanged:  _onLainnyaChanged,
              ),
              const SizedBox(height: 16),

              // ── Widget: Toggle Bantuan Warga ──────────────────────────
              const Text(
                'APAKAH BUTUH BANTUAN SEMUA WARGA?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              SosBantuanWargaToggle(
                value:     _butuhBantuanWarga,
                onChanged: (v) => setState(() => _butuhBantuanWarga = v),
              ),
              const SizedBox(height: 12),

              // ── Pesan Error ───────────────────────────────────────────
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // ── Widget: Tombol Batal & Kirim ──────────────────────────
              SosActionButtons(
                isLoading:           _isLoading,
                isLoadingGps:        _isLoadingGps,
                hasSelectedCategory: _hasSelectedCategory,
                onBatal:             () => Navigator.pop(context),
                onKirim: () {
                  if (!_hasSelectedCategory) {
                    SosTopToast.show(
                      context,
                      message:         'Pilih jenis keadaan darurat terlebih dahulu',
                      backgroundColor: const Color(0xFFE65100),
                      icon:            Icons.warning_amber_rounded,
                      duration:        const Duration(seconds: 2),
                    );
                    return;
                  }
                  _kirimSOS();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}