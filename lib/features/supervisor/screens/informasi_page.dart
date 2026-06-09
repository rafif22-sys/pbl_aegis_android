import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../petugas/providers/pesan_provider.dart';
import 'widgets/aegis_top_header.dart';
import '../../petugas/models/pesan_model.dart';
import '../../petugas/screens/widgets/sos/sos_top_toast.dart';

class InformasiPage extends StatefulWidget {
  const InformasiPage({super.key});

  @override
  State<InformasiPage> createState() => _InformasiPageState();
}

class _InformasiPageState extends State<InformasiPage> {
  // Nilai bisa: 'semua', 'belum_dibaca', 'favorit'
  String _activeFilter = 'semua'; 
  final TextEditingController _pesanCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      
      // --- LOGIKA MENGHAPUS TITIK MERAH (BARU DITAMBAHKAN) ---
      // 1. Hapus titik merah di tampilan (UI)
      context.read<PesanProvider>().clearUnreadCount();
      
      // 2. Beritahu database Laravel (Egie) kalau pesan sudah dibaca
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<PesanProvider>().markAllRead(token: token);
      }
    });
  }

  @override
  void dispose() {
    _pesanCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<PesanProvider>().fetchPesan(token: token, filter: _activeFilter);
    }
  }

  void _changeTab(String filter) {
    if (_activeFilter == filter) return;
    setState(() => _activeFilter = filter);
    _loadData();
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
            const SizedBox(height: 20),
            _buildFilterTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<PesanProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)));
                  }

                  if (provider.pesanList.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada pesan.', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: provider.pesanList.length,
                    itemBuilder: (context, index) {
                      return _buildPesanCard(provider.pesanList[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 8),
        child: FloatingActionButton.extended(
          onPressed: () => _tampilkanDialogKirimPesan(context),
          backgroundColor: const Color(0xFF0D47A1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          icon: const Icon(Icons.send_outlined, color: Colors.white, size: 20),
          label: const Text('Kirim Informasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTabButton('Semua', 'semua'),
          const SizedBox(width: 12),
          _buildTabButton('Belum Dibaca', 'belum_dibaca'),
          const SizedBox(width: 12),
          _buildTabButton('Favorit', 'favorit'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, String filterValue) {
    bool isActive = _activeFilter == filterValue;
    return GestureDetector(
      onTap: () => _changeTab(filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0D47A1) : const Color(0xFFD2E3F4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isActive ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildPesanCard(PesanModel pesan) {
    bool isSos = pesan.content.toLowerCase().contains('sos');
    
    // --- LOGIKA WARNA BADGE ---
    String roleString = pesan.role.toLowerCase();
    Color badgeColor;
    Color badgeBgColor;
    String badgeText;

    if (roleString == 'supervisor') {
      badgeColor = const Color(0xFF673AB7); // Warna Ungu teks & garis
      badgeBgColor = const Color(0xFFF3E5F5); // Warna Ungu pudar latar
      badgeText = 'Supervisor';
    } else {
      badgeColor = const Color(0xFF1976D2); // Warna Biru teks & garis
      badgeBgColor = const Color(0xFFE3F2FD); // Warna Biru pudar latar
      badgeText = 'Admin';
    }

    return GestureDetector(
      onTap: () {
        if (pesan.isUnread) {
          final token = context.read<AuthProvider>().token!;
          context.read<PesanProvider>().markAsReadLocal(pesan.id, _activeFilter);
          context.read<PesanProvider>().markAllRead(token: token); 
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(pesan.sender, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                if (isSos) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, color: Color(0xFFD30000), size: 18),
                ],
                const Spacer(),
                Text(pesan.time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
                const SizedBox(width: 8),
                if (pesan.isUnread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xFFD30000), shape: BoxShape.circle),
                  )
                else
                  const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 8),
            Text(pesan.content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
            const SizedBox(height: 12),
            
            // --- BARIS UNTUK BADGE DAN BINTANG ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge Role
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
                
                // Bintang Favorit
                GestureDetector(
                  onTap: () {
                    final token = context.read<AuthProvider>().token;
                    if (token != null) {
                      context.read<PesanProvider>().toggleFavorit(token: token, pesanId: pesan.id);
                    }
                  },
                  child: Icon(
                    pesan.isStarred ? Icons.star : Icons.star_border,
                    color: pesan.isStarred ? const Color(0xFFFFD700) : Colors.black87,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _tampilkanDialogKirimPesan(BuildContext parentContext) {
    _pesanCtrl.clear();
    bool isSending = false; // Variabel baru untuk efek loading

    showDialog(
      context: parentContext,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext dialogContext) {
        // StatefulBuilder digunakan agar UI di dalam pop-up bisa direfresh (loading)
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Kirim Informasi ke Petugas',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _pesanCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Masukan Informasi untuk semua petugas',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0D47A1))),
                      ),
                      maxLines: 2,
                      enabled: !isSending, // Kunci input teks saat sedang loading mengirim
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD30000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isSending
                              ? null
                              : () async {
                                  if (_pesanCtrl.text.trim().isEmpty) return;

                                  // 1. Ubah status jadi loading
                                  setState(() {
                                    isSending = true;
                                  });

                                  final token = parentContext.read<AuthProvider>().token;
                                  if (token != null) {
                                    // 2. Tembak API
                                    bool success = await parentContext.read<PesanProvider>().kirimPesan(
                                      token: token, 
                                      isiPesan: _pesanCtrl.text.trim()
                                    );
                                    
                                    if (!dialogContext.mounted) return;

                                    // 3. Cek apakah berhasil atau ditolak server
                                    if (success) {
                                      Navigator.pop(dialogContext); // Tutup pop-up
                                      _loadData(); // Refresh daftar pesan
                                      SosTopToast.show(
                                        parentContext,
                                        message: 'Informasi berhasil dikirim!',
                                        backgroundColor: const Color(0xFF1CAF5E),
                                        icon: Icons.check,
                                        iconColor: const Color(0xFF1CAF5E),
                                        iconBackgroundColor: Colors.white,
                                      );
                                    } else {
                                      // Jika gagal, matikan efek loading dan beri tahu pengguna
                                      setState(() {
                                        isSending = false;
                                      });
                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                        const SnackBar(content: Text('Gagal mengirim pesan! Cek koneksi atau server.'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                          icon: isSending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send, size: 18),
                          label: Text(
                            isSending ? 'Mengirim...' : 'Kirim', 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1CAF5E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
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