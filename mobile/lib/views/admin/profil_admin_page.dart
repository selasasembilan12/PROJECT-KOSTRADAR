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
    'username': 'Admin',
    'email': '',
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

      if (user == null) {
        throw Exception('Admin belum login');
      }

      // Ambil profil utama dari tabel public.users.
      final profile = await supabase
          .from('users')
          .select('id_user, username, email, foto_profile')
          .eq('id_user', user.id)
          .maybeSingle();

      final metadata = user.userMetadata ?? {};

      if (profile != null) {
        adminData = {
          'username': profile['username'] ??
              metadata['username'] ??
              user.email?.split('@').first ??
              'Admin',
          'email': profile['email'] ?? user.email ?? '',
          'foto_profile': profile['foto_profile'] ??
              metadata['foto_profile'] ??
              '',
        };
      } else {
        // Fallback agar halaman tetap bisa dibuka jika baris users
        // belum tersedia. Penyimpanan tetap akan memberi pesan error.
        adminData = {
          'username': metadata['username'] ??
              user.email?.split('@').first ??
              'Admin',
          'email': user.email ?? '',
          'foto_profile': metadata['foto_profile'] ?? '',
        };
        debugPrint(
          'Baris public.users tidak ditemukan untuk UUID ${user.id}',
        );
      }
    } catch (e) {
      debugPrint('Gagal mengambil profil admin: $e');
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

  Future<String> _uploadProfilePhoto(XFile image) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Admin belum login');
    }

    final bytes = await image.readAsBytes();
    final ext = image.name.split('.').last.toLowerCase();

    final path =
        'profile_admin/${user.id}/foto_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await supabase.storage.from('kost-images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: ext == 'jpg' || ext == 'jpeg'
            ? 'image/jpeg'
            : 'image/$ext',
      ),
    );

    return supabase.storage.from('kost-images').getPublicUrl(path);
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null || !mounted) return;

      setState(() => _isUploadingPhoto = true);

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Admin belum login');
      }

      final imageUrl = await _uploadProfilePhoto(image);

      // Simpan foto ke tabel public.users terlebih dahulu.
      final updatedRows = await supabase
          .from('users')
          .update({'foto_profile': imageUrl})
          .eq('id_user', user.id)
          .select('id_user');

      if (updatedRows.isEmpty) {
        throw Exception(
          'Baris admin tidak ditemukan di public.users. '
          'Pastikan id_user sama dengan UUID akun Supabase Auth.',
        );
      }

      // Sinkronkan juga metadata Auth.
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'username': adminData['username'],
            'foto_profile': imageUrl,
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        adminData['foto_profile'] = imageUrl;
        _isUploadingPhoto = false;
      });

      _showMessage('Foto profil berhasil disimpan ke database');
    } catch (e) {
      debugPrint('Gagal menyimpan foto profil: $e');

      if (!mounted) return;

      setState(() => _isUploadingPhoto = false);
      _showMessage('Gagal menyimpan foto profil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = adminData['username'] as String? ?? 'Admin';
    final email = adminData['email'] as String? ?? '';
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
                          _buildProfileCard(
                            username,
                            email,
                            fotoProfile,
                          ),
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

  // HEADER: ikon profil tambahan sudah dihapus.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.centerLeft,
      child: const Text(
        'Profil Admin',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
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
              _buildAvatar(fotoProfile, 90),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
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
              Flexible(
                child: Text(
                  username,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _editProfile,
                child: const Icon(
                  Icons.edit,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.email_outlined,
            email.isEmpty ? '-' : email,
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

  Widget _buildAvatar(String fotoProfile, double size) {
    return Container(
      width: size,
      height: size,
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
          : ClipOval(
              child: fotoProfile.isNotEmpty
                  ? Image.network(
                      fotoProfile,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person,
                        size: size * 0.5,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: size * 0.5,
                      color: AppColors.primary,
                    ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(
      text: adminData['username'] as String? ?? '',
    );

    final emailController = TextEditingController(
      text: adminData['email'] as String? ?? '',
    );

    XFile? fotoBaru;
    bool savingInDialog = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextDialog, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profil Admin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: savingInDialog
                          ? null
                          : () async {
                              final image = await _picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );

                              if (image != null) {
                                setDialogState(() => fotoBaru = image);
                              }
                            },
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: fotoBaru != null
                            ? FileImage(File(fotoBaru!.path))
                            : ((adminData['foto_profile'] as String?)
                                            ?.isNotEmpty ??
                                        false)
                                ? NetworkImage(
                                    adminData['foto_profile'] as String,
                                  )
                                : null,
                        child: fotoBaru == null &&
                                ((adminData['foto_profile'] as String?)
                                        ?.isNotEmpty !=
                                    true)
                            ? const Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Ketuk foto untuk mengganti'),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Admin',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: savingInDialog
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: savingInDialog
                      ? null
                      : () async {
                          final nama = nameController.text.trim();
                          final email = emailController.text.trim();

                          if (nama.isEmpty || email.isEmpty) {
                            _showMessage('Nama dan email wajib diisi');
                            return;
                          }

                          if (!email.contains('@')) {
                            _showMessage('Format email tidak valid');
                            return;
                          }

                          setDialogState(() => savingInDialog = true);
                          setState(() => _isSaving = true);

                          try {
                            final user = supabase.auth.currentUser;

                            if (user == null) {
                              throw Exception('Admin belum login');
                            }

                            String fotoUrl =
                                adminData['foto_profile'] as String? ?? '';

                            if (fotoBaru != null) {
                              fotoUrl =
                                  await _uploadProfilePhoto(fotoBaru!);
                            }

                            final emailBerubah = email != user.email;

                            debugPrint('UUID Auth: ${user.id}');
                            debugPrint('Username yang akan disimpan: $nama');

                            // Simpan nama dan foto ke database aplikasi.
                            // Email ikut diperbarui pada tabel users agar
                            // konsisten dengan data profil yang ditampilkan.
                            final updatedRows = await supabase
                                .from('users')
                                .update({
                                  'username': nama,
                                  'foto_profile': fotoUrl,
                                  'email': email,
                                })
                                .eq('id_user', user.id)
                                .select('id_user, username, foto_profile');

                            debugPrint('Hasil update database: $updatedRows');

                            if (updatedRows.isEmpty) {
                              throw Exception(
                                'Profil admin tidak ditemukan di public.users. '
                                'Pastikan id_user sama dengan UUID akun Auth.',
                              );
                            }

                            // Sinkronkan metadata Supabase Auth.
                            await supabase.auth.updateUser(
                              UserAttributes(
                                data: {
                                  'username': nama,
                                  'foto_profile': fotoUrl,
                                },
                                email: emailBerubah ? email : null,
                              ),
                            );

                            if (!mounted) return;

                            setState(() {
                              adminData['username'] = nama;
                              adminData['email'] = email;
                              adminData['foto_profile'] = fotoUrl;
                            });

                            Navigator.pop(dialogContext);

                            _showMessage(
                              emailBerubah
                                  ? 'Profil tersimpan. Perubahan email mungkin memerlukan konfirmasi.'
                                  : 'Profil berhasil diperbarui',
                            );
                          } catch (e) {
                            _showMessage(
                              'Gagal memperbarui profil: $e',
                            );
                            setDialogState(
                              () => savingInDialog = false,
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isSaving = false);
                            }
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
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
                color: iconColor.withValues(alpha: 0.1),
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
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextDialog, setDialogState) {
            return AlertDialog(
              title: const Text('Ubah Password'),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password baru (minimal 6 karakter)',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final password =
                              passwordController.text.trim();

                          if (password.length < 6) {
                            _showMessage(
                              'Password minimal 6 karakter',
                            );
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            await supabase.auth.updateUser(
                              UserAttributes(password: password),
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);
                            _showMessage('Password berhasil diperbarui');
                          } catch (e) {
                            _showMessage(
                              'Gagal mengubah password: $e',
                            );
                            setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
  }

  // LOGOUT: mengakhiri sesi Supabase dan menghapus
  // seluruh halaman admin dari navigation stack.
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

      // Rute login harus sudah terdaftar di aplikasi.
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
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
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
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

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool active,
  ) {
    final color =
        active ? AppColors.primary : AppColors.textSecondary;

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
                builder: (_) => const DaftarChatAdminPage(
                  chatData: {},
                ),
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
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}