//SALSA
//MINTA TOLONG SKALI JANG KORE SINI, KASE TAU SA NANTI KT YANG PERBAIKI. info di gc
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final supabase = Supabase.instance.client;
  
  String nama = "Pengguna KostRadar";
  String email = "Memuat...";
  String? fotoUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final userEmail = user.email ?? 'Tidak ada email';
        String userName = 'Pengguna KostRadar';
        String? userFoto;

        try {
          final data = await supabase
              .from('users')
              .select()
              .eq('id_user', user.id)
              .maybeSingle();

          if (data != null) {
            userName = data['username'] ?? 'Pengguna KostRadar';
            userFoto = data['foto'];
          }
        } catch (dbError) {
          debugPrint("Info DB load: $dbError");
        }

        if (mounted) {
          setState(() {
            email = userEmail;
            nama = userName;
            fotoUrl = userFoto;
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error umum load: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _gantiFotoProfil() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (image == null) return;

      final user = supabase.auth.currentUser;
      if (user == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengunggah foto profil...')),
      );

      final fileName = 'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Murni pakai bytes, TIDAK ADA PEMANGGILAN File(image.path) SAMA SEKALI
      final bytes = await image.readAsBytes();

      await supabase.storage.from('avatars').uploadBinary(
        fileName, 
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase.from('users').update({
        'foto': publicUrl,
      }).eq('id_user', user.id);

      setState(() {
        fotoUrl = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah foto: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _bukaFormEditProfil() {
    final TextEditingController namaController = TextEditingController(text: nama);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap (Username)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final newName = namaController.text.trim();
                    if (newName.isEmpty) return;

                    final user = supabase.auth.currentUser;
                    if (user != null) {
                      try {
                        await supabase
                            .from('users')
                            .update({'username': newName})
                            .eq('id_user', user.id);

                        setState(() {
                          nama = newName;
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil berhasil diperbarui!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menyimpan: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _bukaFormUbahPassword() {
    final TextEditingController passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final newPassword = passController.text.trim();
                    if (newPassword.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password minimal 6 karakter!'), backgroundColor: AppColors.error),
                      );
                      return;
                    }

                    try {
                      await supabase.auth.updateUser(UserAttributes(password: newPassword));
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password berhasil diubah!'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal ubah password: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _gantiFotoProfil,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: fotoUrl != null && fotoUrl!.isNotEmpty
                        ? NetworkImage(fotoUrl!)
                        : const NetworkImage('https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=200'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.white, width: 2),
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              nama,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Mahasiswa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(radius: 3, backgroundColor: AppColors.success),
                  SizedBox(width: 4),
                  Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                children: [
                  _buildMenuItem(
                    icon: Icons.edit_outlined,
                    iconBg: AppColors.primaryLight,
                    iconColor: AppColors.primary,
                    title: 'Edit Profil',
                    subtitle: 'Ubah nama lengkap',
                    onTap: _bukaFormEditProfil,
                  ),
                  const Divider(height: 1, color: AppColors.border, indent: 60),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    iconBg: AppColors.primaryLight,
                    iconColor: AppColors.primary,
                    title: 'Ubah Password',
                    subtitle: 'Perbarui kata sandi akun',
                    onTap: _bukaFormUbahPassword,
                  ),
                  const Divider(height: 1, color: AppColors.border, indent: 60),
                  _buildMenuItem(
                    icon: Icons.logout,
                    iconBg: AppColors.errorLight,
                    iconColor: AppColors.error,
                    title: 'Logout',
                    subtitle: 'Keluar dari akun Anda',
                    isDestructive: true,
                    onTap: () async {
                      await supabase.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? AppColors.error : AppColors.textHint,
      ),
      onTap: onTap,
    );
  }
}