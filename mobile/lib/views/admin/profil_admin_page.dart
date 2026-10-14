import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import 'home_admin_page.dart';
import 'data_kost_page.dart';
import 'daftar_chat_admin_page.dart';

class ProfilAdminPage extends StatefulWidget {
  const ProfilAdminPage({super.key});

  @override
  State<ProfilAdminPage> createState() => _ProfilAdminPageState();
}

class _ProfilAdminPageState extends State<ProfilAdminPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  Map<String, dynamic> adminData = {
    'username': 'Admin KostRadar',
    'email': 'admin@kostradar.com',
    'foto_profile': '',
  };

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
  }

  Future<void> _fetchAdminProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        adminData = {
          'username': user.userMetadata?['username'] ??
              user.email?.split('@').first ??
              'Admin',
          'email': user.email ?? '-',
          'foto_profile': user.userMetadata?['foto_profile'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Gagal mengambil profil: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Fungsi untuk memilih dan mengunggah foto profil ke Supabase Storage
  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User belum login");

      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = 'admin_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'profile_admin/$fileName';

      // Upload file ke Supabase Storage bucket 'kost-images'
      await supabase.storage.from('kost-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt', upsert: true),
          );

      // Ambil Public URL gambar
      final imageUrl = supabase.storage.from('kost-images').getPublicUrl(filePath);

      // Simpan URL ke metadata user Supabase Auth
      await supabase.auth.updateUser(
        UserAttributes(
          data: {'foto_profile': imageUrl},
        ),
      );

      setState(() {
        adminData['foto_profile'] = imageUrl;
        _isUploadingPhoto = false;
      });

      _showMessage('Foto profil berhasil diperbarui');
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      _showMessage('Gagal mengunggah foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = adminData['username'] as String? ?? 'Admin';
    final email = adminData['email'] as String? ?? '-';
    final fotoProfile = adminData['foto_profile'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Kelola informasi akun admin Anda',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildProfileCard(username, email, fotoProfile),
                          const SizedBox(height: 24),
                          const Text(
                            'Pengaturan Akun',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
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
                            iconColor: AppColors.error,
                            titleColor: AppColors.error,
                            onTap: _showLogoutConfirmation,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Profil Admin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    String username,
    String email,
    String fotoProfile,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                ),
                child: _isUploadingPhoto
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : fotoProfile.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              fotoProfile,
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 45,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 45,
                            color: AppColors.primary,
                          ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadPhoto, // Membuka galeri untuk ganti foto
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 15,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _editProfile, // Tombol edit untuk mengubah nama/username
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(
      text: adminData['username'] as String? ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profil Admin'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Username Baru',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    final newName = nameController.text.trim();

                    if (newName.isEmpty) {
                      _showMessage('Username tidak boleh kosong');
                      return;
                    }

                    setState(() => _isSaving = true);

                    try {
                      await supabase.auth.updateUser(
                        UserAttributes(
                          data: {'username': newName},
                        ),
                      );

                      if (!mounted) return;

                      setState(() {
                        adminData['username'] = newName;
                      });

                      Navigator.pop(dialogContext);
                      _showMessage('Profil berhasil diperbarui');
                    } catch (e) {
                      _showMessage('Gagal memperbarui profil: $e');
                    } finally {
                      if (mounted) {
                        setState(() => _isSaving = false);
                      }
                    }
                  },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    nameController.dispose();
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
    Color titleColor = AppColors.textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePassword() async {
    final passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Password baru (minimal 6 karakter)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPassword = passwordController.text.trim();

              if (newPassword.length < 6) {
                _showMessage('Password minimal 6 karakter');
                return;
              }

              try {
                await supabase.auth.updateUser(
                  UserAttributes(password: newPassword),
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);
                _showMessage('Password berhasil diperbarui');
              } catch (e) {
                _showMessage('Gagal mengubah password: $e');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    passwordController.dispose();
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeAdminPage()),
        (route) => false,
      );
    } catch (e) {
      _showMessage('Gagal logout: $e');
    }
  }

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
            _buildNavItem(Icons.apartment_outlined, 'Data Kost', false),
            _buildNavItem(Icons.chat_bubble_outline, 'Chat', false),
            _buildNavItem(Icons.person, 'Profil', true),
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
              MaterialPageRoute(
                builder: (_) => const HomeAdminPage(),
              ),
            );
            break;
          case 'Data Kost':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DataKostPage(),
              ),
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
            break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}