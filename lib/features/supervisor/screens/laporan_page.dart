import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/laporan_provider.dart';
import '../models/laporan_model.dart';
import 'laporan_harian_page.dart';
import 'widgets/aegis_top_header.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  late LaporanProvider _provider;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = LaporanProvider(
        token: context.read<AuthProvider>().token ?? '',
      );
      _provider.initAll();
      setState(() {});
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return months[month - 1];
  }

  /// "2026-04-14" → "14 April\n2026"
  String _formatTanggalCard(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day} ${_getMonthName(d.month)}\n${d.year}';
    } catch (_) {
      return iso;
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Jika provider belum siap (initState belum selesai)
    if (!mounted || _selectedDate == null && _provider == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4F0FB),
        body: SafeArea(
          child: Consumer<LaporanProvider>(
            builder: (context, prov, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AegisTopHeader(),
                  _buildTitleBar(context),

                  // ── Minggu Ini ──────────────────────────────
                  _buildSectionTitle('Minggu Ini'),
                  Expanded(
                    child: _buildMingguIniList(prov),
                  ),

                  // ── Riwayat Laporan ─────────────────────────
                  _buildSectionTitle('Riwayat Laporan'),
                  _buildSearchBar(context, prov),
                  Expanded(
                    child: _buildRiwayatList(prov),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 16),
          const Text(
            'Laporan Patroli',
            style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Minggu Ini List ───────────────────────────────────────────────────────

  Widget _buildMingguIniList(LaporanProvider prov) {
    if (prov.loadingMingguIni) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.errorMingguIni != null) {
      return _buildError(prov.errorMingguIni!, prov.fetchMingguIni);
    }
    if (prov.mingguIniList.isEmpty) {
      return _buildEmpty('Tidak ada laporan minggu ini');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: prov.mingguIniList.length,
      itemBuilder: (context, index) =>
          _buildReportCard(prov.mingguIniList[index]),
    );
  }

  // ─── Riwayat List ──────────────────────────────────────────────────────────

  Widget _buildRiwayatList(LaporanProvider prov) {
    if (prov.loadingRiwayat && prov.riwayatList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.errorRiwayat != null && prov.riwayatList.isEmpty) {
      return _buildError(prov.errorRiwayat!, prov.fetchRiwayat);
    }
    if (prov.riwayatList.isEmpty) {
      return _buildEmpty('Tidak ada riwayat laporan');
    }

    return NotificationListener<ScrollNotification>(
      // Infinite scroll: load more saat hampir di ujung bawah
      onNotification: (scroll) {
        if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200 &&
            prov.hasNextPage &&
            !prov.loadingRiwayat) {
          prov.loadMoreRiwayat();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: prov.riwayatList.length + (prov.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator di bagian bawah list
          if (index == prov.riwayatList.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildReportCard(prov.riwayatList[index]);
        },
      ),
    );
  }

  // ─── Search Bar (Date Picker) ──────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context, LaporanProvider prov) {
    return GestureDetector(
      onTap: () => _showDatePickerBottomSheet(context, prov),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined,
                color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Cari Tanggal'
                    : '${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}',
                style: TextStyle(
                  color: _selectedDate == null
                      ? Colors.grey.shade500
                      : Colors.black87,
                  fontWeight: _selectedDate == null
                      ? FontWeight.normal
                      : FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            // Tombol reset filter
            if (_selectedDate != null)
              GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = null);
                  prov.clearFilter();
                },
                child: Icon(Icons.close,
                    size: 18, color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Report Card ───────────────────────────────────────────────────────────

  Widget _buildReportCard(LaporanHarianRingkasan data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaporanHarianPage(
              tanggal: data.tanggal, // kirim format "Y-m-d"
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Kotak Tanggal ──
            Container(
              width: 85,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.hari,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTanggalCard(data.tanggal),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 11, height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // ── Statistik ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  children: [
                    _buildStatRow(
                      Icons.check_circle_outline,
                      'Total Patroli',
                      data.totalPatroli,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      Icons.person_outline,
                      'Petugas',
                      data.totalPetugas,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      Icons.location_on_outlined,
                      'Total Checkpoint',
                      data.totalCheckpoint,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ─── Date Picker Bottom Sheet ──────────────────────────────────────────────

  void _showDatePickerBottomSheet(BuildContext context, LaporanProvider prov) {
    DateTime tempSelectedDate = _selectedDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builderContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Pilih Tanggal',
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CalendarDatePicker(
                    initialDate: tempSelectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    onDateChanged: (DateTime newDate) {
                      setModalState(() => tempSelectedDate = newDate);
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Colors.white, size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TERPILIH',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${tempSelectedDate.day} '
                                  '${_getMonthName(tempSelectedDate.month)} '
                                  '${tempSelectedDate.year}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final tglStr = tempSelectedDate
                              .toIso8601String()
                              .split('T')[0]; // "Y-m-d"

                          setState(() => _selectedDate = tempSelectedDate);
                          prov.setFilterTanggal(tglStr);
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Tampilkan Laporan',
                          style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Helpers UI ────────────────────────────────────────────────────────────

  Widget _buildError(String msg, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(msg,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}