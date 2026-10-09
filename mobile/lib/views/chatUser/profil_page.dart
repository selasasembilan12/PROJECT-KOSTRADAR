import 'package:flutter/material.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: AppColors.textPrimary), // <-- DIUBAH
        ),
        backgroundColor: AppColors.white, // <-- DIUBAH
        foregroundColor: AppColors.textPrimary, // <-- DIUBAH
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CircleAvatar(
              radius: 50,
              backgroundColor:
                  AppColors.primary, // <-- DIUBAH (pengganti blueAccent)
              child: Icon(
                Icons.person,
                size: 50,
                color: AppColors.white,
              ), // <-- DIUBAH
            ),
            const SizedBox(height: 16),
            const Text(
              'Rian Mahasiswa',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, // <-- DIUBAH
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'rian.mahasiswa@email.com',
              style: TextStyle(
                color: AppColors.textSecondary, // <-- DIUBAH (pengganti grey)
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(
              thickness: 8, // <-- DIUBAH (ditebalkan dikit biar kayak section separator modern)
              color: AppColors
                  .backgroundLight, // <-- DIUBAH (pengganti 0xFFF5F5F5)
            ),

            ListTile(
              leading: const Icon(
                Icons.favorite_border,
                color: AppColors.primary, // <-- DIUBAH
              ),
              title: const Text(
                'Kost Favorit Saya',
                style: TextStyle(color: AppColors.textPrimary), // <-- DIUBAH
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors
                    .textHint, // <-- DIUBAH (biar panah nggak terlalu mencolok)
              ),
              onTap: () {
                Navigator.pushNamed(context, '/daftar-favorite');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.history,
                color: AppColors.primary, // <-- DIUBAH
              ),
              title: const Text(
                'Riwayat & Status Sewa',
                style: TextStyle(color: AppColors.textPrimary), // <-- DIUBAH
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textHint, // <-- DIUBAH
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(
                Icons.settings_outlined,
                color: AppColors.primary, // <-- DIUBAH
              ),
              title: const Text(
                'Pengaturan Akun',
                style: TextStyle(color: AppColors.textPrimary), // <-- DIUBAH
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textHint, // <-- DIUBAH
              ),
              onTap: () {},
            ),
            const Divider(
              thickness: 8, // <-- DIUBAH
              color: AppColors.backgroundLight, // <-- DIUBAH
            ),

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.error, // <-- DIUBAH (pengganti Colors.red)
              ),
              title: const Text(
                'Keluar (Logout)',
                style: TextStyle(
                  color: AppColors.error, // <-- DIUBAH
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
