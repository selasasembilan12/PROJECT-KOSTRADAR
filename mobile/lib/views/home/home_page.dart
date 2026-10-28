import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/widgets/smooth_motion.dart';
import '../../models/kost_model.dart';
// Import file pencarian & hasil
import 'pencarian_page.dart';
import 'hasil_pencarian.dart';
// Import file kost
import '../kost/detail_kost_page.dart';
// Import file chatUser & profil
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
  
  String namaUser = "Memuat...";
  String? fotoUser;
  Set<String> favoriteKostIds = {}; // Menyimpan ID kost yang di-favoritkan oleh user

  @override
  void initState() {
    super.initState();
    _loadNamaUser();
    _loadUserFavorites(); // Load data favorit user pas awal buka
  }

  // Memuat nama dan foto dari tabel 'users', sama seperti halaman ProfilPage.
  Future<void> _loadNamaUser() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            namaUser = 'Pengguna KostRadar';
            fotoUser = null;
          });
        }
        return;
      }

      String userName = 'Pengguna KostRadar';
      String? userFoto;

      try {
        final data = await supabase
            .from('users')
            .select('username, foto')
            .eq('id_user', user.id)
            .maybeSingle();

        if (data != null) {
          final username = data['username']?.toString().trim();
          final foto = data['foto']?.toString().trim();

          if (username != null && username.isNotEmpty) {
            userName = username;
          }

          if (foto != null && foto.isNotEmpty) {
            userFoto = foto;
          }
        }
      } catch (dbError) {
        debugPrint('Gagal mengambil profil pengguna: $dbError');
      }

      // Gunakan metadata akun sebagai cadangan jika nama belum tersedia.
      if (userName == 'Pengguna KostRadar') {
        final metadata = user.userMetadata;
        final metadataName = metadata?['username'] ?? metadata?['nama'];

        if (metadataName != null &&
            metadataName.toString().trim().isNotEmpty) {
          userName = metadataName.toString().trim();
        }
      }

      if (mounted) {
        setState(() {
          namaUser = userName;
          fotoUser = userFoto;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat profil pengguna: $e');

      if (mounted) {
        setState(() {
          namaUser = 'Pengguna KostRadar';
        });
      }
    }
  }

  // FUNGSI MEMUAT DAFTAR ID FAVORIT USER
  Future<void> _loadUserFavorites() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await supabase
          .from('favorite')
          .select('id_kost')
          .eq('id_user', user.id);
      if (mounted) {
        setState(() {
          favoriteKostIds = (response as List)
              .map((item) => item['id_kost'].toString())
              .toSet();
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat id favorit: $e");
    }
  }

  // FUNGSI TOGGLE FAVORIT (TAMBAH / HAPUS)
  Future<void> _toggleFavorite(String idKost) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }
    final isFav = favoriteKostIds.contains(idKost);
    
    // Update UI dulu secara responsif
    setState(() {
      if (isFav) {
        favoriteKostIds.remove(idKost);
      } else {
        favoriteKostIds.add(idKost);
      }
    });

    try {
      if (isFav) {
        // Hapus dari database
        await supabase
            .from('favorite')
            .delete()
            .eq('id_user', user.id)
            .eq('id_kost', idKost);
      } else {
        // Tambah ke database
        await supabase.from('favorite').insert({
          'id_user': user.id,
          'id_kost': idKost,
        });
      }
    } catch (e) {
      debugPrint("Gagal update favorit: $e");
      // Revert status jika gagal di server
      setState(() {
        if (isFav) {
          favoriteKostIds.add(idKost);
        } else {
          favoriteKostIds.remove(idKost);
        }
      });
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
    ).then((_) => _loadUserFavorites());
  }

  String _formatRupiah(dynamic number) {
    final double hargaVal = double.tryParse(number.toString()) ?? 0.0;
    return hargaVal.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  Widget _animatedTab(int index, Widget child) {
    final isSelected = _selectedIndex == index;
    return AnimatedOpacity(
      opacity: isSelected ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: isSelected ? Offset.zero : const Offset(0, 0.015),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !isSelected,
          child: child,
        ),
      ),
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
            // Tab tetap berada di IndexedStack agar state tiap halaman terjaga.
            _animatedTab(0, _buildBerandaTab()),
            _animatedTab(1, _buildFavoritTab()),
            _animatedTab(2, const DaftarChatPage()),
            _animatedTab(3, const ProfilPage()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          // Muat ulang profil saat pengguna kembali ke Beranda.
          if (index == 0) {
            _loadNamaUser();
          }

          if (index == 1) {
            _loadUserFavorites();
          }
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
  // TAB BERANDA (KARTU VERTIKAL / FOTO ATAS)
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
            _buildHeader(),
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
            ...listKost.asMap().entries.map(
              (entry) => SmoothEntrance(
                index: entry.key,
                child: _buildKostCardVertikal(entry.value),
              ),
            ),
          ],
        );
      },
    );
  }

  // ========================================
  // TAB FAVORIT (KARTU HORIZONTAL / FOTO KIRI)
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Header Favorit
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 0),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Kost Favorit",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        "${listKostFavorites.length} Tersimpan",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sub-header Lokasi & Status
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  "Bandung • ${listKostFavorites.length} Kost Tersimpan",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Text(
                  "Sinkron Otomatis",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Banner Informasi Abu-Abu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Ketersediaan kamar dan harga dapat berubah sewaktu-waktu. Hubungi pemilik untuk booking segera.",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Daftar Kartu Favorit (Model Horizontal)
            if (listKostFavorites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Belum ada kost favorit',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...listKostFavorites.asMap().entries.map(
                (entry) => SmoothEntrance(
                  index: entry.key,
                  child: _buildKostCardHorizontal(entry.value),
                ),
              ),
          ],
        );
      },
    );
  }

  // ======================================================
  // 1. KARTU KOST BERANDA (VERTIKAL - UNTUK HALAMAN HOME)
  // ======================================================
  Widget _buildKostCardVertikal(KostModel kost) {
    final imageUrl = kost.foto.isNotEmpty ? kost.foto[0] : '';
    final isFavorite = favoriteKostIds.contains(kost.idKost.toString());

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
          // FOTO ATAS DENGAN BADGE TERVERIFIKASI & TOMBOL LOVE (INTERAKTIF)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 180,
                    color: AppColors.primaryLight,
                    child: const Center(
                      child: Icon(Icons.home_work, size: 60, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              if (kost.terverifikasi)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Terverifikasi',
                          style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              // TOMBOL LOVE / FAVORIT INTERAKTIF
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(kost.idKost.toString()),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // INFORMASI DETAIL KOST (BAWAH)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        kost.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rp ${_formatRupiah(kost.harga)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          '/bulan',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        kost.alamat,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // CHIP FASILITAS
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChipFasilitas(Icons.wifi, "WiFi Cepat"),
                    _buildChipFasilitas(Icons.ac_unit, "AC Dingin"),
                    _buildChipFasilitas(Icons.king_bed_outlined, "K. Mandi Dalam"),
                  ],
                ),
                const SizedBox(height: 12),
                // BARIS BAWAH: KETERSEDIAAN & BUTTON DETAIL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tersedia ${kost.ketersediaanKamar} kamar',
                            style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _openDetail(kost),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Row(
                        children: [
                          Text('Detail', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                        ],
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

  // Helper Chip Fasilitas Beranda
  Widget _buildChipFasilitas(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ========================================================
  // 2. KARTU KOST FAVORIT (HORIZONTAL - UNTUK TAB FAVORIT)
  // ========================================================
  Widget _buildKostCardHorizontal(KostModel kost) {
    final imageUrl = kost.foto.isNotEmpty ? kost.foto[0] : '';
    return GestureDetector(
      onTap: () => _openDetail(kost),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto di Kiri
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 95,
                    height: 95,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 95,
                      height: 95,
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.home_work, color: AppColors.primary),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: Colors.green, size: 10),
                        SizedBox(width: 2),
                        Text(
                          "4.8",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Detail Teks di Kanan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          kost.nama,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleFavorite(kost.idKost.toString()),
                        child: const Icon(Icons.favorite, color: Colors.red, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${_formatRupiah(kost.harga)} /bulan',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          kost.alamat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Fasilitas & Status Kamar
                  Row(
                    children: [
                      const Icon(Icons.wifi, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      const Text("WiFi", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      const Icon(Icons.ac_unit, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      const Text("AC", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(
                              "Tersedia ${kost.ketersediaanKamar} kmr",
                              style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Beranda
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: fotoUser != null && fotoUser!.isNotEmpty
                ? NetworkImage(fotoUser!)
                : null,
            child: fotoUser == null || fotoUser!.isEmpty
                ? const Icon(
                    Icons.person,
                    color: AppColors.primary,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selamat Datang 👋', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  'Hai, $namaUser',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_outlined, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _openSearch,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Text('Cari nama kost, daerah, atau...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _openSearch,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.tune, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Banner
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎓 ', style: TextStyle(fontSize: 10)),
                      Text('Zona Kampus', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Temukan kost terbaik di sekitar kampus',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Akses jalan cepat, lingkungan tenang, dan bebas jam malam!',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  // Header Section
  Widget _buildSectionHeader(String title, bool showSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            child: const Text('Pilihan', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ),
          const Spacer(),
          if (showSeeAll)
            GestureDetector(
              onTap: _openAllResults,
              child: const Row(
                children: [
                  Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}