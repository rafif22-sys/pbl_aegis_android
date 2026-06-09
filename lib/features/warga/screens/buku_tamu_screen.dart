import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../petugas/models/tamu_model.dart';
import '../../petugas/providers/tamu_provider.dart';
import '../../petugas/screens/widgets/buku_tamu/top_bar_screen.dart';
import '../../../core/config/app_config.dart';

class BukuTamuScreen extends StatefulWidget {
  const BukuTamuScreen({super.key});

  static const Color kPrimary = Color(0xFF034DC0);
  static const Color kBg = Color(0xFFDCEFFE);

  @override
  State<BukuTamuScreen> createState() => _BukuTamuScreenState();
}

class _BukuTamuScreenState extends State<BukuTamuScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<TamuModel> _tamus = const [];
  DateTime _selectedDate = DateTime.now();

  // ── State filter ─────────────────────────
  bool _showAllDates = false;
  String _searchQuery = '';
  String _filterStatus = 'semua';
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

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

  Future<void> _loadTamu() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

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
    final tamuProvider = context.read<TamuProvider>();
    setState(() {
      _isLoading = false;
      if (tamuProvider.state == TamuListState.error) {
        _errorMessage = tamuProvider.errorMessage;
      } else {
        _tamus = tamuProvider.tamuList;
      }
    });
  }

  List<TamuModel> get _filteredTamus {
    return _tamus.where((tamu) {
      final bool isMasuk = tamu.status == 'masuk';

      // Filter tanggal (Tamu yang masih masuk selalu ditampilkan)
      if (!_showAllDates && !isMasuk) {
        final masuk  = tamu.waktuMasuk.toLocal();
        final keluar = tamu.waktuKeluar?.toLocal() ?? masuk;

        final hariMasuk   = DateTime(masuk.year, masuk.month, masuk.day);
        final hariKeluar  = DateTime(keluar.year, keluar.month, keluar.day);
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

  Future<void> _openDetailDialog(TamuModel tamu) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: _DetailTamuDialog(tamu: tamu),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BukuTamuScreen.kBg,
      body: Column(
        children: [
          const TopBarScreen(),

          // ── Bagian atas (tidak ikut scroll) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
            child: Column(
              children: [
                Row(
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
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _buildAllDatesToggle(),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDatePicker(),
                const SizedBox(height: 15),
                _buildSearchAndFilter(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Container putih dengan card yang bisa scroll ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.hardEdge,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          )
                        : _filteredTamus.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people_outline,
                                        size: 64, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Tamu "$_searchQuery" tidak ditemukan.'
                                          : _showAllDates
                                              ? 'Belum ada data tamu.'
                                              : _isToday(_selectedDate)
                                                  ? 'Belum ada tamu hari ini.'
                                                  : 'Tidak ada tamu pada tanggal ini.',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadTamu,
                                child: Scrollbar(
                                  radius: const Radius.circular(10),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: _filteredTamus.length,
                                    itemBuilder: (context, index) =>
                                        _guestCard(_filteredTamus[index]),
                                  ),
                                ),
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDatesToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showAllDates = !_showAllDates),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _showAllDates ? BukuTamuScreen.kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showAllDates ? BukuTamuScreen.kPrimary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showAllDates ? Icons.calendar_view_month : Icons.today,
              size: 15,
              color: _showAllDates ? Colors.white : BukuTamuScreen.kPrimary,
            ),
            const SizedBox(width: 5),
            Text(
              _showAllDates ? 'Semua Hari' : 'Hari Ini',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _showAllDates ? Colors.white : BukuTamuScreen.kPrimary,
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Masukkan nama tamu',
                hintStyle: const TextStyle(fontSize: 13),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
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

        PopupMenuButton<String>(
          onSelected: (val) => setState(() => _filterStatus = val),
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            _popupItem('semua', 'Semua', Icons.people_outline, Colors.grey),
            _popupItem('masuk', 'Masuk', Icons.login, const Color(0xFF034DC0)),
            _popupItem('keluar', 'Keluar', Icons.logout, const Color(0xFF2EB24F)),
          ],
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isFiltered
                      ? BukuTamuScreen.kPrimary.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isFiltered
                        ? BukuTamuScreen.kPrimary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: isFiltered ? BukuTamuScreen.kPrimary : Colors.grey,
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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

    final days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    final months = [
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
          child: const Icon(Icons.calendar_today, color: BukuTamuScreen.kPrimary),
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
                style: const TextStyle(fontSize: 10, color: Colors.grey),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    color: _showAllDates ? Colors.grey : Colors.black87,
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

  Widget _guestCard(TamuModel tamu) {
    final waktuMasuk = _formatTimeWithDate(tamu.waktuMasuk.toLocal());
    final waktuKeluar = tamu.waktuKeluar != null
        ? _formatTimeWithDate(tamu.waktuKeluar!.toLocal())
        : '--:--';
    final isKeluar = tamu.status == 'keluar';
    final isBelumKeluar = !isKeluar;
    final hasWaktuKeluar = tamu.waktuKeluar != null;
    final isOvertime = isBelumKeluar && hasWaktuKeluar && DateTime.now().isAfter(tamu.waktuKeluar!.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _openDetailDialog(tamu),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isOvertime ? Colors.red.shade300 : Colors.grey.shade200,
                width: isOvertime ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              tamu.nama,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOvertime) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: const Text(
                                'OVERTIME!',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isKeluar
                            ? const Color(0xFFC8E6C9)
                            : const Color(0xFFBBDEFB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isKeluar ? 'Keluar' : 'Masuk',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(text: 'Masuk $waktuMasuk | '),
                      TextSpan(
                        text: 'Keluar $waktuKeluar',
                        style: TextStyle(
                          color: (!hasWaktuKeluar || isOvertime) ? Colors.red : Colors.grey,
                          fontWeight: (!hasWaktuKeluar || isOvertime) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeWithDate(DateTime dateTime) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month $hh.$mm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailTamuDialog — view-only (warga tidak bisa ubah status)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailTamuDialog extends StatelessWidget {
  const _DetailTamuDialog({required this.tamu});

  final TamuModel tamu;

  String? _resolveFotoUrl(String? fotoTamu) {
  if (fotoTamu == null || fotoTamu.trim().isEmpty) return null;

  String resolved = fotoTamu
        .replaceAll('http://127.0.0.1:54321', AppConfig.supabaseUrl)
        .replaceAll('http://localhost:54321', AppConfig.supabaseUrl);

    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return resolved;
    }

    final cleaned = resolved.startsWith('/') ? resolved.substring(1) : resolved;
    return '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.supabaseBucket}/$cleaned';
  }

  // Format waktu dengan tanggal — sama seperti DetailTamuDialog petugas
  String _formatDateTime(DateTime dt) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${bulan[dt.month]} ${dt.year}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl      = _resolveFotoUrl(tamu.fotoTamu);
    final sudahKeluar  = tamu.status == 'keluar';
    final isEstimasi   = !sudahKeluar && tamu.waktuKeluar != null;

    final status         = sudahKeluar ? 'Keluar' : 'Masuk';
    final statusBgColor  = sudahKeluar ? const Color(0xFFC8E6C9) : const Color(0xFFBBDEFB);
    final statusTextColor = sudahKeluar ? const Color(0xFF2EB24F) : const Color(0xFF034DC0);

    final waktuMasukStr = _formatDateTime(tamu.waktuMasuk.toLocal());

    final waktuKeluarStr = sudahKeluar && tamu.waktuKeluar != null
        ? _formatDateTime(tamu.waktuKeluar!.toLocal())
        : '-';

    final estimasiStr = isEstimasi
        ? _formatDateTime(tamu.waktuKeluar!.toLocal())
        : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ──
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Informasi Tamu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE85C5C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Foto + Info ──
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 150,
                      height: 190,
                      child: fotoUrl == null
                          ? Container(
                              color: const Color(0xFFF0F0F0),
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined,
                                    size: 44, color: Colors.grey),
                              ),
                            )
                          : Image.network(
                              fotoUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: const Color(0xFFF0F0F0),
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF0F0F0),
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      size: 44, color: Colors.grey),
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: statusTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _infoRow(Icons.person, tamu.nama),
                        const SizedBox(height: 6),
                        _infoRow(Icons.description_outlined, tamu.keperluan),
                        const SizedBox(height: 6),
                        _infoRow(Icons.home_outlined, tamu.alamat),
                        const SizedBox(height: 6),
                        _infoRow(Icons.badge_outlined, tamu.namaUser),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 8),

            // ── Waktu (dengan tanggal + estimasi jika belum keluar) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _timelineItem(
                  label: 'Masuk',
                  value: waktuMasukStr,
                  color: const Color(0xFF2EB24F),
                ),
                const SizedBox(height: 6),

                // Estimasi keluar (kuning) — hanya jika status masih masuk
                if (estimasiStr != null) ...[
                  _timelineItem(
                    label: 'Estimasi Keluar',
                    value: estimasiStr,
                    color: const Color(0xFFFF8F00),
                  ),
                  const SizedBox(height: 6),
                ],

                // Waktu keluar aktual (merah) — hanya jika sudah keluar
                if (sudahKeluar)
                  _timelineItem(
                    label: 'Keluar',
                    value: waktuKeluarStr,
                    color: const Color(0xFFE53935),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13), softWrap: true),
        ),
      ],
    );
  }

  Widget _timelineItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.access_time, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatTimeValue(DateTime dateTime) {
  final hh = dateTime.hour.toString().padLeft(2, '0');
  final mm = dateTime.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}