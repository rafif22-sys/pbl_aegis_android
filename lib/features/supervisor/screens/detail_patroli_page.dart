import 'package:flutter/material.dart';
import 'widgets/aegis_top_header.dart';

// --- KELAS DATA DUMMY CHECKPOINT ---
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

class DetailPatroliPage extends StatelessWidget {
  final String namaPetugas;

  DetailPatroliPage({super.key, required this.namaPetugas});

  // Data Dummy untuk List Titik Checkpoint (Dibuat sampai 5 agar bisa discroll)
  final List<CheckpointData> checkpoints = [
    CheckpointData(
      title: 'Titik 1',
      time: '07.30',
      condition: 'Aman',
      note: 'Keadaan aman dan gembok terpasang',
      imageUrls: ['https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'],
    ),
    CheckpointData(
      title: 'Titik 2',
      time: '08.30',
      condition: 'Aman',
      note: 'Keadaan aman dan gembok terpasang',
      imageUrls: [
        'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
      ],
    ),
    CheckpointData(
      title: 'Titik 3',
      time: '09.00',
      condition: 'Terdapat Isu',
      note: 'Ada coretan di dinding belakang',
      imageUrls: ['https://images.unsplash.com/photo-1515263487990-61b07816b324?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'],
    ),
    CheckpointData(
      title: 'Titik 4',
      time: '09.45',
      condition: 'Aman',
      note: 'Pintu gerbang samping terkunci rapat',
      imageUrls: ['https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'],
    ),
    CheckpointData(
      title: 'Titik 5',
      time: '10.30',
      condition: 'Aman',
      note: 'Patroli selesai, semua area terpantau aman',
      imageUrls: ['https://images.unsplash.com/photo-1497366216548-37526070297c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F0FB), // Background biru muda
      body: SafeArea(
        child: Column( // Bagian utama tetap Column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AegisTopHeader(),
            
            // --- BAGIAN FIXED (TIDAK IKUT DI-SCROLL) ---
            _buildTitleBar(context),
            
            // Peta Rute Patroli
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade300,
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'), // Placeholder Peta
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- BAGIAN LIST YANG BISA DI-SCROLL ---
            // Menggunakan Expanded agar list mengambil sisa layar di bawah peta
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 30), // Beri jarak bawah agar tidak mentok
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

  // --- WIDGET JUDUL & NAMA PETUGAS ---
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
          CircleAvatar(radius: 18, backgroundColor: Colors.grey.shade300),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Petugas', style: TextStyle(fontSize: 14, color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
              Text(namaPetugas, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET KARTU TITIK CHECKPOINT ---
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
          // Bagian Teks (Kiri)
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
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
          
          // Bagian Thumbnail Foto (Kanan)
          GestureDetector(
            onTap: () => _showImageDialog(context, data.imageUrls),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(data.imageUrls[0]), 
                  fit: BoxFit.cover,
                ),
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

  // --- LOGIKA POP-UP FOTO (LIGHTBOX) ---
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
                          onPageChanged: (index) {
                            setStateDialog(() {}); 
                          },
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
                              if (currentIndex > 0) {
                                pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              }
                            },
                          ),
                          Text('${currentIndex + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios, color: currentIndex < imageUrls.length - 1 ? Colors.black : Colors.grey),
                            onPressed: () {
                              if (currentIndex < imageUrls.length - 1) {
                                pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              }
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