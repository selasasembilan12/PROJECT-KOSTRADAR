//Hesti

import 'package:flutter/material.dart';

// ==========================================
// WARNA APLIKASI KOSTRADAR
// ==========================================

class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundLight = Colors.white;
  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF12233F);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color cardBackground = Colors.white;
  static const Color cardShadow = Color(0x14000000);
  static const Color chipBackground = Color(0xFFEFF6FF);
  static const Color chipText = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
}

// ==========================================
// PENGATURAN SPASI
// ==========================================

class AppSpacing {
  static const double defaultPadding = 20;
  static const double mediumSpacing = 20;
  static const double largeSpacing = 24;
}

// ==========================================
// TEKS APLIKASI
// ==========================================

class AppTexts {
  static const String welcomeText = "Selamat datang kembali,";
  static const String userName = "Pengguna KostRadar";
  static const String searchHint = "Cari kost impianmu...";
  static const String bannerTag = "KOSTRADAR";
  static const String bannerTitle = "Temukan Kost Impianmu!";
  static const String bannerSubtitle =
      "Cari kost nyaman dengan harga terbaik.";
  static const String recommendationTitle = "Rekomendasi Kost";
  static const String viewAll = "Lihat Semua";
  static const String verified = "Terverifikasi";
  static const String available = "Tersedia";
  static const String detail = "Detail";
}

// ==========================================
// MODEL DATA KOST
// ==========================================

class Kost {
  final String name;
  final String address;
  final int price;
  final String image;
  final List<String> facilities;
  final int availableRooms;
  final bool isVerified;
  bool isFavorite;

  Kost({
    required this.name,
    required this.address,
    required this.price,
    required this.image,
    required this.facilities,
    required this.availableRooms,
    this.isVerified = false,
    this.isFavorite = false,
  });
}

// ==========================================
// HALAMAN HOME
// ==========================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  String _searchKeyword = "";

  final List<Kost> _kostList = [
    Kost(
      name: "Kost Adiwarna",
      address: "Jl. Gegerkalong No. 12, Bandung",
      price: 1200000,
      image:
          "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
      facilities: [
        "WiFi Cepat",
        "AC Dingin",
        "K. Mandi Dalam",
      ],
      availableRooms: 3,
      isVerified: true,
      isFavorite: true,
    ),
    Kost(
      name: "Kost Melati",
      address: "Jl. Setiabudi No. 45, Bandung",
      price: 1000000,
      image:
          "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800",
      facilities: [
        "WiFi",
        "AC",
        "Parkir",
      ],
      availableRooms: 2,
      isVerified: false,
      isFavorite: false,
    ),
  ];

  // ==========================================
  // FORMAT RUPIAH
  // ==========================================

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // ==========================================
  // FILTER DATA KOST
  // ==========================================

  List<Kost> get _filteredKost {
    return _kostList.where((kost) {
      final keyword = _searchKeyword.toLowerCase();

      final matchSearch =
          kost.name.toLowerCase().contains(keyword) ||
          kost.address.toLowerCase().contains(keyword) ||
          kost.facilities.any(
            (facility) =>
                facility.toLowerCase().contains(keyword),
          );

      final matchFavorite =
          _selectedIndex != 1 || kost.isFavorite;

      return matchSearch && matchFavorite;
    }).toList();
  }

  // ==========================================
  // BUKA HALAMAN PENCARIAN
  // ==========================================

  Future<void> _openSearch() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => KostSearchPage(
          initialKeyword: _searchKeyword,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _searchKeyword = result;
      _selectedIndex = 0;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // TAMPILAN UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: _selectedIndex == 2 || _selectedIndex == 3
            ? _buildOtherPage()
            : _buildHomeContent(),
      ),

      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeContent() {
    final kostList = _filteredKost;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          _buildHeader(),

          const SizedBox(
            height: AppSpacing.mediumSpacing,
          ),

          _buildSearchBar(),

          const SizedBox(
            height: AppSpacing.mediumSpacing,
          ),

          _buildBanner(),

          const SizedBox(
            height: AppSpacing.largeSpacing,
          ),

          _buildRecommendationSection(),

          const SizedBox(height: 16),

          if (kostList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text(
                  "Kost tidak ditemukan",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

          ...kostList.map(
            (kost) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.defaultPadding,
              ),
              child: _buildKostCard(kost),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.defaultPadding,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTexts.welcomeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  AppTexts.userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                _showMessage("Belum ada notifikasi");
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SEARCH BAR
  // ==========================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.defaultPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        _searchKeyword.isEmpty
                            ? AppTexts.searchHint
                            : _searchKeyword,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: _openSearch,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.filter_list,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BANNER
  // ==========================================

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.defaultPadding,
      ),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: NetworkImage(
              "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800",
            ),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppTexts.bannerTag,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12),

                Text(
                  AppTexts.bannerTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  AppTexts.bannerSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // REKOMENDASI
  // ==========================================

  Widget _buildRecommendationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.defaultPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedIndex == 1
                  ? "Kost Favorit"
                  : AppTexts.recommendationTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          TextButton(
            onPressed: _openSearch,
            child: const Text(
              AppTexts.viewAll,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD KOST
  // ==========================================

  Widget _buildKostCard(Kost kost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
                  kost.image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      color: AppColors.primaryLight,
                      child: const Icon(
                        Icons.home_work,
                        size: 60,
                        color: AppColors.primary,
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 12,
                        ),

                        SizedBox(width: 4),

                        Text(
                          AppTexts.verified,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        kost.isFavorite = !kost.isFavorite;
                      });
                    },
                    icon: Icon(
                      kost.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: kost.isFavorite
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
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Rp ${_formatRupiah(kost.price)} /bulan",
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
                      color: AppColors.textSecondary,
                      size: 16,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        kost.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.chipBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        facility,
                        style: const TextStyle(
                          color: AppColors.chipText,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 9,
                      color: AppColors.success,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        "${AppTexts.available} "
                        "${kost.availableRooms} kamar",
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    TextButton.icon(
                      onPressed: () {
                        _showMessage(
                          "Detail ${kost.name} belum dihubungkan",
                        );
                      },
                      label: const Text(AppTexts.detail),
                      icon: const Icon(
                        Icons.arrow_forward,
                        size: 14,
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

  // ==========================================
  // HALAMAN CHAT DAN PROFIL SEMENTARA
  // ==========================================

  Widget _buildOtherPage() {
    final isChat = _selectedIndex == 2;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isChat
                ? Icons.chat_bubble_outline
                : Icons.person_outline,
            size: 65,
            color: AppColors.primary,
          ),

          const SizedBox(height: 16),

          Text(
            isChat ? "Halaman Chat" : "Halaman Profil",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Halaman belum dihubungkan",
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,

      onTap: (index) {
        setState(() {
          _selectedIndex = index;
          if (index == 0) {
            _searchKeyword = "";
          }
        });
      },

      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedFontSize: 12,
      unselectedFontSize: 12,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          activeIcon: Icon(Icons.favorite),
          label: "Favorit",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: "Chat",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: "Profil",
        ),
      ],
    );
  }
}

// ==========================================
// HALAMAN PENCARIAN SEMENTARA
// ==========================================

class KostSearchPage extends StatefulWidget {
  final String initialKeyword;

  const KostSearchPage({
    super.key,
    this.initialKeyword = "",
  });

  @override
  State<KostSearchPage> createState() =>
      _KostSearchPageState();
}

class _KostSearchPageState extends State<KostSearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialKeyword,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    Navigator.pop(
      context,
      _controller.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Pencarian Kost"),
        backgroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: "Cari nama atau lokasi kost",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Cari Kost"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

