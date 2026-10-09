import 'package:flutter/material.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

class KostItem {
  final String nama;
  final String harga;
  final String ketersediaan;

  const KostItem({
    required this.nama,
    required this.harga,
    required this.ketersediaan,
  });
}

class DataKostView extends StatelessWidget {
  const DataKostView({super.key});

  static const List<KostItem> _daftarKost = [
    KostItem(
      nama: 'Kost Adiwarna',
      harga: 'Rp 1.200.000',
      ketersediaan: 'Tersedia 3 kamar',
    ),
    KostItem(
      nama: 'Kost Melati',
      harga: 'Rp 1.000.000',
      ketersediaan: 'Tersedia 2 kamar',
    ),
    KostItem(
      nama: 'Kost Cemara',
      harga: 'Rp 950.000',
      ketersediaan: 'Tersedia 5 kamar',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // <-- DIUBAH (pengganti bgLight)
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final kost in _daftarKost) ...[
                      _buildKostCard(kost),
                      const SizedBox(height: 12),
                    ],
                    _buildManajemenKamarInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------- TOP BAR ----------------
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: AppColors.white, // <-- DIUBAH
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu,
                size: 22,
                color: AppColors.textPrimary,
              ), // <-- DIUBAH
              const SizedBox(width: 10),
              const Text(
                'Data Kost',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary, // <-- DIUBAH
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // <-- DIUBAH
              foregroundColor: AppColors.white, // <-- DIUBAH
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  // ---------------- KARTU KOST ----------------
  Widget _buildKostCard(KostItem kost) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white, // <-- DIUBAH
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ), // <-- DIUBAH (pengganti cardBorder)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color:
                  AppColors.backgroundLight, // <-- DIUBAH (pengganti bgLight)
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.apartment,
              color: AppColors.textSecondary,
            ), // <-- DIUBAH (pengganti textGrey)
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kost.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary, // <-- DIUBAH
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${kost.harga} / bulan',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary, // <-- DIUBAH
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success, // <-- DIUBAH
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      kost.ketersediaan,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success, // <-- DIUBAH
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
                onPressed: () {},
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 18,
                ), // <-- DIUBAH
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 18,
                ), // <-- DIUBAH (pengganti danger)
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- INFO MANAJEMEN KAMAR ----------------
  Widget _buildManajemenKamarInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight, // <-- DIUBAH (pengganti infoBg)
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 20,
          ), // <-- DIUBAH
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen Kamar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary, // <-- DIUBAH
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Perbarui data ketersediaan kamar secara berkala untuk memudahkan calon penghuni menemukan unit Anda.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors
                        .textSecondary, // <-- DIUBAH (pengganti textGrey)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- BOTTOM NAVIGATION ----------------
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white, // <-- DIUBAH
        border: Border(
          top: BorderSide(color: AppColors.border),
        ), // <-- DIUBAH (pengganti cardBorder)
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.dashboard_outlined,
              'Dashboard',
              isActive: false,
            ),
            _buildNavItem(Icons.apartment, 'Data Kost', isActive: true),
            _buildNavItem(Icons.chat_bubble_outline, 'Chat', isActive: false),
            _buildNavItem(Icons.person_outline, 'Profil', isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {required bool isActive}) {
    final color = isActive
        ? AppColors.primary
        : AppColors.textSecondary; // <-- DIUBAH (pengganti textGrey)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
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
    );
  }
}
