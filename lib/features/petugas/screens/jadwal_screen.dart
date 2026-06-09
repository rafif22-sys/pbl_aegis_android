import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/jadwal_model.dart';
import '../repositories/jadwal_repository.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final _repo = JadwalRepository();

  List<JadwalModel> _jadwalList  = [];
  String _mingguMulai            = '';
  String _mingguAkhir            = '';
  bool _loadingJadwal            = true;
  String? _errorJadwal;

  List<JadwalModel> _riwayatList = [];
  bool _loadingRiwayat           = true;
  String? _errorRiwayat;
  String? _filterTanggal;
  String _filterStatus           = 'Semua';

  final List<String> _statusOptions = [
    'Semua', 'Menunggu', 'Hadir', 'Terlambat', 'Alpha',
  ];

  // ── Warna utama ───────────────────────────────────────
  static const Color _navy      = Color(0xFF0D1B3E);
  static const Color _blue      = Color(0xFF1565C0);
  static const Color _bgPage    = Color(0xFFDCEFFE);
  static const Color _textDark  = Color(0xFF0F2A44);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _textGray  = Color(0xFF94A3B8);

  // ── Warna libur (oranye hangat) ───────────────────────
  static const Color _liburBg     = Color(0xFFFFF7ED);
  static const Color _liburBorder = Color(0xFFFED7AA);
  static const Color _liburBar    = Color(0xFFF97316);
  static const Color _liburText   = Color(0xFF9A3412);
  static const Color _liburTitle  = Color(0xFF9A3412);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _loadAll() async {
    await Future.wait([_fetchJadwal(), _fetchRiwayat()]);
  }

  Future<void> _fetchJadwal() async {
    setState(() { _loadingJadwal = true; _errorJadwal = null; });
    try {
      final result = await _repo.getJadwalMingguan(token: _token);
      setState(() {
        _jadwalList  = result['data'];
        _mingguMulai = result['minggu_mulai'] ?? '';
        _mingguAkhir = result['minggu_akhir'] ?? '';
      });
    } catch (e) {
      setState(() => _errorJadwal = e.toString());
    } finally {
      setState(() => _loadingJadwal = false);
    }
  }

  Future<void> _fetchRiwayat() async {
    setState(() { _loadingRiwayat = true; _errorRiwayat = null; });
    try {
      final list = await _repo.getRiwayatAbsensi(
        token:   _token,
        tanggal: _filterTanggal,
        status:  _filterStatus == 'Semua' ? null : _filterStatus,
      );
      setState(() => _riwayatList = list);
    } catch (e) {
      setState(() => _errorRiwayat = e.toString());
    } finally {
      setState(() => _loadingRiwayat = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────
  bool _isLibur(JadwalModel j) =>
      j.status.toLowerCase() == 'libur';

  String _formatHeaderRange() {
    if (_mingguMulai.isEmpty || _mingguAkhir.isEmpty) return '';
    final s = DateTime.parse(_mingguMulai);
    final e = DateTime.parse(_mingguAkhir);
    const bln = ['','Jan','Feb','Mar','Apr','Mei','Jun',
                  'Jul','Ags','Sep','Okt','Nov','Des'];
    return '${s.day} ${bln[s.month]} - ${e.day} ${bln[e.month]} ${e.year}';
  }

  String _formatTanggalPendek(String iso) {
    try {
      final d = DateTime.parse(iso);
      const bln = ['','JAN','FEB','MAR','APR','MEI','JUN',
                   'JUL','AGS','SEP','OKT','NOV','DES'];
      return '${d.day} ${bln[d.month]} ${d.year}';
    } catch (_) { return iso; }
  }

  IconData _shiftIcon(String s) {
    final n = s.toLowerCase();
    if (n.contains('1') || n.contains('pagi'))  return Icons.wb_sunny_outlined;
    if (n.contains('2') || n.contains('siang')) return Icons.wb_cloudy_outlined;
    return Icons.nightlight_round;
  }

  Color _shiftColor(String s) {
    final n = s.toLowerCase();
    if (n.contains('1') || n.contains('pagi'))  return const Color(0xFFD97706);
    if (n.contains('2') || n.contains('siang')) return const Color(0xFF0284C7);
    return const Color(0xFF7C3AED);
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [
          _buildTopBar(top),
          Expanded(
            child: RefreshIndicator(
              color: _blue,
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJadwalPanel(),
                    const SizedBox(height: 24),
                    _buildRiwayatSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TOP BAR NAVY ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(double topPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 10,
        left: 24,
        right: 24,
        bottom: 10,
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
            'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/new_logo.png',
            height: 30,
            width: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.pets, color: Colors.lightBlueAccent, size: 40),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'ADVANCED EMERGENCY & GUARD INFORMATION SYSTEM',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ─── PANEL JADWAL (container putih rounded) ───────────────────────────────────

  Widget _buildJadwalPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildJadwalHeader(),
            _buildJadwalCardList(),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalHeader() {
    return Container(
      width: double.infinity,
      color: _blue,
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jadwal Minggu Ini',
                  style: TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.white70, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      _formatHeaderRange(),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCardList() {
    if (_loadingJadwal) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorJadwal != null) {
      return _buildError(_errorJadwal!, _fetchJadwal);
    }
    if (_jadwalList.isEmpty) {
      return _buildEmpty('Tidak ada jadwal minggu ini');
    }

    const double cardHeight = 95.0;
    const int maxVisible    = 4;
    final double listHeight = (_jadwalList.length <= maxVisible
            ? _jadwalList.length.toDouble()
            : maxVisible.toDouble()) *
        cardHeight;

    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        itemCount: _jadwalList.length,
        itemBuilder: (ctx, i) => _buildJadwalCard(_jadwalList[i]),
      ),
    );
  }

  // ─── CARD JADWAL ──────────────────────────────────────────────────────────────

  Widget _buildJadwalCard(JadwalModel jadwal) {
    final isLibur   = _isLibur(jadwal);
    final isHariIni = !isLibur &&
        jadwal.tanggal == DateTime.now().toIso8601String().split('T')[0];

    if (isLibur) return _buildLiburCard(jadwal);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: isHariIni ? Colors.white : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: isHariIni
            ? Border.all(color: _blue, width: 1.8)
            : Border.all(color: const Color(0xFFE8EEF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${jadwal.hari.toUpperCase()}, ${_formatTanggalPendek(jadwal.tanggal)}',
            style: const TextStyle(
              color: _textGray, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Pos Jaga: ${jadwal.posJaga}',
            style: const TextStyle(
              color: _textDark, fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!isHariIni) ...[
                const Icon(Icons.access_time_rounded,
                    size: 13, color: _textMuted),
                const SizedBox(width: 4),
              ],
              Text(
                '${jadwal.jamMulai} – ${jadwal.jamSelesai}',
                style: TextStyle(
                  color: isHariIni ? _textDark : _textMuted,
                  fontSize: isHariIni ? 14 : 12,
                  fontWeight:
                      isHariIni ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              Icon(_shiftIcon(jadwal.namaShift),
                  size: isHariIni ? 15 : 13,
                  color: _shiftColor(jadwal.namaShift)),
              const SizedBox(width: 4),
              Text(
                jadwal.namaShift,
                style: TextStyle(
                  color: _shiftColor(jadwal.namaShift),
                  fontSize: isHariIni ? 14 : 12,
                  fontWeight:
                      isHariIni ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── CARD LIBUR ───────────────────────────────────────────────────────────────
  //
  // Tampilan khusus untuk hari libur:
  //  • Background oranye muda (#FFF7ED)
  //  • Garis aksen oranye di sisi kiri (4 px)
  //  • Badge "LIBUR" oranye di kanan
  //  • Ikon pantai & teks "Hari Libur" menggantikan jam & shift
  //  • Ikon dekoratif besar transparan di latar

  Widget _buildLiburCard(JadwalModel jadwal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: _liburBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _liburBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // ── Garis aksen kiri ──────────────────────────
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 4,
                color: _liburBar,
              ),
            ),

            // ── Ikon dekoratif latar (transparan) ─────────
            Positioned(
              right: -6, top: 0, bottom: 0,
              child: Center(
                child: Icon(
                  Icons.beach_access_outlined,
                  size: 56,
                  color: _liburBar.withOpacity(0.08),
                ),
              ),
            ),

            // ── Konten utama ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 11, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hari & tanggal
                  Text(
                    '${jadwal.hari.toUpperCase()}, ${_formatTanggalPendek(jadwal.tanggal)}',
                    style: const TextStyle(
                      color: _liburText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Pos jaga
                  Text(
                    'Pos Jaga: ${jadwal.posJaga}',
                    style: const TextStyle(
                      color: _liburTitle,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Baris bawah: "Hari Libur" + badge
                  Row(
                    children: [
                      const Icon(Icons.beach_access_outlined,
                          size: 14, color: _liburText),
                      const SizedBox(width: 5),
                      const Text(
                        'Hari Libur',
                        style: TextStyle(
                          color: _liburText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // ── Badge "LIBUR" ──────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _liburBorder,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.beach_access_outlined,
                                size: 11, color: _liburText),
                            SizedBox(width: 4),
                            Text(
                              'LIBUR',
                              style: TextStyle(
                                color: _liburText,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SECTION RIWAYAT ──────────────────────────────────────────────────────────

  Widget _buildRiwayatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 22,
              decoration: BoxDecoration(
                color: _blue, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'RIWAYAT PRESENSI',
              style: TextStyle(
                color: _textDark, fontSize: 18,
                fontWeight: FontWeight.bold, letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFilterPanel(),
        const SizedBox(height: 16),
        _buildRiwayatPanel(),   // ← panel baru pengganti ListView langsung
      ],
    );
  }

  Widget _buildRiwayatPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _buildRiwayatContent(),
      ),
    );
  }

  Widget _buildRiwayatContent() {
    if (_loadingRiwayat) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorRiwayat != null) {
      return _buildError(_errorRiwayat!, _fetchRiwayat);
    }
    if (_riwayatList.isEmpty) {
      return _buildEmpty('Tidak ada riwayat absensi');
    }

    const double cardHeight = 100.0;
    const int    maxVisible = 4;
    final double listHeight = (_riwayatList.length <= maxVisible
            ? _riwayatList.length.toDouble()
            : maxVisible.toDouble()) *
        cardHeight;

    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        itemCount: _riwayatList.length,
        itemBuilder: (ctx, i) => _buildRiwayatCard(_riwayatList[i]),
      ),
    );
  }

  // ─── FILTER PANEL ─────────────────────────────────────────────────────────────

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TANGGAL',
                        style: TextStyle(
                          fontSize: 10, color: _textGray,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickTanggal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _filterTanggal ?? 'mm/dd/yyyy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _filterTanggal != null
                                      ? _textDark : _textGray,
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined,
                                size: 15, color: _textGray),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STATUS',
                        style: TextStyle(
                          fontSize: 10, color: _textGray,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterStatus,
                          isExpanded: true,
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 12, color: _textDark,
                            fontWeight: FontWeight.w600,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              size: 18, color: _textGray),
                          items: _statusOptions
                              .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s),
                                  ))
                              .toList(),
                          onChanged: (val) => setState(
                              () => _filterStatus = val ?? 'Semua'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetchRiwayat,
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Terapkan Filter',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() =>
          _filterTanggal = picked.toIso8601String().split('T')[0]);
    }
  }

  // ─── CARD RIWAYAT ─────────────────────────────────────────────────────────────

  Widget _buildRiwayatCard(JadwalModel jadwal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${jadwal.hari.toUpperCase()}, ${_formatTanggalPendek(jadwal.tanggal)}',
                  style: const TextStyle(
                    color: _textGray, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pos Jaga: ${jadwal.posJaga}',
                  style: const TextStyle(
                    color: _textDark, fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: _textMuted),
                    const SizedBox(width: 4),
                    Text('${jadwal.jamMulai} – ${jadwal.jamSelesai}',
                        style: const TextStyle(
                            color: _textMuted, fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(_shiftIcon(jadwal.namaShift),
                        size: 13, color: _shiftColor(jadwal.namaShift)),
                    const SizedBox(width: 4),
                    Text(jadwal.namaShift,
                        style: TextStyle(
                          color: _shiftColor(jadwal.namaShift),
                          fontSize: 12, fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(jadwal.status),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────

  Widget _buildStatusBadge(String status) {
    final map = {
      'hadir':     [const Color(0xFFDCFCE7), const Color(0xFF166534)],
      'terlambat': [const Color(0xFFFEF9C3), const Color(0xFF854D0E)],
      'alpha':     [const Color(0xFFFEE2E2), const Color(0xFF991B1B)],
      'libur':     [const Color(0xFFFED7AA), const Color(0xFF9A3412)],
      'menunggu':  [const Color(0xFFF1F5F9), const Color(0xFF64748B)],
    };
    final colors = map[status.toLowerCase()] ?? map['menunggu']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors[0],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: colors[1],
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.event_busy_rounded,
                size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(msg,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}