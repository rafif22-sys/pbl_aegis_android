import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/aegis_top_header.dart';

class CheckpointData {
  final String title;
  final String time;
  final String condition;
  final String note;
  final List<String> imageUrls;

  CheckpointData({
    required this.title,
    required this.time,
    required this.condition,
    required this.note,
    required this.imageUrls,
  });
}

class DetailPatroliPage extends StatefulWidget {
  final String idJadwalAbsensi;
  final String namaPetugas;

  const DetailPatroliPage({super.key, required this.idJadwalAbsensi, required this.namaPetugas});

  @override
  State<DetailPatroliPage> createState() => _DetailPatroliPageState();
}

class _DetailPatroliPageState extends State<DetailPatroliPage> {
  bool _isLoading = true;
  List<CheckpointData> checkpoints = [];
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchDetailPatroli();
  }

  Future<void> _fetchDetailPatroli() async {
    setState(() => _isLoading = true);
    
    try {
      final List<dynamic> data = await supabase
          .from('laporan_checkpoint')
          .select()
          .eq('id_jadwal_absensi', widget.idJadwalAbsensi)
          .order('waktu_laporan', ascending: true); // Urut dari checkpoint pertama

      checkpoints = data.map((row) {
        DateTime waktu = DateTime.parse(row['waktu_laporan'] ?? row['created_at']);
        String jam = '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}';
        
        // Handle foto bukti (bisa null)
        List<String> fotos = [];
        if (row['foto_bukti'] != null && row['foto_bukti'].toString().isNotEmpty) {
          fotos.add(row['foto_bukti'].toString());
        } else {
          // Placeholder kalau petugas ngga upload foto
          fotos.add('https://images.unsplash.com/photo-1555861496-faa3eaf591fc?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'); 
        }

        return CheckpointData(
          title: 'Titik ${row['point'] ?? '-'}',
          time: jam,
          condition: row['kondisi'] ?? 'Aman',
          note: row['catatan'] ?? 'Tidak ada catatan.',
          imageUrls: fotos,
        );
      }).toList();

    } catch (e) {
      debugPrint("Error fetching detail: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade300,
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'), 
                  fit: BoxFit.cover,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
                : checkpoints.isEmpty 
                  ? const Center(child: Text("Belum ada data checkpoint.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 30), 
                      itemCount: checkpoints.length,
                      itemBuilder: (context, index) {
                        return _buildCheckpointCard(context, checkpoints[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, size: 28, color: Colors.black)),
          const SizedBox(width: 16),
          CircleAvatar(radius: 18, backgroundColor: Colors.grey.shade300),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Petugas', style: TextStyle(fontSize: 14, color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
              Text(widget.namaPetugas, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointCard(BuildContext context, CheckpointData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Text('Waktu: ${data.time}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 4),
                Text('Kondisi: ${data.condition}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Catatan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text(data.note, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          GestureDetector(
            onTap: () => _showImageDialog(context, data.imageUrls),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: NetworkImage(data.imageUrls[0]), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: data.imageUrls.length > 1 
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomRight: Radius.circular(12))),
                        child: Text('+${data.imageUrls.length - 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ) 
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, List<String> imageUrls) {
    PageController pageController = PageController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            int currentIndex = pageController.hasClients ? pageController.page?.round() ?? 0 : 0;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, size: 24)),
                        const SizedBox(width: 12),
                        const Text('Foto Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 400, 
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: PageView.builder(
                          controller: pageController,
                          itemCount: imageUrls.length,
                          onPageChanged: (index) => setStateDialog(() {}),
                          itemBuilder: (context, index) {
                            return Image.network(imageUrls[index], fit: BoxFit.cover);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (imageUrls.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, color: currentIndex > 0 ? Colors.black : Colors.grey),
                            onPressed: () {
                              if (currentIndex > 0) pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            },
                          ),
                          Text('${currentIndex + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios, color: currentIndex < imageUrls.length - 1 ? Colors.black : Colors.grey),
                            onPressed: () {
                              if (currentIndex < imageUrls.length - 1) pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}