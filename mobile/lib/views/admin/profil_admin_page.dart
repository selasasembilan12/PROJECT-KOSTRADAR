
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isUploadingPhoto = false;

  String _username = 'Admin';
  String _email = '';
  String _fotoProfile = '';

  int _jumlahKost = 0;
  int _jumlahKamar = 0;

  static const Color _background = Color(0xFFF4F6FA);
  static const Color _primary = Color(0xFF1765D8);
  static const Color _textDark = Color(0xFF172033);
  static const Color _textMuted = Color(0xFF778399);
  static const Color _border = Color(0xFFE5EAF1);
  static const Color _danger = Color(0xFFDC3636);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // =========================================================
  // MEMUAT PROFIL ADMIN DAN STATISTIK KOST
  // =========================================================

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final metadata = user.userMetadata ?? {};

    _username = metadata['username']?.toString() ??
        metadata['nama']?.toString() ??
        user.email?.split('@').first ??
        'Admin';

    _email = user.email ?? '';
    _fotoProfile = metadata['foto_profile']?.toString() ?? '';

    try {
      final profile = await supabase
          .from('users')
          .select('id_user, username, email, foto_profile')
          .eq('id_user', user.id)
          .maybeSingle();

      if (profile != null) {
        _username =
            profile['username']?.toString().trim().isNotEmpty == true
                ? profile['username'].toString()
                : _username;

        _email = profile['email']?.toString() ?? _email;

        _fotoProfile =
            profile['foto_profile']?.toString().isNotEmpty == true
                ? profile['foto_profile'].toString()
                : _fotoProfile;
      }
    } catch (e) {
      debugPrint('Gagal memuat profil admin: $e');
    }

    try {
      final kostList = await supabase
          .from('kost')
          .select('ketersediaan_kamar')
          .eq('id_user', user.id);

      _jumlahKost = kostList.length;
      _jumlahKamar = 0;

      for (final kost in kostList) {
        _jumlahKamar +=
            int.tryParse(
              (kost['ketersediaan_kamar'] ?? 0).toString(),
            ) ??
            0;
      }
    } catch (e) {
      debugPrint('Gagal memuat statistik kost: $e');
    }

    if (!mounted) return;

    setState(() => _isLoading = false);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // FOTO PROFIL
  // =========================================================

  Future<String> _uploadProfilePhoto(XFile image) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Admin belum login.');
    }

    final bytes = await image.readAsBytes();
    final extension = image.name.split('.').last.toLowerCase();

    final contentType =
        extension == 'jpg' || extension == 'jpeg'
            ? 'image/jpeg'
            : 'image/$extension';

    final path =
        'profile_admin/${user.id}/foto_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await supabase.storage.from('kost-images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: true,
      ),
    );

    return supabase.storage.from('kost-images').getPublicUrl(path);
  }

  Future<void> _changeProfilePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null || !mounted) return;

      setState(() => _isUploadingPhoto = true);

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Admin belum login.');
      }

      final imageUrl = await _uploadProfilePhoto(image);

      final updatedRows = await supabase
          .from('users')
          .update({'foto_profile': imageUrl})
          .eq('id_user', user.id)
          .select('id_user');

      if (updatedRows.isEmpty) {
        throw Exception(
          'Data admin tidak ditemukan pada tabel users.',
        );
      }

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'username': _username,
            'foto_profile': imageUrl,
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        _fotoProfile = imageUrl;
        _isUploadingPhoto = false;
      });

      _showMessage('Foto profil berhasil diperbarui.');
    } catch (e) {
      debugPrint('Gagal mengganti foto profil: $e');

      if (!mounted) return;

      setState(() => _isUploadingPhoto = false);
      _showMessage('Gagal memperbarui foto: $e');
    }
  }

  // =========================================================
  // EDIT PROFIL
  // =========================================================

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _username);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profil Admin'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _changeProfilePhoto,
                        child: Stack(
                          children: [
                            _avatar(radius: 35),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 13,
                                backgroundColor: _primary,
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Admin',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Nama wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _email,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email akun',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            final user = supabase.auth.currentUser;

                            if (user == null) {
                              throw Exception('Admin belum login.');
                            }

                            final nama = nameController.text.trim();

                            final rows = await supabase
                                .from('users')
                                .update({'username': nama})
                                .eq('id_user', user.id)
                                .select('id_user');

                            if (rows.isEmpty) {
                              throw Exception(
                                'Data admin tidak ditemukan pada tabel users.',
                              );
                            }

                            await supabase.auth.updateUser(
                              UserAttributes(
                                data: {
                                  'username': nama,
                                  'foto_profile': _fotoProfile,
                                },
                              ),
                            );

                            if (!mounted) return;

                            setState(() => _username = nama);

                            Navigator.pop(dialogContext);
                            _showMessage('Profil berhasil diperbarui.');
                          } catch (e) {
                            _showMessage(
                              'Gagal menyimpan profil: $e',
                            );
                            setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
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
  }

  // =========================================================
  // UBAH PASSWORD
  // =========================================================

  Future<void> _changePassword() async {
    final controller = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password baru',
            helperText: 'Minimal 6 karakter',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, controller.text);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (password == null) return;

    if (password.trim().length < 6) {
      _showMessage('Password minimal 6 karakter.');
      return;
    }

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: password.trim()),
      );

      _showMessage('Password berhasil diperbarui.');
    } catch (e) {
      _showMessage('Gagal mengubah password: $e');
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      _showMessage('Gagal logout: $e');
    }
  }

  // =========================================================
  // KOMPONEN UI
  // =========================================================

  Widget _avatar({double radius = 38}) {
    final hasPhoto = _fotoProfile.startsWith('http');

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE5EEFF),
      backgroundImage:
          hasPhoto ? NetworkImage(_fotoProfile) : null,
      child: _isUploadingPhoto
          ? const CircularProgressIndicator(
              color: _primary,
              strokeWidth: 2,
            )
          : !hasPhoto
              ? Icon(
                  Icons.person,
                  size: radius,
                  color: _primary,
                )
              : null,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Text(
        title,
        style: const TextStyle(
          color: _textDark,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _panel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _statistic({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _primary, size: 21),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? _danger : _primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              width: 41,
              height: 41,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: danger ? _danger : _textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: _textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TAMPILAN PROFIL ADMIN
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _primary,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadProfile,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    24,
                  ),
                  children: [
                    // HEADER TANPA TOMBOL REFRESH
                    Row(
                      children: [
                        Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.home_work_outlined,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KOSTRADAR ADMIN',
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Profil',
                                style: TextStyle(
                                  color: _textDark,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // KARTU PROFIL
                    _panel(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              _avatar(radius: 42),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: _isUploadingPhoto
                                      ? null
                                      : _changeProfilePhoto,
                                  child: Container(
                                    width: 27,
                                    height: 27,
                                    decoration: const BoxDecoration(
                                      color: _primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _username,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _textDark,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit profil',
                                onPressed: _editProfile,
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: _primary,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5EEFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: _primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 19),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              children: [
                                _statistic(
                                  value: '$_jumlahKost',
                                  label: 'Unit Kost',
                                  icon: Icons.apartment_rounded,
                                ),
                                Container(
                                  height: 48,
                                  width: 1,
                                  color: _border,
                                ),
                                _statistic(
                                  value: '$_jumlahKamar',
                                  label: 'Kamar Tersedia',
                                  icon: Icons.bed_outlined,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 23),

                    // PENGATURAN AKUN
                    _sectionTitle('Pengaturan Akun & Bisnis'),
                    _panel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _settingItem(
                            icon: Icons.manage_accounts_outlined,
                            title: 'Edit Profil',
                            subtitle: 'Informasi nama dan foto',
                            onTap: _editProfile,
                          ),
                          const Divider(
                            height: 1,
                            indent: 65,
                            endIndent: 12,
                            color: _border,
                          ),
                          _settingItem(
                            icon: Icons.lock_outline_rounded,
                            title: 'Ubah Password',
                            subtitle: 'Keamanan autentikasi akun',
                            onTap: _changePassword,
                          ),
                          const Divider(
                            height: 1,
                            indent: 65,
                            endIndent: 12,
                            color: _border,
                          ),
                          _settingItem(
                            icon: Icons.logout_rounded,
                            title: 'Keluar / Logout',
                            subtitle: 'Keluar dari akun admin',
                            danger: true,
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // =========================================================
  // NAVIGASI BAWAH
  // =========================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _navItem(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeAdminPage(),
                  ),
                );
              },
            ),
            _navItem(
              icon: Icons.apartment_outlined,
              label: 'Data Kost',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DataKostPage(),
                  ),
                );
              },
            ),
            _navItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DaftarChatAdminPage(
                      chatData: {},
                    ),
                  ),
                );
              },
            ),
            _navItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              selected: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final color = selected ? _primary : _textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
