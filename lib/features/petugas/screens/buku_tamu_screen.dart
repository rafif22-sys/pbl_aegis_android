// ─────────────────────────────────────────────────────────────────────────────
// buku_tamu_screen.dart
// Halaman utama Buku Tamu — hanya berisi state & layout
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/tamu_model.dart';
import '../providers/tamu_provider.dart';
import 'widgets/buku_tamu/detail_tamu_dialog.dart';
import 'widgets/buku_tamu/formulir_tamu_screen.dart';
import 'widgets/buku_tamu/guest_card.dart';
import 'widgets/buku_tamu/notification_screen.dart';
import 'widgets/buku_tamu/top_bar_screen.dart';

class BukuTamuPage extends StatefulWidget {
  const BukuTamuPage({super.key});

  static const Color kPrimary = Color(0xFF034DC0);
  static const Color kBg = Color(0xFFDCEFFE);

  @override
  State<BukuTamuPage> createState() => _BukuTamuPageState();
}

class _BukuTamuPageState extends State<BukuTamuPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<TamuModel> _tamus = const [];
  DateTime _selectedDate = DateTime.now();

  bool _showAllDates = false;
  String _searchQuery = '';
  String _filterStatus = 'semua';
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadTamu();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data Loading ───────────────────────────────────────────────────────────

  Future<void> _loadTamu() async {
    final token = context.read<AuthProvider>().token;

    if (token == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesi login tidak ditemukan.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await context.read<TamuProvider>().fetchListTamu(token: token);

    if (!mounted) return;
    final provider = context.read<TamuProvider>();
    setState(() {
      _isLoading = false;
      if (provider.state == TamuListState.error) {
        _errorMessage = provider.errorMessage;
      } else {
        _tamus = provider.tamuList;
      }
    });
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  List<TamuModel> get _filteredTamus {
    return _tamus.where((tamu) {
      final bool isMasuk = tamu.status == 'masuk';

      // Filter tanggal (Tamu yang masih masuk selalu ditampilkan)
      if (!_showAllDates && !isMasuk) {
        final masuk = tamu.waktuMasuk.toLocal();
        
        // Tentukan tanggal akhir: waktuKeluar jika ada, jika tidak gunakan masuk
        final keluar = tamu.waktuKeluar?.toLocal() ?? masuk;

        // Normalisasi ke awal hari (00:00:00) agar perbandingan akurat
        final hariMasuk = DateTime(masuk.year, masuk.month, masuk.day);
        final hariKeluar = DateTime(keluar.year, keluar.month, keluar.day);
        final hariDipilih = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );

        // Tamu muncul jika tanggal dipilih berada dalam rentang masuk–keluar
        final dalamRentang = !hariDipilih.isBefore(hariMasuk) &&
            !hariDipilih.isAfter(hariKeluar);

        if (!dalamRentang) return false;
      }

      // Filter nama
      if (_searchQuery.isNotEmpty &&
          !tamu.nama.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Filter status
      if (_filterStatus != 'semua' && tamu.status != _filterStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openForm() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: const FormulirTamuPage(),
      ),
    );

    if (result == true && mounted) {
      await _loadTamu();
      if (!mounted) return;
      NotificationScreen.show(
        context,
        message: 'Data tamu berhasil ditambahkan.',
        backgroundColor: const Color(0xFF0040A2),
        icon: Icons.check,
        iconColor: Colors.blue,
        iconBackgroundColor: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<bool> _prosesKeluar(TamuModel tamu) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return false;

    final result = await context.read<TamuProvider>().markKeluar(
          token: token,
          tamuId: tamu.id,
          waktuKeluar: DateTime.now(),
        );
    return result.success;
  }

  Future<void> _openDetailDialog(TamuModel tamu) async {
    final keluarBerhasil = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: DetailTamuDialog(
          tamu: tamu,
          onKeluar:
              tamu.status == 'keluar' ? null : () => _prosesKeluar(tamu),
        ),
      ),
    );

    if (!mounted) return;

    if (keluarBerhasil == true) {
      await _loadTamu();
      if (!mounted) return;
      NotificationScreen.show(
        context,
        message: 'Berhasil mengubah status tamu.',
        backgroundColor: const Color(0xFF2EB24F),
        icon: Icons.check,
        iconColor: const Color(0xFF2EB24F),
        iconBackgroundColor: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else if (keluarBerhasil == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengubah status tamu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BukuTamuPage.kBg,
      body: Column(
        children: [
          const TopBarScreen(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTamu,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildDatePicker(),
                    const SizedBox(height: 15),
                    _buildSearchAndFilter(),
                    const SizedBox(height: 20),
                    _buildContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton.extended(
          onPressed: _openForm,
          label: const Text(
            'Tambah Tamu',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: BukuTamuPage.kPrimary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Sub-Widgets ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            final role = context.read<AuthProvider>().user?.role;
            final route = switch (role) {
              'petugas'    => AppRoutes.petugasHome,
              'supervisor' => AppRoutes.supervisorHome,
              'warga'      => AppRoutes.wargaHome,
              _            => AppRoutes.login,
            };
            Navigator.pushReplacementNamed(context, route);
          },
          child: const Icon(Icons.arrow_back, size: 28),
        ),
        const SizedBox(width: 10),
        const Text(
          'Buku Tamu',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        _buildAllDatesToggle(),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    final filtered = _filteredTamus;

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.people_outline,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _emptyMessage,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [

          Expanded(
            child: Scrollbar(
              radius: const Radius.circular(10),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final tamu = filtered[index];

                  return GuestCard(
                    tamu: tamu,
                    showAllDates: _showAllDates,
                    onTap: () => _openDetailDialog(tamu),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _emptyMessage {
    if (_searchQuery.isNotEmpty) return 'Tamu "$_searchQuery" tidak ditemukan.';
    if (_showAllDates) return 'Belum ada data tamu.';
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    return isToday ? 'Belum ada tamu hari ini.' : 'Tidak ada tamu pada tanggal ini.';
  }

  Widget _buildAllDatesToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showAllDates = !_showAllDates),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _showAllDates ? BukuTamuPage.kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showAllDates
                ? BukuTamuPage.kPrimary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showAllDates ? Icons.calendar_view_month : Icons.today,
              size: 15,
              color:
                  _showAllDates ? Colors.white : BukuTamuPage.kPrimary,
            ),
            const SizedBox(width: 5),
            Text(
              _showAllDates ? 'Semua Hari' : 'Hari Ini',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _showAllDates ? Colors.white : BukuTamuPage.kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final isFiltered = _filterStatus != 'semua';

    return Row(
      children: [
        // Search bar
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Masukkan nama tamu',
                hintStyle: const TextStyle(fontSize: 13),
                border: InputBorder.none,
                icon: const Icon(Icons.search,
                    color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Filter button
        PopupMenuButton<String>(
          onSelected: (val) => setState(() => _filterStatus = val),
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            _popupItem(
                'semua', 'Semua', Icons.people_outline, Colors.grey),
            _popupItem('masuk', 'Masuk', Icons.login,
                const Color(0xFF034DC0)),
            _popupItem('keluar', 'Keluar', Icons.logout,
                const Color(0xFF2EB24F)),
          ],
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isFiltered
                      ? BukuTamuPage.kPrimary.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isFiltered
                        ? BukuTamuPage.kPrimary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color:
                      isFiltered ? BukuTamuPage.kPrimary : Colors.grey,
                ),
              ),
              if (isFiltered)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _popupItem(
      String value, String label, IconData icon, Color color) {
    final isSelected = _filterStatus == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.black87,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 14, color: color),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFBBDEFB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.calendar_today,
              color: BukuTamuPage.kPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showAllDates
                    ? 'SEMUA HARI'
                    : isToday
                        ? 'HARI INI'
                        : 'TANGGAL DIPILIH',
                style:
                    const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                _showAllDates
                    ? 'Semua Data Tamu'
                    : '${days[_selectedDate.weekday - 1]}, '
                        '${_selectedDate.day} '
                        '${months[_selectedDate.month - 1]} '
                        '${_selectedDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showAllDates
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('id', 'ID'),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _showAllDates ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: _showAllDates ? Colors.grey : Colors.black87,
                ),
                Text(
                  ' Pilih Tanggal',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _showAllDates ? Colors.grey : Colors.black87,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: _showAllDates ? Colors.grey : Colors.black87,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}