import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/absensi_model.dart';
import '../repositories/absensi_repository.dart';
import 'absen_foto_screen.dart';
import '../../petugas/screens/sesi_patroli_screen.dart';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  final _repo = AbsensiRepository();

  AbsensiModel? _absensi;
  bool _loading = true;
  String? _error;
  bool? _dalamRadius;

  // ── Warna ─────────────────────────────────────────────
  static const Color _bgPage    = Color(0xFFDCEFFE);
  static const Color _blue      = Color(0xFF1565C0);
  static const Color _textDark  = Color(0xFF0F2A44);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _textGray  = Color(0xFF94A3B8);
  static const Color _iconBg    = Color(0xFFC6DDF4);
  static const Color _iconColor = Color(0xFF001F3F);
  static const Color _greenBg   = Color(0xFF22C55E);
  static const Color _disabledBg = Color(0xFFCFCFCF);
  static const Color _disabledText = Color(0xFFF5F5F5);
  static const Color _disabledSubtext = Color(0xFFE8E8E8);
  static const Color _disabledIconBg = Color(0xFFEAEAEA);
  static const Color _disabledIcon = Color(0xFF8A8A8A);

  static const String _logoUrl =
      'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/new_logo.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAbsensi());
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _loadAbsensi() async {
    setState(() { _loading = true; _error = null; _dalamRadius = null; });
    try {
      final data = await _repo.getHariIni(token: _token);
      setState(() => _absensi = data);
      _cekRadius(); // ✅ cek radius setelah data loaded
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cekRadius() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (_absensi?.posJagaLat != null && _absensi?.posJagaLng != null) {
        final jarak = _hitungJarak(
          pos.latitude, pos.longitude,
          _absensi!.posJagaLat!, _absensi!.posJagaLng!,
        );
        if (mounted) setState(() => _dalamRadius = jarak <= 50);
      } else {
        if (mounted) setState(() => _dalamRadius = true);
      }
    } catch (_) {
      if (mounted) setState(() => _dalamRadius = true);
    }
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('GPS tidak aktif. Aktifkan GPS terlebih dahulu.');
      return null;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      _showError('Izin lokasi ditolak. Aktifkan di pengaturan.');
      return null;
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  double _hitungJarak(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  Future<void> _onAbsenMasuk() async {
    final pos = await _getLocation();
    if (pos == null) return;

    if (_absensi!.posJagaLat != null && _absensi!.posJagaLng != null) {
      final jarak = _hitungJarak(
        pos.latitude, pos.longitude,
        _absensi!.posJagaLat!, _absensi!.posJagaLng!,
      );
      if (jarak > 50) {
        _showError('Anda berada ${jarak.round()}m dari pos jaga.\nMaksimal 50m untuk bisa absen.');
        return;
      }
    }

    final foto = await _bukaKamera('Presensi Masuk');
    if (foto == null) return;

    _showLoading('Menyimpan presensi masuk...');
    try {
      
      final result = await _repo.absenMasuk(
        token: _token, foto: foto,
        latitude: pos.latitude, longitude: pos.longitude,
      );
      if (mounted) {
        Navigator.pop(context);
        setState(() => _absensi = result);
        _showSuccess('Presensi masuk berhasil!\nJam: ${result.jamMasuk}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _onAbsenPulang() async {
    final pos = await _getLocation();
    if (pos == null) return;

    if (_absensi!.posJagaLat != null && _absensi!.posJagaLng != null) {
      final jarak = _hitungJarak(
        pos.latitude, pos.longitude,
        _absensi!.posJagaLat!, _absensi!.posJagaLng!,
      );
      if (jarak > 50) {
        _showError('Anda berada ${jarak.round()}m dari pos jaga.\nMaksimal 50m untuk bisa absen.');
        return;
      }
    }

    final foto = await _bukaKamera('Absen Pulang');
    if (foto == null) return;

    _showLoading('Menyimpan absen pulang...');
    try {
      final result = await _repo.absenPulang(
        token: _token, foto: foto,
        latitude: pos.latitude, longitude: pos.longitude,
      );
      if (mounted) {
        Navigator.pop(context);
        setState(() => _absensi = result);
        _showSuccess('Absen pulang berhasil!\nStatus: ${result.status.toUpperCase()}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<File?> _bukaKamera(String tipeAbsen) async {
    if (!mounted) return null;
    return await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => AbsenFotoScreen(
          tipeAbsen : tipeAbsen,
          namaShift : _absensi!.namaShift,
          jamMulai  : _absensi!.jamMulai,
          posJaga   : _absensi!.posJaga,
        ),
      ),
    );
  }

  void _showLoading(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(children: [
          const CircularProgressIndicator(color: _blue),
          const SizedBox(width: 16),
          Expanded(child: Text(msg, style: const TextStyle(color: _textDark))),
        ]),
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          SizedBox(width: 8),
          Text('Gagal', style: TextStyle(color: Color(0xFFDC2626), fontSize: 16)),
        ]),
        content: Text(msg, style: const TextStyle(color: _textDark)),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _blue)))],
      ),
    );
  }

  void _showSuccess(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF16A34A)),
          SizedBox(width: 8),
          Text('Berhasil', style: TextStyle(color: Color(0xFF16A34A), fontSize: 16)),
        ]),
        content: Text(msg, style: const TextStyle(color: _textDark)),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _blue)))],
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [
          // ── Top Bar (sama persis dengan TopBarScreen) ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding + 10, left: 24, right: 24, bottom: 10,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  _logoUrl,
                  height: 30, width: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.security, color: Colors.lightBlueAccent, size: 30),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'ADVANCED EMERGENCY & GUARD INFORMATION SYSTEM',
                    style: TextStyle(
                      color: Colors.white70, fontSize: 9,
                      fontWeight: FontWeight.w600, letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Judul halaman (di bawah header, bukan di header) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: _iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'PRESENSI',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Konten ──
          Expanded(
            child: RefreshIndicator(
              color: _blue,
              onRefresh: _loadAbsensi,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _loading
                    ? const Center(child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: CircularProgressIndicator(),
                      ))
                    : _error != null
                        ? _buildError()
                        : _absensi == null
                            ? _buildTidakAdaJadwal()
                            : _buildKonten(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── KONTEN UTAMA ───────────────────────────────────────────────────────────
  Widget _buildKonten() {
    final a = _absensi!;
    final sudahMulaiPatroli = (a.rute?.jumlahDilaporkan ?? 0) > 0;
    final tampilkanSesiPatroli = a.sudahMasuk
        && a.rute != null
        && a.status != 'alpha'
        && !(a.pulangCepat && !sudahMulaiPatroli);   

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(a),
        const SizedBox(height: 20),
        _buildTombolMasuk(a),
        const SizedBox(height: 12),
        _buildTombolPulang(a),
        if (tampilkanSesiPatroli) ...[         
          const SizedBox(height: 20),
          _buildSesiPatroli(a),
        ],
      ],
    );
  }

  // ── CARD INFO ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard(AbsensiModel a) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Baris 1: Jam Shift & Lokasi — ✅ crossAxisAlignment.start agar sejajar atas
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // ✅ fix alignment
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.access_time_rounded,
                    label: 'JAM SHIFT',
                    value: '${a.jamMulai} - ${a.jamSelesai}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'LOKASI',
                    value: a.posJaga.toUpperCase(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Baris 2: Hari & Tanggal
          _buildInfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'HARI & TANGGAL',
            value: '${a.hari}, ${_formatTanggal(a.tanggal)}',
            fullWidth: true,
          ),
          const SizedBox(height: 14),
          // ✅ Indikator radius dinamis
          _buildRadiusIndicator(),
        ],
      ),
    );
  }

  Widget _buildRadiusIndicator() {
    if (_dalamRadius == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF64748B)),
            ),
            SizedBox(width: 8),
            Text('Mengecek lokasi...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      );
    }

    final dalamRadius = _dalamRadius!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dalamRadius ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dalamRadius
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            dalamRadius
                ? Icons.check_circle_outline
                : Icons.location_off_outlined,
            size: 16,
            color: dalamRadius
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dalamRadius
                  ? 'Radius lokasi sesuai titik penugasan'
                  : 'Anda berada di luar jangkauan pos jaga',
              style: TextStyle(
                color: dalamRadius
                    ? const Color(0xFF166534)
                    : const Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    color: _textGray, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  )),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                    color: _textDark, fontSize: 14,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ),
      ],
    );

    return content;
  }

  // ── TOMBOL Presensi MASUK ─────────────────────────────────────────────────────
  Widget _buildTombolMasuk(AbsensiModel a) {
    final sudah  = a.sudahMasuk;
    final boleh  = a.bolehAbsenMasuk;
    final aktif  = boleh && !sudah;
    final isAlpha = a.status == 'alpha'; 

    
    if (isAlpha && !sudah) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDC2626), width: 2),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alpha',
                      style: TextStyle(
                        color: Color(0xFFDC2626), fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(height: 4),
                  Text('Anda tidak melakukan presensi masuk dan pulang',
                      style: TextStyle(
                        color: Color(0xFFDC2626), fontSize: 13,
                      )),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: aktif ? _onAbsenMasuk : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: sudah
              ? const Color(0xFFF0FDF4)
              : aktif
                  ? _greenBg
                  : _disabledBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: aktif
              ? [
                  BoxShadow(
                    color: _greenBg.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: sudah
                    ? const Color(0xFF16A34A).withOpacity(0.15)
                    : aktif
                        ? Colors.green.shade700
                        : _disabledIconBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: sudah
                      ? const Color(0xFF16A34A)
                      : aktif
                          ? Colors.white
                          : Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                sudah
                    ? Icons.check_rounded
                    : Icons.login_rounded,
                color: sudah
                    ? const Color(0xFF16A34A)
                    : aktif
                        ? Colors.white
                        : _disabledIcon,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presensi Masuk',
                    style: TextStyle(
                      color: sudah
                          ? const Color(0xFF166534)
                          : aktif
                              ? Colors.white
                              : _disabledText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    sudah
                        ? (a.jamMasuk ?? '-')
                        : 'Buka jam ${a.waktuBukaMasuk}',
                    style: TextStyle(
                      color: sudah
                          ? const Color(0xFF16A34A)
                          : aktif
                              ? Colors.white.withOpacity(0.9)
                              : _disabledSubtext,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: aktif
                  ? Colors.white
                  : Colors.white70,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ── TOMBOL Presensi PULANG ────────────────────────────────────────────────────
  Widget _buildTombolPulang(AbsensiModel a) {
    final sudah  = a.sudahPulang;
    final boleh  = a.bolehAbsenPulang;
    final aktif  = boleh && !sudah && a.sudahMasuk;
    final isAlpha = a.status == 'alpha'; 

  
    if (isAlpha) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDC2626), width: 2),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alpha',
                      style: TextStyle(
                        color: Color(0xFFDC2626), fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    a.sudahMasuk
                        ? 'Anda tidak melakukan presensi pulang'
                        : 'Anda tidak melakukan presensi masuk dan pulang',
                    style: const TextStyle(
                      color: Color(0xFFDC2626), fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: aktif ? _onAbsenPulang : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: sudah
              ? const Color(0xFFF0FDF4)
              : aktif
                  ? _blue
                  : _disabledBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: aktif
              ? [
                  BoxShadow(
                    color: _blue.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: sudah
                    ? const Color(0xFF16A34A).withOpacity(0.15)
                    : aktif
                        ? Colors.blue.shade700
                        : _disabledIconBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                sudah
                    ? Icons.check_rounded
                    : Icons.logout_rounded,
                color: sudah
                    ? const Color(0xFF16A34A)
                    : aktif
                        ? Colors.white
                        : _disabledIcon,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presensi Keluar',
                    style: TextStyle(
                      color: sudah
                          ? const Color(0xFF166534)
                          : aktif
                              ? Colors.white
                              : _disabledText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    sudah
                        ? (a.jamPulang ?? '-')
                        : a.pulangCepat
                            ? 'Pulang cepat diizinkan ⚡'           // ← teks khusus pulang cepat
                            : 'Buka jam ${a.waktuBukaPulang} – ${a.batasPulang}',
                    style: TextStyle(
                      color: sudah
                          ? const Color(0xFF16A34A)
                          : aktif
                              ? Colors.white.withOpacity(0.9)
                              : _disabledSubtext,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: aktif
                  ? Colors.white
                  : Colors.white70,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSesiPatroli(AbsensiModel a) {
    final rute = a.rute;
    final isAlpha   = a.status == 'alpha';
    final isSelesai = rute != null && 
                      rute.jumlahCheckpoint > 0 && 
                      rute.jumlahDilaporkan >= rute.jumlahCheckpoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Judul "Sesi Patroli" ───────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 4, height: 22,
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Sesi Patroli',
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
 
        // ── Card Patroli ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCEFFE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Baris atas: badge + checkpoint ──────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tugas Patroli',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // ✅ Checkpoint dengan background
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // ✅ background biru muda
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)), // ✅ border biru
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${a.rute!.jumlahCheckpoint} checkpoint',
                            style: const TextStyle(
                              color: _blue, // ✅ teks biru
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _blue, // ✅ ikon biru
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
 
                const SizedBox(height: 16),
 
                // ── Ikon perisai + info shift & tanggal & tombol ────────────────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ikon perisai — sedikit lebih lebar
                      Container(
                        width: 110, 
                        decoration: BoxDecoration(
                          color: isSelesai ? const Color(0xFF16A34A).withOpacity(0.15) : _iconBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isSelesai ? Icons.check_circle_rounded : Icons.security_rounded,
                          color: isSelesai ? const Color(0xFF16A34A) : _blue,
                          size: 44,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Info jam, tanggal, dan tombol — rata TENGAH
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center, 
                          mainAxisAlignment: MainAxisAlignment.center,   
                          children: [
                            Text(
                                '${a.jamMulai} - ${a.jamSelesai}',
                                style: const TextStyle(
                                  color: _textDark,
                                  fontSize: 22, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${a.hari}, ${_formatTanggal(a.tanggal)}',
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 14, // ✅ naik dari 13 → 14
                                ),
                              ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 150, 
                              child: ElevatedButton(
                                onPressed: isSelesai ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SesiPatroliScreen(
                                        idJadwalAbsensi: a.idJadwalAbsensi, 
                                      ),
                                    ),
                                  ).then((_) => _loadAbsensi()); // reload in case patroli completed
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelesai ? _disabledBg : _greenBg,
                                  foregroundColor: isSelesai ? _disabledText : Colors.white,
                                  disabledBackgroundColor: _disabledBg,
                                  disabledForegroundColor: _disabledText,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  isSelesai ? 'Patroli Selesai' : 'Mulai Patroli',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── EMPTY & ERROR ──────────────────────────────────────────────────────────
  Widget _buildTidakAdaJadwal() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: _textGray.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Tidak ada jadwal hari ini',
                style: TextStyle(color: _textGray, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error ?? 'Terjadi kesalahan',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAbsensi,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTanggal(String iso) {
    try {
      final datePart = iso.split('T').first;
      final parts = datePart.split('-');
      if (parts.length < 3) return iso;
      final year  = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day   = int.parse(parts[2]);
      const bln = ['','Jan','Feb','Mar','Apr','Mei','Jun',
                   'Jul','Ags','Sep','Okt','Nov','Des'];
      return '$day ${bln[month]} $year';
    } catch (_) { return iso; }
  }
}