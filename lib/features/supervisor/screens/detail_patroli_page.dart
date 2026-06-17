import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/config/app_config.dart';
import '../models/laporan_model.dart';
import 'widgets/aegis_top_header.dart';

class DetailPatroliPage extends StatefulWidget {
  final DetailPetugas petugasData;

  const DetailPatroliPage({super.key, required this.petugasData});

  @override
  State<DetailPatroliPage> createState() => _DetailPatroliPageState();
}

class _DetailPatroliPageState extends State<DetailPatroliPage> {
  late final MapController _mapController;

  List<LatLng> _osrmRoute = [];
  bool _loadingRoute = false;
  int? _highlightedIndex;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchOsrmRoute();
  }

  // ── Koordinat Valid ───────────────────────────────────────────────────
  List<DetailCheckpoint> get _checkpointsWithCoords =>
      widget.petugasData.checkpoints
          .where((c) => c.latitude != null && c.longitude != null)
          .toList();

  LatLng get _mapCenter {
    final pts = _checkpointsWithCoords;
    if (pts.isEmpty) return const LatLng(-6.2, 106.8);
    final lat = pts.map((c) => c.latitude!).reduce((a, b) => a + b) / pts.length;
    final lng = pts.map((c) => c.longitude!).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }

  // ── OSRM: Rute Mengikuti Jalan ────────────────────────────────────────
  Future<void> _fetchOsrmRoute() async {
    final pts = _checkpointsWithCoords;
    if (pts.length < 2) return;

    setState(() => _loadingRoute = true);

    try {
      final coords = pts.map((c) => '${c.longitude!},${c.latitude!}').join(';');
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$coords'
        '?geometries=geojson&overview=full',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = body['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as Map<String, dynamic>;
          final rawCoords = geometry['coordinates'] as List;

          final routePoints = rawCoords
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();

          if (mounted) setState(() => _osrmRoute = routePoints);
        }
      } else {
        debugPrint('OSRM Error: Status Code ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal memuat rute OSRM: $e');
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  String _buildStorageUrl(String path) {
    String cleanPath = path.trim();
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    return '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.supabaseBucket}/$cleanPath';
  }

  // ── Warna Marker ──────────────────────────────────────────────────────
  Color _markerColor(String kondisi) {
    return kondisi.trim().toLowerCase() == 'aman'
        ? const Color(0xFF1565C0)
        : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AegisTopHeader(),
            _buildTitleBar(context),
            _buildMap(),
            const SizedBox(height: 6),
            _buildLegend(),
            const SizedBox(height: 6),
            Expanded(
              child: widget.petugasData.checkpoints.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_off_rounded,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Belum ada checkpoint dilaporkan',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 30),
                      itemCount: widget.petugasData.checkpoints.length,
                      itemBuilder: (_, i) => _buildCheckpointCard(
                        context,
                        widget.petugasData.checkpoints[i],
                        i,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    final foto = widget.petugasData.petugas.fotoProfil;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade900,
            backgroundImage: foto != null && foto.isNotEmpty
                ? NetworkImage(_buildStorageUrl(foto))
                : null,
            child: foto == null || foto.isEmpty
                ? const Icon(Icons.person, size: 22, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.petugasData.posJaga,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.petugasData.petugas.nama,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.petugasData.shift,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final checkpoints = _checkpointsWithCoords;

    final polylinePoints = _osrmRoute.isNotEmpty
        ? _osrmRoute
        : checkpoints.map((c) => LatLng(c.latitude!, c.longitude!)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: checkpoints.isEmpty
          ? Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Koordinat checkpoint tidak tersedia',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 15.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.android_aegis',
                    ),
                    if (polylinePoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: polylinePoints,
                            color: Colors.blue.shade800,
                            strokeWidth: 4.5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: List.generate(checkpoints.length, (i) {
                        final cp = checkpoints[i];
                        final isHighlighted = _highlightedIndex == i;
                        final color = _markerColor(cp.kondisi);
                        final size = isHighlighted ? 38.0 : 32.0;

                        return Marker(
                          point: LatLng(cp.latitude!, cp.longitude!),
                          width: size,
                          height: size,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _highlightedIndex =
                                    _highlightedIndex == i ? null : i;
                              });
                              _mapController.move(
                                  LatLng(cp.latitude!, cp.longitude!), 17);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white,
                                    width: isHighlighted ? 3 : 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.6),
                                    blurRadius: isHighlighted ? 10 : 5,
                                    spreadRadius: isHighlighted ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isHighlighted ? 15 : 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                if (_loadingRoute)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue.shade900),
                            ),
                            const SizedBox(width: 8),
                            const Text('Memuat rute...',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _mapController.move(_mapCenter, 15.5),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4),
                        ],
                      ),
                      child: Icon(Icons.center_focus_strong,
                          size: 20, color: Colors.blue.shade900),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _legendItem(const Color(0xFF1565C0), 'Aman'),
          const SizedBox(width: 16),
          _legendItem(Colors.red, 'Terdapat Isu'),
          const Spacer(),
          if (_osrmRoute.isNotEmpty)
            const Row(
              children: [
                Icon(Icons.alt_route, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text('Rute jalan aktual',
                    style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const Center(
            child: Text('n',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _buildCheckpointCard(
      BuildContext context, DetailCheckpoint checkpoint, int index) {
    final isAman = checkpoint.kondisi.trim().toLowerCase() == 'aman';
    final markerColor = _markerColor(checkpoint.kondisi);
    final isHighlighted = _highlightedIndex == index;

    final List<String> fotoUrls = checkpoint.fotoBukti
        .map((path) => _buildStorageUrl(path))
        .toList();

    return GestureDetector(
      onTap: () {
        if (checkpoint.latitude != null && checkpoint.longitude != null) {
          setState(() => _highlightedIndex = index);
          _mapController.move(
              LatLng(checkpoint.latitude!, checkpoint.longitude!), 17);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? markerColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? markerColor.withOpacity(0.18)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isHighlighted ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header Card ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: markerColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: markerColor.withOpacity(0.4),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      checkpoint.namaCheckpoint,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: markerColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAman ? 'Aman' : 'Terdapat Isu',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body Card ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Waktu
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        checkpoint.waktuLaporan != null
                            ? 'Pukul ${checkpoint.waktuLaporan}'
                            : 'Waktu tidak tercatat',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Catatan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Catatan',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black38)),
                        const SizedBox(height: 3),
                        Text(
                          checkpoint.catatan?.isNotEmpty == true
                              ? checkpoint.catatan!
                              : 'Tidak ada catatan',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Foto Bukti Strip ──────────────────────────────────
                  // Gunakan _FotoStrip agar foto yang tidak exist
                  // otomatis disembunyikan, dan jumlah label akurat.
                  _FotoStrip(
                    fotoUrls: fotoUrls,
                    onTap: (validIndex, validUrls) {
                      _showImageDialog(context, validUrls,
                          initialIndex: validIndex);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog Fullscreen Foto ────────────────────────────────────────────
  void _showImageDialog(BuildContext context, List<String> imageUrls,
      {int initialIndex = 0}) {
    final pageController = PageController(initialPage: initialIndex);
    // currentIndex dideklarasikan di luar builder agar nilainya
    // tidak direset setiap kali StatefulBuilder rebuild.
    int currentIndex = initialIndex;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          imageUrls.length > 1
                              ? 'Foto Bukti (${currentIndex + 1} / ${imageUrls.length})'
                              : 'Foto Bukti',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 360,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: imageUrls.length,
                        onPageChanged: (i) =>
                            setStateDialog(() => currentIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          imageUrls[i],
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                color: Colors.blue.shade700,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Gagal memuat foto',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (imageUrls.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              color: currentIndex > 0
                                  ? Colors.black87
                                  : Colors.grey.shade300),
                          onPressed: currentIndex > 0
                              ? () => pageController.previousPage(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                        // Dot indicators
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            imageUrls.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: i == currentIndex ? 18 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == currentIndex
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios,
                              color: currentIndex < imageUrls.length - 1
                                  ? Colors.black87
                                  : Colors.grey.shade300),
                          onPressed: currentIndex < imageUrls.length - 1
                              ? () => pageController.nextPage(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FotoStrip
//
// Widget strip foto horizontal yang:
//   • Mencoba memuat hingga 6 slot foto (sesuai List fotoUrls dari model)
//   • Slot yang gagal load (foto tidak ada di storage) DISEMBUNYIKAN otomatis
//   • Label "Foto Bukti (N)" menunjukkan jumlah foto yang benar-benar berhasil
//   • Nomor overlay thumbnail dihitung dari foto valid saja
//   • Dialog fullscreen hanya menerima URL foto yang valid
// ─────────────────────────────────────────────────────────────────────────────
class _FotoStrip extends StatefulWidget {
  /// URL lengkap foto (sudah include base Supabase URL), maks 6 item.
  final List<String> fotoUrls;

  /// Callback saat thumbnail ditekan.
  /// [validIndex] = posisi foto di dalam [validUrls].
  /// [validUrls]  = daftar URL yang berhasil dimuat.
  final void Function(int validIndex, List<String> validUrls) onTap;

  const _FotoStrip({required this.fotoUrls, required this.onTap});

  @override
  State<_FotoStrip> createState() => _FotoStripState();
}

class _FotoStripState extends State<_FotoStrip> {
  // null  = belum diketahui (sedang loading)
  // true  = berhasil dimuat
  // false = gagal (foto tidak ada / error)
  late final List<bool?> _status;

  @override
  void initState() {
    super.initState();
    _status = List.filled(widget.fotoUrls.length, null);
  }

  /// Daftar URL yang sudah dikonfirmasi berhasil dimuat.
  List<String> get _validUrls {
    final result = <String>[];
    for (int i = 0; i < widget.fotoUrls.length; i++) {
      if (_status[i] == true) result.add(widget.fotoUrls[i]);
    }
    return result;
  }

  bool get _allChecked => _status.every((s) => s != null);
  bool get _anyValid   => _status.any((s) => s == true);
  int  get _validCount => _status.where((s) => s == true).length;

  @override
  Widget build(BuildContext context) {
    // Jika semua slot sudah dicek dan semuanya gagal → tampilkan placeholder
    if (_allChecked && !_anyValid) {
      return Container(
        width: double.infinity,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported,
                size: 22, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              'Tidak ada foto bukti',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    // Label jumlah foto: "..." saat masih loading, angka saat sudah selesai
    final String labelCount = _allChecked ? '$_validCount' : '…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label header
        Row(
          children: [
            Icon(Icons.photo_library_outlined,
                size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Foto Bukti ($labelCount)',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Strip thumbnail horizontal
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.fotoUrls.length,
            itemBuilder: (_, i) {
              // Sembunyikan slot yang sudah dikonfirmasi gagal
              if (_status[i] == false) return const SizedBox.shrink();

              final isValid = _status[i] == true;

              return GestureDetector(
                onTap: isValid
                    ? () {
                        final valid    = _validUrls;
                        final vidx     = valid.indexOf(widget.fotoUrls[i]);
                        if (vidx >= 0) widget.onTap(vidx, valid);
                      }
                    : null,
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.fotoUrls[i],
                        fit: BoxFit.cover,

                        // frameBuilder dipanggil saat frame pertama berhasil
                        // di-decode → tandai status[i] = true
                        frameBuilder:
                            (_, child, frame, wasSynchronouslyLoaded) {
                          if (frame != null && _status[i] != true) {
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) {
                              if (mounted) setState(() => _status[i] = true);
                            });
                          }
                          return child;
                        },

                        // errorBuilder dipanggil jika foto 404 / gagal fetch
                        // → tandai status[i] = false agar slot hilang
                        errorBuilder: (_, __, ___) {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) {
                            if (mounted) setState(() => _status[i] = false);
                          });
                          // Kembalikan SizedBox kosong; setState di atas akan
                          // rebuild dan slot ini menjadi SizedBox.shrink()
                          return const SizedBox.shrink();
                        },

                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          );
                        },
                      ),

                      // Overlay nomor (hanya tampil jika foto sudah valid)
                      if (isValid)
                        Positioned(
                          bottom: 4,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              // Nomor urut di antara foto valid saja
                              '${_validUrls.indexOf(widget.fotoUrls[i]) + 1}'
                              '/$_validCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}