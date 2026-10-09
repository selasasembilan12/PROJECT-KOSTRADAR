//Riana

import 'package:flutter/material.dart';

const Color warnaBiru = Color(0xFF2563EB);
const Color warnaLatarProfil = Color(0xFFF7F8FC);
const Color warnaTeksProfil = Color(0xFF172033);
const Color warnaAbuProfil = Color(0xFF64748B);

class ProfilAdminPage extends StatefulWidget {
  const ProfilAdminPage({super.key});

  @override
  State<ProfilAdminPage> createState() => _ProfilAdminPageState();
}

class _ProfilAdminPageState extends State<ProfilAdminPage> {
  String nama = 'Pak Hermawan';
  String email = 'admin@kostradar.com';
  String kost = 'Kost Adawarna';
  String telepon = '081234567890';

  bool menerimaTamu = true;
  String kataSandi = 'admin123';

  void pesan(String isi) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(isi),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> editProfil() async {
    final namaC = TextEditingController(text: nama);
    final emailC = TextEditingController(text: email);
    final kostC = TextEditingController(text: kost);
    final teleponC = TextEditingController(text: telepon);
    final formKey = GlobalKey<FormState>();

    final simpan = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(namaC, 'Nama admin'),
                  const SizedBox(height: 12),
                  _field(
                    emailC,
                    'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())) {
                        return 'Masukkan email yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(kostC, 'Nama kost'),
                  const SizedBox(height: 12),
                  _field(
                    teleponC,
                    'Nomor telepon',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate() &&
                  namaC.text.trim().isNotEmpty &&
                  kostC.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (simpan == true && mounted) {
      setState(() {
        nama = namaC.text.trim();
        email = emailC.text.trim();
        kost = kostC.text.trim();
        telepon = teleponC.text.trim();
      });

      pesan('Profil berhasil diperbarui.');
    }

    namaC.dispose();
    emailC.dispose();
    kostC.dispose();
    teleponC.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label wajib diisi';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> ubahPassword() async {
    final lamaC = TextEditingController();
    final baruC = TextEditingController();
    final konfirmasiC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool tampilLama = false;
    bool tampilBaru = false;
    bool tampilKonfirmasi = false;

    final simpan = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (contextDialog, setDialogState) => AlertDialog(
          title: const Text('Ubah Password'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _passwordField(
                      lamaC,
                      'Password saat ini',
                      tampil: tampilLama,
                      ubahTampil: () => setDialogState(
                        () => tampilLama = !tampilLama,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password saat ini wajib diisi';
                        }
                        if (value != kataSandi) {
                          return 'Password saat ini salah';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _passwordField(
                      baruC,
                      'Password baru',
                      tampil: tampilBaru,
                      ubahTampil: () => setDialogState(
                        () => tampilBaru = !tampilBaru,
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Minimal 6 karakter';
                        }
                        if (value == kataSandi) {
                          return 'Gunakan password yang berbeda';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _passwordField(
                      konfirmasiC,
                      'Konfirmasi password baru',
                      tampil: tampilKonfirmasi,
                      ubahTampil: () => setDialogState(
                        () => tampilKonfirmasi = !tampilKonfirmasi,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi password wajib diisi';
                        }
                        if (value != baruC.text) {
                          return 'Password tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password awal simulasi: admin123',
                        style: TextStyle(
                          color: warnaAbuProfil,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (simpan == true && mounted) {
      setState(() => kataSandi = baruC.text);
      pesan('Password berhasil diubah untuk sesi percobaan.');
    }

    lamaC.dispose();
    baruC.dispose();
    konfirmasiC.dispose();
  }

  Widget _passwordField(
    TextEditingController controller,
    String label, {
    required bool tampil,
    required VoidCallback ubahTampil,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !tampil,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return '$label wajib diisi';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: tampil ? 'Sembunyikan password' : 'Tampilkan password',
          onPressed: ubahTampil,
          icon: Icon(
            tampil ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> logout() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar / Logout'),
        content: const Text(
          'Yakin ingin keluar dari halaman admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (yakin == true && mounted) {
      pesan('Logout masih simulasi; autentikasi belum terhubung.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warnaLatarProfil,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                    children: [
                      _kartuProfil(),
                      const SizedBox(height: 18),
                      _statusTamu(),
                      const SizedBox(height: 22),
                      const Text(
                        'PENGATURAN AKUN & BISNIS',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.6,
                          color: warnaAbuProfil,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _menu(
                        ikon: Icons.manage_accounts_outlined,
                        warna: warnaBiru,
                        judul: 'Edit Profil',
                        deskripsi: 'Informasi nama dan kontak',
                        aksi: editProfil,
                      ),
                      _menu(
                        ikon: Icons.lock_reset_rounded,
                        warna: warnaAbuProfil,
                        judul: 'Ubah Password',
                        deskripsi: 'Keamanan akun admin',
                        aksi: ubahPassword,
                      ),
                      _menu(
                        ikon: Icons.logout_rounded,
                        warna: Colors.red,
                        judul: 'Keluar / Logout',
                        deskripsi: 'Keluar dari akun admin',
                        aksi: logout,
                        merah: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _navigasiBawah(),
    );
  }

  Widget _header() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          const Icon(
            Icons.home_work_rounded,
            color: warnaBiru,
            size: 18,
          ),
          const SizedBox(width: 7),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KOSTRADAR ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    color: warnaAbuProfil,
                    letterSpacing: 0.7,
                  ),
                ),
                Text(
                  'Profil',
                  style: TextStyle(
                    fontSize: 15,
                    color: warnaTeksProfil,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: warnaBiru,
            child: const Icon(
              Icons.person,
              size: 19,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuProfil() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE0F2FE),
            child: Icon(
              Icons.person_rounded,
              size: 48,
              color: Color(0xFF47718C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: warnaTeksProfil,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: warnaAbuProfil,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            kost,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: warnaAbuProfil,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: warnaBiru, size: 13),
                SizedBox(width: 4),
                Text(
                  'Pengelola Kost',
                  style: TextStyle(
                    color: warnaBiru,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '12',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: warnaBiru,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Unit Kost',
                        style: TextStyle(
                          color: warnaAbuProfil,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '28',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: warnaTeksProfil,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Total Kamar',
                        style: TextStyle(
                          color: warnaAbuProfil,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Telepon: $telepon',
              style: const TextStyle(
                fontSize: 12,
                color: warnaAbuProfil,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTamu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Color(0xFF15803D),
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Penerimaan Tamu',
                  style: TextStyle(
                    color: warnaTeksProfil,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  menerimaTamu
                      ? 'Aktif Menerima Reservasi'
                      : 'Tidak Menerima Reservasi',
                  style: TextStyle(
                    color: menerimaTamu
                        ? const Color(0xFF15803D)
                        : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: menerimaTamu,
            activeThumbColor: warnaBiru,
            onChanged: (value) {
              setState(() => menerimaTamu = value);
              pesan(
                value
                    ? 'Penerimaan reservasi diaktifkan.'
                    : 'Penerimaan reservasi dinonaktifkan.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _menu({
    required IconData ikon,
    required Color warna,
    required String judul,
    required String deskripsi,
    required VoidCallback aksi,
    bool merah = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: aksi,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(ikon, color: warna, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: TextStyle(
                        fontSize: 13,
                        color: merah ? Colors.red : warnaTeksProfil,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deskripsi,
                      style: const TextStyle(
                        fontSize: 11,
                        color: warnaAbuProfil,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navigasiBawah() {
    return BottomNavigationBar(
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: warnaBiru,
      unselectedItemColor: warnaAbuProfil,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      onTap: (index) {
        if (index == 3) return;

        if (index == 2) {
          Navigator.of(context).pop();
          return;
        }

        pesan(
          index == 0
              ? 'Halaman Home belum tersedia pada percobaan ini.'
              : 'Halaman Data Kost belum tersedia pada percobaan ini.',
        );
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apartment_outlined),
          label: 'Data Kost',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Profil',
        ),
      ],
    );
  }
}

