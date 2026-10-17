import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../models/kost_model.dart';

// Import file pencarian & hasil
import 'pencarian_page.dart';
import 'hasil_pencarian.dart';
// Import file kost
import '../kost/detail_kost_page.dart';
// Import file chatUser & profil (PUNYA SALSA)
import '../chatUser/daftar_chat_page.dart';
import '../chatUser/profil_page.dart';

// ========================================
// HALAMAN HOME (TERINTEGRASI SUPABASE)
// ========================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  int _selectedIndex = 0;
  
  // Variabel buat nyimpen nama user di beranda
  String namaUser = "Memuat..."; 

  @override
  void initState() {
    super.initState();
    _loadNamaUser(); // Panggil fungsi narik nama pas home dibuka
  }

  // LOGIKA NARIK NAMA LANGSUNG DARI TABEL 'mahasiswa'
  Future<void> _loadNamaUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        String userName = 'Pengguna KostRadar';

        try {
          final data = await supabase
              .from('mahasiswa') // <-- Mengarah ke tabel mahasiswa
              .select('nama')
              .eq('id', user.id)
              .maybeSingle();

          if (data != null && data['nama'] != null) {
            userName = data['nama'];
          } else if (user.userMetadata != null && user.userMetadata!['nama'] != null) {
            userName = user.userMetadata!['nama'];
          }
        } catch (dbError) {
          if (user.userMetadata != null && user.userMetadata!['nama'] != null) {
            userName = user.userMetadata!['nama'];
          }
        }

        if (mounted) {
          setState(() {
            namaUser = userName;
          });
        }
      } else {
        if (mounted) setState(() => namaUser = 'Pengguna KostRadar');
      }
    } catch (e) {
      if (mounted) setState(() => namaUser = 'Pengguna KostRadar');
    }
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PencarianPage()),
    );
  }

  void _openAllResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HasilPencarianPage()),
    );
  }

  void _openDetail(KostModel kost) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailKostPage(kost: kost),
      ),
    );
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            // TAB 0: BERANDA
            _buildBerandaTab(),
            // TAB 1: FAVORIT
            _buildFavoritTab(),
            // TAB 2: CHAT (PUNYA SALSA)
            const DaftarChatPage(),
            // TAB 3: PROFIL (PUNYA SALSA)
            const ProfilPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // ========================================
  // TAB BERANDA (AMBIL DATA DARI SUPABASE)
  // ========================================
  Widget _buildBerandaTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('kost').select('*, foto_kost(*), fasilitas_kost(*)'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
        }
        final rawData = snapshot.data ?? [];
        final List<KostModel> listKost = rawData.map((e) => KostModel.fromJson(e)).toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 20),
            _buildHeader(), // <-- NAMA DI HEADER UDAH OTOMATIS SESUAI AKUN
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildBanner(),
            const SizedBox(height: 24),
            _buildSectionHeader('Rekomendasi Kost', true),
            const SizedBox(height: 16),
            if (listKost.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Belum ada kost tersedia',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ...listKost.map((kost) => _buildKostCard(kost)),
          ],
        );
      },
    );
  }

  // ========================================
  // TAB FAVORIT (AMBIL DARI TABEL FAVORITE)
  // ========================================
  Widget _buildFavoritTab() {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Silakan login untuk melihat kost favorit',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase
          .from('favorite')
          .select('id_kost, kost(*, foto_kost(*), fasilitas_kost(*))')
          .eq('id_user', user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat favorit: ${snapshot.error}'));
        }
        final rawData = snapshot.data ?? [];
        final List<KostModel> listKostFavorites = rawData
            .where((item) => item['kost'] != null)
            .map((item) => KostModel.fromJson(item['kost']))
            .toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 20),
            _buildSectionHeader('Kost Favorit', false),
            const SizedBox(height: 16),
            if (listKostFavorites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Belum ada kost favorit',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ...listKostFavorites.map((kost) => _buildKostCard(kost)),
          ],
        );
      },
    );
  }

  // ========================================
  // WIDGET-WIDGET PEMBANTU
  // ========================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat datang kembali,',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  namaUser, // <-- NAMA AKUN MUNCUL DI SINI
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Belum ada notifikasi')),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _openSearch,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text(
                      'Cari kost impianmu...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _openSearch,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.filter_list, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
          ),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'KOSTRADAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Temukan Kost Impianmu!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cari kost nyaman dengan harga terbaik.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool showSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: _openAllResults,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKostCard(KostModel kost) {
    final imageUrl = kost.foto.isNotEmpty ? kost.foto[0] : '';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: AppColors.primaryLight,
                    child: const Center(
                      child: Icon(
                        Icons.home_work,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              if (kost.terverifikasi)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✓ Terverifikasi',
                      style: TextStyle(color: AppColors.white, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kost.nama,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rp ${_formatRupiah(kost.harga)} /bulan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        kost.alamat,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kost.fasilitas
                      .map(
                        (facility) => Chip(
                          label: Text(
                            facility,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          backgroundColor: AppColors.primaryLight,
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 9, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tersedia ${kost.ketersediaanKamar} kamar',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openDetail(kost),
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text(
                        'Detail',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}