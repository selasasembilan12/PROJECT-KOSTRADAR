import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';

import 'home_admin_page.dart';
import 'daftar_chat_admin_page.dart';
import 'profil_admin_page.dart';
import 'tambah_edit_kost_page.dart';

// ============================================================
// MODEL DATA KOST (Mendukung Foto dari Relasi Supabase)
// ============================================================

class KostItem {
  final String idKost;
  final String? idUser;
  final String nama;
  final String? alamat;
  final double harga;
  final String? deskripsi;
  final int ketersediaanKamar;
  final List<String> listFoto; // Menampung daftar URL/nama foto

  const KostItem({
    required this.idKost,
    this.idUser,
    required this.nama,
    this.alamat,
    required this.harga,
    this.deskripsi,
    required this.ketersediaanKamar,
    required this.listFoto,
  });

  factory KostItem.fromMap(Map<String, dynamic> map) {
    // Mengambil data foto dari hasil relasi tabel 'foto_kost' di Supabase
    var fotoData = map['foto_kost'] as List<dynamic>? ?? [];
    List<String> fotos = fotoData
        .map((f) => f['foto']?.toString() ?? '')
        .toList();

    return KostItem(
      idKost: map['id_kost']?.toString() ?? '',
      idUser: map['id_user']?.toString(),
      nama: map['nama'] ?? '',
      alamat: map['alamat'],
      harga: (map['harga'] != null)
          ? double.parse(map['harga'].toString())
          : 0.0,
      deskripsi: map['deskripsi'],
      ketersediaanKamar: map['ketersediaan_kamar'] ?? 0,
      listFoto: fotos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id_kost": idKost,
      "id_user": idUser,
      "nama": nama,
      "alamat": alamat,
      "harga": harga,
      "deskripsi": deskripsi,
      "ketersediaan_kamar": ketersediaanKamar,
      "list_foto": listFoto,
    };
  }
}

// ============================================================
// DATA KOST PAGE
// ============================================================

class DataKostPage extends StatefulWidget {
  const DataKostPage({super.key});

  @override
  State<DataKostPage> createState() => _DataKostPageState();
}

class _DataKostPageState extends State<DataKostPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fungsi mengambil data kost beserta relasi tabel 'foto_kost'
  Future<List<KostItem>> _fetchKostData() async {
    final response = await supabase
        .from('kost')
        .select(
          '*, foto_kost(foto)',
        ) // Mengambil data kost dan relasi fotonya sekaligus
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((item) => KostItem.fromMap(item)).toList();
  }

  // Fungsi untuk menghapus kost dan foto relasinya
  Future<void> _deleteKost(BuildContext context, KostItem kost) async {
    try {
      await supabase.from('foto_kost').delete().eq('id_kost', kost.idKost);
      await supabase.from('kost').delete().eq('id_kost', kost.idKost);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${kost.nama} berhasil dihapus"),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menghapus kost: $e"),
          backgroundColor: AppColors.error,
        ),
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
            _buildTopBar(context),
            Expanded(
              child: FutureBuilder<List<KostItem>>(
                future: _fetchKostData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Terjadi kesalahan: ${snapshot.error}",
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final daftarKost = snapshot.data ?? [];

                  if (daftarKost.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              "Belum ada data kost tersedia.",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        _buildManajemenKamarInfo(),
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final kost in daftarKost)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildKostCard(context, kost),
                        ),
                      const SizedBox(height: 8),
                      _buildManajemenKamarInfo(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Data Kost",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TambahEditKostPage(),
                ),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              "Tambah Kost",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DATA KOST (Menampilkan Indikator Foto)
  // ============================================================

  Widget _buildKostCard(BuildContext context, KostItem kost) {
    final formattedHarga =
        "Rp ${kost.harga.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

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
          // Menampilkan thumbnail foto pertama jika ada, atau ikon default jika kosong
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: kost.listFoto.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const Icon(
                      Icons.image,
                      color: AppColors.primary,
                    ), // Bisa diganti NetworkImage jika berupa URL Cloud
                  )
                : const Icon(
                    Icons.apartment,
                    size: 30,
                    color: AppColors.textSecondary,
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
                const SizedBox(height: 4),
                Text(
                  "$formattedHarga/bulan",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kost.alamat ?? 'Tidak ada alamat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Tersedia ${kost.ketersediaanKamar} kamar (${kost.listFoto.length} foto)",
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TambahEditKostPage(kostData: kost.toMap()),
                    ),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
                icon: const Icon(
                  Icons.edit,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () {
                  _showDeleteDialog(context, kost);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
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
  // DELETE CONFIRMATION
  // ============================================================

  void _showDeleteDialog(BuildContext context, KostItem kost) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Kost"),
          content: Text("Apakah Anda yakin ingin menghapus ${kost.nama}?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteKost(context, kost);
              },
              child: const Text(
                "Hapus",
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // INFO MANAJEMEN KAMAR
  // ============================================================

  Widget _buildManajemenKamarInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Manajemen Kamar",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Perbarui data ketersediaan kamar secara berkala untuk memudahkan calon penghuni menemukan unit Anda.",
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

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_outlined, "Home", false),
            _buildNavItem(context, Icons.apartment, "Data Kost", true),
            _buildNavItem(context, Icons.chat_bubble_outline, "Chat", false),
            _buildNavItem(context, Icons.person_outline, "Profil", false),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION ITEM
  // ============================================================

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
  ) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        switch (label) {
          case "Home":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeAdminPage()),
            );
            break;
          case "Chat":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DaftarChatAdminPage(chatData: {}),
              ),
            );
            break;
          case "Profil":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilAdminPage()),
            );
            break;
          case "Data Kost":
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
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
