import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../petugas/providers/tamu_provider.dart';
import '../../petugas/models/tamu_model.dart';
import 'widgets/aegis_top_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../petugas/screens/widgets/buku_tamu/guest_card.dart';
import '../../petugas/screens/widgets/buku_tamu/detail_tamu_dialog.dart';

class BukuTamuPage extends StatefulWidget {
  const BukuTamuPage({super.key});

  @override
  State<BukuTamuPage> createState() => _BukuTamuPageState();
}

class _BukuTamuPageState extends State<BukuTamuPage> {
  final ScrollController _scrollController = ScrollController(); 
  
  bool _isLoading = true;
  String? _errorMessage;
  List<TamuModel> _tamus = [];
  
  DateTime _selectedDate = DateTime.now();
  bool _showAllDates = false;
  String _searchQuery = '';
  String _filterStatus = 'semua';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTamu();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  List<TamuModel> get _filteredTamus {
    return _tamus.where((tamu) {
      final bool isMasuk = (tamu.status ?? '').toLowerCase() == 'masuk';

      if (!_showAllDates && !isMasuk) {
        final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        final masuk = tamu.waktuMasuk.toLocal();
        final startDate = DateTime(masuk.year, masuk.month, masuk.day);
        
        DateTime endDate = DateTime(2100); 
        if (tamu.waktuKeluar != null) {
          final keluar = tamu.waktuKeluar!.toLocal();
          endDate = DateTime(keluar.year, keluar.month, keluar.day);
        }

        if (target.isBefore(startDate) || target.isAfter(endDate)) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty &&
          !(tamu.nama).toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      if (_filterStatus != 'semua' && (tamu.status ?? '').toLowerCase() != _filterStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  String _formatTanggalJam(DateTime waktu) {
    final local = waktu.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final day = local.day;
    final month = months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$day $month $hour:$min';
  }

  void _openDetailDialog(TamuModel tamu) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: DetailTamuDialog(
          tamu: tamu,
          // KUNCI: Isi onKeluar dengan null, agar tombol hilang!
          onKeluar: null, 
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13), softWrap: true)),
      ],
    );
  }

  Widget _buildTimelineItem({required String label, required String value, required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.access_time, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEFFE),
      body: SafeArea(
        child: Column(
          children: [
            const AegisTopHeader(),
            _buildTitleBar(context),
            _buildDateFilter(),
            const SizedBox(height: 16),
            _buildSearchAndFilter(),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: RefreshIndicator(onRefresh: _loadTamu, color: const Color(0xFF0D47A1), child: _buildContent()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, size: 28, color: Colors.black)),
          const SizedBox(width: 16),
          const Text('Buku Tamu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showAllDates = !_showAllDates),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: _showAllDates ? const Color(0xFF0D47A1) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _showAllDates ? const Color(0xFF0D47A1) : Colors.grey.shade300)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_showAllDates ? Icons.grid_view_rounded : Icons.calendar_today, size: 14, color: _showAllDates ? Colors.white : const Color(0xFF0D47A1)),
                  const SizedBox(width: 6),
                  Text(_showAllDates ? 'Semua Hari' : 'Hari Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _showAllDates ? Colors.white : const Color(0xFF0D47A1))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateFilter() {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFBBE1FA), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.calendar_today, color: Color(0xFF0D47A1), size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_showAllDates ? 'SEMUA HARI' : (isToday ? 'HARI INI' : 'TANGGAL DIPILIH'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(_showAllDates ? 'Menampilkan semua data' : '${days[_selectedDate.weekday - 1]}, ${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black), overflow: TextOverflow.ellipsis),
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
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final isFiltered = _filterStatus != 'semua';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _searchCtrl, onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(hintText: 'Cari nama tamu...', hintStyle: const TextStyle(color: Colors.black38, fontSize: 13), prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20), suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => _filterStatus = val), offset: const Offset(0, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              _buildPopupItem('semua', 'Semua', Icons.people_outline, Colors.grey),
              _buildPopupItem('masuk', 'Masuk', Icons.login, const Color(0xFF034DC0)),
              _buildPopupItem('keluar', 'Keluar', Icons.logout, const Color(0xFF2EB24F)),
            ],
            child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: isFiltered ? const Color(0xFFE4F1FF) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isFiltered ? const Color(0xFF0D47A1) : Colors.transparent)), child: Icon(Icons.tune, color: isFiltered ? const Color(0xFF0D47A1) : Colors.black54)),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String label, IconData icon, Color color) {
    final isSelected = _filterStatus == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.black87)),
          if (isSelected) ...[const Spacer(), Icon(Icons.check, size: 16, color: color)],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)));
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)));
    final filtered = _filteredTamus;
    if (filtered.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.people_outline, size: 48, color: Colors.grey), const SizedBox(height: 12), Text(_searchQuery.isNotEmpty ? 'Tamu "$_searchQuery" tidak ditemukan.' : 'Belum ada data tamu.', style: const TextStyle(color: Colors.grey, fontSize: 13))]));
    return Scrollbar(controller: _scrollController, thumbVisibility: true, thickness: 6.0, radius: const Radius.circular(10), interactive: true, child: ListView.builder(controller: _scrollController, physics: const AlwaysScrollableScrollPhysics(), itemCount: filtered.length, itemBuilder: (context, index) { return _buildTamuCard(filtered[index]); }));
  }

  Widget _buildTamuCard(TamuModel tamu) {
    String statusAman = tamu.status ?? 'MASUK'; 
    bool isKeluar = statusAman.toLowerCase() == 'keluar';
    bool isBelumKeluar = !isKeluar;
    bool hasWaktuKeluar = tamu.waktuKeluar != null;

    bool isOvertime = isBelumKeluar && hasWaktuKeluar && DateTime.now().isAfter(tamu.waktuKeluar!);

    String masukStr = _formatTanggalJam(tamu.waktuMasuk);
    String keluarStr = hasWaktuKeluar ? _formatTanggalJam(tamu.waktuKeluar!) : '--:--';

    return InkWell(
      onTap: () => _openDetailDialog(tamu), 
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOvertime ? Colors.red.shade300 : Colors.grey.shade200,
            width: isOvertime ? 1.5 : 1.0, 
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
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
                        child: Text(tamu.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (isOvertime) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.shade300)),
                          child: const Text('OVERTIME!', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isKeluar ? const Color(0xFFE8F5E9) : const Color(0xFFE4F0FB), borderRadius: BorderRadius.circular(12)),
                  child: Text(isKeluar ? 'Keluar' : 'Masuk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isKeluar ? const Color(0xFF2E7D32) : const Color(0xFF034DC0))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(text: 'Masuk $masukStr | '),
                  TextSpan(
                    text: 'Keluar $keluarStr',
                    style: TextStyle(color: (!hasWaktuKeluar || isOvertime) ? Colors.red : Colors.grey, fontWeight: (!hasWaktuKeluar || isOvertime) ? FontWeight.bold : FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}