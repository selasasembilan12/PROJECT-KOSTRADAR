import 'package:flutter/material.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

class ProfilAdminPage extends StatefulWidget {
  const ProfilAdminPage({super.key});

  @override
  State<ProfilAdminPage> createState() => _ProfilAdminPageState();
}

class _ProfilAdminPageState extends State<ProfilAdminPage> {
  // Data sementara.
  // Nama field dibuat mengikuti tabel users agar nanti mudah dihubungkan
  // ke database.
  final Map<String, dynamic> admin = {
    'id_user': 'admin-001',
    'username': 'Admin KostRadar',
    'email': 'admin@kostradar.com',
    'foto_profile': '',
    'role': 'admin',
  };

  @override
  Widget build(BuildContext context) {
    final String username = admin['username'] ?? 'Admin';
    final String email = admin['email'] ?? '-';
    final String fotoProfile = admin['foto_profile'] ?? '';

    return Scaffold(
      backgroundColor:
          AppColors.background, // <-- DIUBAH (pengganti 0xFFF7F8FA)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white, // <-- DIUBAH
        foregroundColor:
            AppColors.textPrimary, // <-- DIUBAH (pengganti 0xFF1F2937)
        title: const Text(
          'KOSTRADAR ADMIN',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color:
                    AppColors.textPrimary, // <-- DIUBAH (pengganti 0xFF111827)
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kelola informasi akun admin Anda',
              style: TextStyle(
                fontSize: 14,
                color: AppColors
                    .textSecondary, // <-- DIUBAH (pengganti 0xFF6B7280)
              ),
            ),
            const SizedBox(height: 24),

            // PROFILE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white, // <-- DIUBAH
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow, // <-- DIUBAH (pengganti Colors.black.withValues)
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildAvatar(username: username, fotoProfile: fotoProfile),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary, // <-- DIUBAH
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary, // <-- DIUBAH
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showEditProfile,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // <-- DIUBAH
                        foregroundColor: AppColors.white, // <-- DIUBAH
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Pengaturan Akun',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, // <-- DIUBAH
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingItem(
              icon: Icons.lock_outline,
              title: 'Ubah Password',
              subtitle: 'Perbarui password akun admin',
              onTap: _showChangePassword,
            ),

            const SizedBox(height: 10),

            _buildSettingItem(
              icon: Icons.logout_outlined,
              title: 'Logout',
              subtitle: 'Keluar dari akun admin',
              iconColor: AppColors.error, // <-- DIUBAH (pengganti Colors.red)
              titleColor: AppColors.error, // <-- DIUBAH
              onTap: _showLogoutConfirmation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({required String username, required String fotoProfile}) {
    final bool hasPhoto = fotoProfile.trim().isNotEmpty;

    if (hasPhoto) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(fotoProfile),
      );
    }

    final String initial = username.trim().isNotEmpty
        ? username.trim()[0].toUpperCase()
        : 'A';

    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.primaryLight, // <-- DIUBAH (biar avatar default ada background biru muda)
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: AppColors.primary, // <-- DIUBAH
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Material(
      color: AppColors.white, // <-- DIUBAH
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight, // <-- DIUBAH (biar icon ada background tipis)
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      iconColor ??
                      AppColors
                          .textSecondary, // <-- DIUBAH (pengganti 0xFF374151)
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColors.textPrimary, // <-- DIUBAH (pengganti 0xFF111827)
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors
                            .textSecondary, // <-- DIUBAH (pengganti 0xFF6B7280)
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint, // <-- DIUBAH (pengganti 0xFF9CA3AF)
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfile() {
    final usernameController = TextEditingController(
      text: admin['username'] ?? '',
    );
    final emailController = TextEditingController(text: admin['email'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white, // <-- DIUBAH
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary, // <-- DIUBAH
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(
                    color: AppColors.textSecondary,
                  ), // <-- DIUBAH
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.textSecondary,
                  ), // <-- DIUBAH
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ), // <-- DIUBAH
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ), // <-- DIUBAH
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ), // <-- DIUBAH
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: AppColors.textSecondary,
                  ), // <-- DIUBAH
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppColors.textSecondary,
                  ), // <-- DIUBAH
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ), // <-- DIUBAH
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ), // <-- DIUBAH
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ), // <-- DIUBAH
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      admin['username'] = usernameController.text.trim();
                      admin['email'] = emailController.text.trim();
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil berhasil diperbarui.'),
                        backgroundColor: AppColors.success, // <-- DIUBAH
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // <-- DIUBAH
                    foregroundColor: AppColors.white, // <-- DIUBAH
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ), // <-- DIUBAH
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePassword() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white, // <-- DIUBAH
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ubah Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary, // <-- DIUBAH
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  labelStyle: TextStyle(
                    color: AppColors.textSecondary,
                  ), // <-- DIUBAH
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                  ), // <-- DIUBAH
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ), // <-- DIUBAH
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ), // <-- DIUBAH
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ), // <-- DIUBAH
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password',
                  labelStyle: TextStyle(
                    color: AppColors.textSecondary,
                  ), // <-- DIUBAH
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                  ), // <-- DIUBAH
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ), // <-- DIUBAH
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ), // <-- DIUBAH
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ), // <-- DIUBAH
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (passwordController.text.isEmpty ||
                        confirmController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password belum diisi.'),
                          backgroundColor: AppColors.error, // <-- DIUBAH
                        ),
                      );
                      return;
                    }

                    if (passwordController.text != confirmController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Konfirmasi password tidak sama.'),
                          backgroundColor: AppColors.error, // <-- DIUBAH
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password berhasil diperbarui secara lokal.',
                        ),
                        backgroundColor: AppColors.success, // <-- DIUBAH
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // <-- DIUBAH
                    foregroundColor: AppColors.white, // <-- DIUBAH
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ), // <-- DIUBAH
                  ),
                  child: const Text('Simpan Password'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white, // <-- DIUBAH
          title: const Text(
            'Logout',
            style: TextStyle(color: AppColors.textPrimary), // <-- DIUBAH
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun admin?',
            style: TextStyle(color: AppColors.textSecondary), // <-- DIUBAH
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary), // <-- DIUBAH
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logout masih bersifat lokal.'),
                    backgroundColor: AppColors.error, // <-- DIUBAH
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, // <-- DIUBAH
                foregroundColor: AppColors.white, // <-- DIUBAH
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ), // <-- DIUBAH
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
