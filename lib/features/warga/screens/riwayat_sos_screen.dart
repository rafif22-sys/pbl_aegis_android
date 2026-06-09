import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sos/providers/sos_provider.dart';
import '../../petugas/screens/widgets/riwayat_sos/sos_top_header.dart';
import '../../petugas/screens/widgets/riwayat_sos/sos_stat_card.dart';
import '../../petugas/screens/widgets/riwayat_sos/sos_filter_sheet.dart';
import '../../petugas/screens/widgets/riwayat_sos/sos_card.dart';
import '../../petugas/screens/widgets/riwayat_sos/sos_pagination_bar.dart';
import '../../petugas/screens/widgets/riwayat_sos/sos_empty_error.dart';
import 'detail_sos_screen.dart';

class RiwayatSosScreen extends StatefulWidget {
  const RiwayatSosScreen({super.key});

  @override
  State<RiwayatSosScreen> createState() => _RiwayatSosScreenState();
}

class _RiwayatSosScreenState extends State<RiwayatSosScreen> {
  static const int _perPage = 5;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final token = context.read<AuthProvider>().token ?? '';
    await context.read<SosProvider>().fetchListSOS(token: token);
  }

  void _onFilterChanged(SosProvider provider, String? value) {
    provider.setFilter(value);
    setState(() => _currentPage = 1);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEFFE),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: const Color(0xFF0D47A1),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SosTopHeader(),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('SINYAL SOS',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ),
                const SizedBox(height: 16),
                const SosSummaryCards(),
                const SizedBox(height: 32),
                SosDaftarHeader(
                  onFilterTap: () {
                    final provider = context.read<SosProvider>();
                    showSosFilterSheet(context, provider, _onFilterChanged);
                  },
                ),
                const SizedBox(height: 16),
                _buildSosList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSosList() {
    return Consumer<SosProvider>(
      builder: (context, provider, _) {
        if (provider.state == SosListState.loading) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0D47A1))),
          );
        }

        if (provider.state == SosListState.error) {
          return SosErrorState(
              message: provider.errorMessage, onRetry: _fetchData);
        }

        if (provider.sosList.isEmpty) {
          return const SosEmptyState();
        }

        final allList = provider.sosList;
        final totalPages = (allList.length / _perPage).ceil();
        final safePage = _currentPage.clamp(1, totalPages);
        final startIndex = (safePage - 1) * _perPage;
        final endIndex = (startIndex + _perPage).clamp(0, allList.length);
        final pageList = allList.sublist(startIndex, endIndex);

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageList.length,
              itemBuilder: (context, index) => SosCard(
                sos: pageList[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailSosScreen(sos: pageList[index]),
                  ),
                ),
              ),
            ),
            if (totalPages > 1)
              SosPaginationBar(
                currentPage: safePage,
                totalPages: totalPages,
                onPrev: () => setState(() => _currentPage = safePage - 1),
                onNext: () => setState(() => _currentPage = safePage + 1),
              ),
          ],
        );
      },
    );
  }
}
