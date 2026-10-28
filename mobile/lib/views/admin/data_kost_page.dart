import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/smooth_motion.dart';
import 'home_admin_page.dart';
import 'daftar_chat_admin_page.dart';
import 'profil_admin_page.dart';
import 'tambah_edit_kost_page.dart';

class KostItem {
  final Map<String, dynamic> data;

  const KostItem(this.data);

  String get id => (data['id_kost'] ?? data['id'] ?? '').toString();

  String get nama => (data['nama'] ?? 'Tanpa nama').toString();

  String get harga {
    final value = num.tryParse(data['harga']?.toString() ?? '') ?? 0;
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  String get ketersediaan =>
      'Tersedia ${data['ketersediaan_kamar'] ?? 0} kamar';

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(data);
}

class DataKostPage extends StatefulWidget {
  const DataKostPage({super.key});

  @override
  State<DataKostPage> createState() => _DataKostPageState();
}

class _DataKostPageState extends State<DataKostPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<KostItem> daftarKost = [];
  bool isLoading = true;
  String? errorMessage;
  final Map<String, String?> fotoKost = {};

  @override
  void initState() {
    super.initState();
    _loadKost();
  }

  // ============================================================
  // MEMUAT KOST MILIK AKUN YANG SEDANG LOGIN
  // ============================================================

  Future<void> _loadKost() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      // Hanya mengambil kost yang id_user-nya sesuai dengan akun login.
      final response = await supabase
          .from('kost')
          .select()
          .eq('id_user', user.id);

      final items = <KostItem>[];

      for (final row in response) {
        items.add(KostItem(Map<String, dynamic>.from(row)));
      }

      // Mengambil foto hanya untuk kost milik akun yang login.
      final fotoMap = <String, String?>{};

      for (final kost in items) {
        if (kost.id.isEmpty) continue;

        final fotoRows = await supabase
            .from('foto_kost')
            .select('foto')
            .eq('id_kost', kost.id);

        fotoMap[kost.id] = fotoRows.isNotEmpty
            ? fotoRows.first['foto']?.toString()
            : null;
      }

      if (!mounted) return;

      setState(() {
        daftarKost = items;
        fotoKost
          ..clear()
          ..addAll(fotoMap);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // MEMBUKA FORM TAMBAH / EDIT KOST
  // ============================================================

  Future<void> _openForm({KostItem? kost}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahEditKostPage(
          kostData: kost?.toMap(),
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadKost();
    }
  }

  // ============================================================
  // MENGHAPUS KOST MILIK AKUN YANG LOGIN
  // ============================================================

  Future<void> _showDeleteDialog(KostItem kost) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kost'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${kost.nama}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (kost.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID kost tidak ditemukan.')),
      );
      return;
    }

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Silakan login kembali.');
      }

      // Pastikan data yang akan dihapus memang milik akun login.
      final existingKost = await supabase
          .from('kost')
          .select('id_kost')
          .eq('id_kost', kost.id)
          .eq('id_user', user.id)
          .maybeSingle();

      if (existingKost == null) {
        throw Exception(
          'Kost tidak ditemukan atau bukan milik akun yang sedang login.',
        );
      }

      // Hapus foto yang terhubung dengan kost tersebut.
      await supabase
          .from('foto_kost')
          .delete()
          .eq('id_kost', kost.id);

      // Hapus kost dengan filter ID dan pemilik.
      await supabase
          .from('kost')
          .delete()
          .eq('id_kost', kost.id)
          .eq('id_user', user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${kost.nama} berhasil dihapus.')),
      );

      await _loadKost();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus kost: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Kost',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Tambah Kost',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KONTEN DATA KOST
  // ============================================================

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              const Text(
                'Data kost gagal dimuat.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadKost,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (daftarKost.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadKost,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          children: const [
            SizedBox(height: 100),
            Icon(
              Icons.apartment_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Belum ada data kost',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Tekan Tambah Kost untuk menambahkan data.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadKost,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var index = 0; index < daftarKost.length; index++)
            SmoothEntrance(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildKostCard(daftarKost[index]),
              ),
            ),
          _buildManajemenKamarInfo(),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU KOST
  // ============================================================

  Widget _buildKostCard(KostItem kost) {
    final foto = fotoKost[kost.id];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 76,
              height: 86,
              child: foto != null && foto.isNotEmpty
                  ? Image.network(
                      foto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kost.nama,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${kost.harga}/bulan',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kost.ketersediaan,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                  ),
                ),
                if ((kost.data['alamat'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    kost.data['alamat'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Edit kost',
                onPressed: () => _openForm(kost: kost),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                tooltip: 'Hapus kost',
                onPressed: () => _showDeleteDialog(kost),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOTO KOST KOSONG / GAGAL DIMUAT
  // ============================================================

  Widget _photoPlaceholder() {
    return Container(
      color: AppColors.backgroundLight,
      child: const Icon(
        Icons.apartment,
        size: 32,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ============================================================
  // INFORMASI MANAJEMEN KAMAR
  // ============================================================

  Widget _buildManajemenKamarInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen Kamar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Perbarui data ketersediaan kamar secara berkala agar calon penghuni memperoleh informasi terbaru.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'Home', false),
            _buildNavItem(Icons.apartment, 'Data Kost', true),
            _buildNavItem(Icons.chat_bubble_outline, 'Chat', false),
            _buildNavItem(Icons.person_outline, 'Profil', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active) {
    final color = active ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        switch (label) {
          case 'Home':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeAdminPage()),
            );
            break;

          case 'Chat':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DaftarChatAdminPage(chatData: {}),
              ),
            );
            break;

          case 'Profil':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilAdminPage()),
            );
            break;

          case 'Data Kost':
            break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}