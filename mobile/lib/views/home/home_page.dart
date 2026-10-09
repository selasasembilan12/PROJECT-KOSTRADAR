import 'package:flutter/material.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';

import 'pencarian_page.dart';
import 'hasil_pencarian.dart';
import '../kost/detail_kost_page.dart';

// ========================================
// HALAMAN HOME
// ========================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final Set<String> _favorites = {'Kost Adiwarna'};

  // Membuka halaman pencarian
  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PencarianPage()),
    );
  }

  // Membuka semua hasil pencarian
  void _openAllResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
    );
  }

  void _openDetail(KostResult kost) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailKostPage(kost: kost.toKostModel()),
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
    final allKost = kostRadarData;

    final displayedKost = _selectedIndex == 1
        ? allKost.where((kost) {
            return _favorites.contains(kost.name);
          }).toList()
        : allKost;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _selectedIndex >= 2
            ? _buildOtherPage()
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _buildBanner(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(),
                  const SizedBox(height: 16),

                  if (displayedKost.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Belum ada kost favorit',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),

                  ...displayedKost.map(_buildKostCard),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
  // HEADER
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang kembali,',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pengguna KostRadar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belum ada notifikasi')),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SEARCH BAR
  // ========================================

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
                  color: AppColors.white, // <-- DIUBAH
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
              child: const Icon(
                Icons.filter_list,
                color: AppColors.white,
              ), // <-- DIUBAH
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // BANNER
  // ========================================

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
                  color: AppColors.white, // <-- DIUBAH
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Temukan Kost Impianmu!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white, // <-- DIUBAH
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cari kost nyaman dengan harga terbaik.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white,
                ), // <-- DIUBAH
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // JUDUL REKOMENDASI
  // ========================================

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedIndex == 1 ? 'Kost Favorit' : 'Rekomendasi Kost',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (_selectedIndex == 0)
            TextButton(
              onPressed: _openAllResults,
              child: const Text('Lihat Semua'),
            ),
        ],
      ),
    );
  }

  // ========================================
  // CARD KOST
  // ========================================

  Widget _buildKostCard(KostResult kost) {
    final isFavorite = _favorites.contains(kost.name);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.white, // <-- DIUBAH
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors
                .cardShadow, // <-- DIUBAH (biar konsisten sama file lain)
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
                  kost.image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return Container(
                      height: 180,
                      color: AppColors.primaryLight,
                      child: const Center(
                        child: Icon(
                          Icons.home_work,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (kost.isVerified)
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
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                      ), // <-- DIUBAH
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: AppColors.white, // <-- DIUBAH
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        if (isFavorite) {
                          _favorites.remove(kost.name);
                        } else {
                          _favorites.add(kost.name);
                        }
                      });
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
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
                  kost.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        AppColors.textPrimary, // <-- DIUBAH (biar teks jelas)
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rp ${_formatRupiah(kost.price)} /bulan',
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
                        kost.address,
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
                  children: kost.facilities.map((facility) {
                    return Chip(
                      label: Text(
                        facility,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ), // <-- DIUBAH
                      ),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 9, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tersedia ${kost.availableRooms} kamar',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _openDetail(kost);
                      },

                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text(
                        'Detail',
                        style: TextStyle(color: AppColors.primary),
                      ), // <-- DIUBAH
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

  // ========================================
  // CHAT DAN PROFIL SEMENTARA
  // ========================================

  Widget _buildOtherPage() {
    final isChat = _selectedIndex == 2;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isChat ? Icons.chat_bubble_outline : Icons.person_outline,
            size: 65,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            isChat ? 'Halaman Chat' : 'Halaman Profil',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ), // <-- DIUBAH
          ),
          const SizedBox(height: 8),
          const Text(
            'Halaman belum dihubungkan',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
