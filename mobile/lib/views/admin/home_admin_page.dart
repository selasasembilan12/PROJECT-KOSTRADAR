import 'package:flutter/material.dart';

// ============================================================
// WARNA APLIKASI
// ============================================================
class AppColors {
  static const primary = Color(0xFF2E75D6);
  static const primaryDark = Color(0xFF1A4D8F);
  static const success = Color(0xFF2E9E5B);
  static const bgLight = Color(0xFFF5F7FA);
  static const cardBorder = Color(0xFFE5E8EC);
  static const textGrey = Color(0xFF8A94A6);
}

// ============================================================
// HALAMAN HOME ADMIN
// ============================================================
class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminHomeView();
  }
}

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRingkasanPropertiCard(),
                    const SizedBox(height: 16),
                    _buildKelolaUnitButton(),
                    const SizedBox(height: 20),
                    _buildKostTerbaruHeader(),
                    const SizedBox(height: 10),
                    _buildKostItem(
                      nama: 'Kost Adiwarna',
                      harga: 'Rp 1.200.000',
                      waktu: '11:30',
                      status: 'Tersedia 3 kamar',
                    ),
                    const SizedBox(height: 10),
                    _buildKostItem(
                      nama: 'Kost Melati',
                      harga: 'Rp 1.000.000',
                      waktu: '11:30',
                      status: null,
                    ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.radar, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Text(
                'KOSTRADAR ADMIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Home',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- RINGKASAN PROPERTI ----------------
  Widget _buildRingkasanPropertiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Properti',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pantau aktivitas kost dan calon penghuni hari ini',
                      style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge('Aktif'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.apartment,
                  iconColor: AppColors.primary,
                  value: '12',
                  label: 'Total Kost',
                  trailing: _buildTrendBadge('+2'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.meeting_room,
                  iconColor: AppColors.success,
                  value: '8',
                  label: 'Kamar Tersedia',
                  trailingText: 'Siap huni',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.mail_outline,
                  iconColor: AppColors.primary,
                  value: '4',
                  label: 'Pesan Masuk',
                  trailing: _buildDot(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.chat_bubble_outline,
                  iconColor: AppColors.primary,
                  value: '25',
                  label: 'Total Chat',
                  trailingText: 'Bulan ini',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    Widget? trailing,
    String? trailingText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              if (trailing != null) trailing,
              if (trailingText != null)
                Text(
                  trailingText,
                  style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.success,
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  // ---------------- TOMBOL KELOLA UNIT BARU ----------------
  Widget _buildKelolaUnitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Unit Baru',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Tambahkan kamar & perbarui ketersediaan',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  // ---------------- KOST TERBARU ----------------
  Widget _buildKostTerbaruHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Kost Terbaru',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        Row(
          children: const [
            Text(
              'Lihat Semua',
              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildKostItem({
    required String nama,
    required String harga,
    required String waktu,
    required String? status,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment, color: AppColors.textGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      waktu,
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$harga/bulan',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: const TextStyle(fontSize: 11, color: AppColors.success),
                      ),
                      const Spacer(),
                      const Icon(Icons.wifi, size: 14, color: AppColors.textGrey),
                      const SizedBox(width: 6),
                      const Icon(Icons.ac_unit, size: 14, color: AppColors.textGrey),
                    ],
                  ),
                ],
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
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', isActive: true),
            _buildNavItem(Icons.apartment_outlined, 'Data Kost', isActive: false),
            _buildNavItem(Icons.chat_bubble_outline, 'Chat', isActive: false),
            _buildNavItem(Icons.person_outline, 'Profil', isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {required bool isActive}) {
    final color = isActive ? AppColors.primary : AppColors.textGrey;
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