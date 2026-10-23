
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import 'data_kost_page.dart';
import 'daftar_chat_admin_page.dart';
import 'profil_admin_page.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, int>> _fetchRingkasanProperti() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return {'totalKost': 0, 'totalKamarTersedia': 0};
    }

    try {
      final response = await supabase
          .from('kost')
          .select('ketersediaan_kamar')
          .eq('id_user', user.id);

      final data = List<Map<String, dynamic>>.from(response);
      int totalKamarTersedia = 0;

      for (final item in data) {
        final kamar = int.tryParse(
              item['ketersediaan_kamar']?.toString() ?? '0',
            ) ??
            0;
        totalKamarTersedia += kamar;
      }

      return {
        'totalKost': data.length,
        'totalKamarTersedia': totalKamarTersedia,
      };
    } catch (e) {
      debugPrint('Gagal mengambil ringkasan kost: $e');
      return {'totalKost': 0, 'totalKamarTersedia': 0};
    }
  }

  // PERBAIKAN: Statistik chat berdasarkan ID admin yang login.
  Future<Map<String, int>> _fetchStatistikChat() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return {'pesanMasuk': 0, 'totalChat': 0};
    }

    try {
      final response = await supabase
          .from('messages')
          .select('id_message, pengirim_id, penerima_id')
          .or(
            'pengirim_id.eq.${user.id},penerima_id.eq.${user.id}',
          );

      final rows = List<Map<String, dynamic>>.from(response);

      int pesanMasuk = 0;

      // Satu pengguna dihitung sebagai satu percakapan,
      // sesuai pengelompokan di daftar chat admin.
      final Set<String> percakapan = {};

      for (final row in rows) {
        final pengirimId = row['pengirim_id']?.toString();
        final penerimaId = row['penerima_id']?.toString();

        // Abaikan pesan yang tidak memiliki ID pengirim/penerima.
        if (pengirimId == null ||
            penerimaId == null ||
            pengirimId.isEmpty ||
            penerimaId.isEmpty) {
          continue;
        }

        // Abaikan pesan yang dikirim ke akun sendiri.
        if (pengirimId == penerimaId) {
          continue;
        }

        // Pesan masuk adalah pesan yang penerimanya admin login.
        if (penerimaId == user.id) {
          pesanMasuk++;
        }

        // Tentukan lawan bicara dari sudut pandang admin.
        String? lawanBicara;

        if (pengirimId == user.id) {
          lawanBicara = penerimaId;
        } else if (penerimaId == user.id) {
          lawanBicara = pengirimId;
        }

        if (lawanBicara != null &&
            lawanBicara.isNotEmpty &&
            lawanBicara != user.id) {
          percakapan.add(lawanBicara);
        }
      }

      return {
        'pesanMasuk': pesanMasuk,
        'totalChat': percakapan.length,
      };
    } catch (e, stackTrace) {
      debugPrint('Gagal mengambil statistik chat: $e');
      debugPrintStack(stackTrace: stackTrace);

      return {'pesanMasuk': 0, 'totalChat': 0};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchKostTerbaru() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    try {
      final response = await supabase
          .from('kost')
          .select('*, foto_kost(foto)')
          .eq('id_user', user.id)
          .order('created_at', ascending: false)
          .limit(3);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Gagal mengambil kost terbaru: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildRingkasanProperti(),
              const SizedBox(height: 16),
              _buildBannerKelolaUnit(context),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Kost Terbaru'),
              const SizedBox(height: 12),
              _buildDaftarKostTerbaru(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // HEADER HOME: ikon profil tambahan dihapus.
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KOSTRADAR ADMIN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Home',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRingkasanProperti() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchRingkasanProperti(),
      builder: (context, snapshot) {
        final totalKost = snapshot.data?['totalKost'] ?? 0;
        final totalKamar =
            snapshot.data?['totalKamarTersedia'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pantau aktivitas kost dan calon penghuni hari ini',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '• Aktif',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.apartment,
                      iconBg: AppColors.primaryLight,
                      iconColor: AppColors.primary,
                      value: snapshot.connectionState ==
                              ConnectionState.waiting
                          ? '...'
                          : totalKost.toString(),
                      label: 'Total Kost',
                      badgeText: 'Terdaftar',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.door_front_door_outlined,
                      iconBg: AppColors.successLight,
                      iconColor: AppColors.success,
                      value: snapshot.connectionState ==
                              ConnectionState.waiting
                          ? '...'
                          : totalKamar.toString(),
                      label: 'Kamar Tersedia',
                      badgeText: 'Siap huni',
                      badgeColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, int>>(
                future: _fetchStatistikChat(),
                builder: (context, chatSnapshot) {
                  final statistik = chatSnapshot.data ??
                      {'pesanMasuk': 0, 'totalChat': 0};

                  final sedangMemuat =
                      chatSnapshot.connectionState ==
                          ConnectionState.waiting;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.mail_outline,
                          iconBg: AppColors.primaryLight,
                          iconColor: AppColors.primary,
                          value: sedangMemuat
                              ? '...'
                              : (statistik['pesanMasuk'] ?? 0)
                                  .toString(),
                          label: 'Pesan Masuk',
                          badgeText:
                              sedangMemuat ? 'Memuat' : 'Aktual',
                          badgeColor: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.chat_bubble_outline,
                          iconBg: AppColors.primaryLight,
                          iconColor: AppColors.primary,
                          value: sedangMemuat
                              ? '...'
                              : (statistik['totalChat'] ?? 0)
                                  .toString(),
                          label: 'Total Chat',
                          badgeText: 'Percakapan',
                          badgeColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required String badgeText,
    Color badgeColor = AppColors.success,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              Flexible(
                child: Text(
                  badgeText,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerKelolaUnit(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DataKostPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_business,
                color: AppColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelola Unit Baru',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tambahkan kamar & perbarui ketersediaan',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DataKostPage(),
              ),
            );
          },
          child: const Row(
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaftarKostTerbaru() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchKostTerbaru(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Belum ada unit kost terbaru.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final listKost = snapshot.data!;

        return Column(
          children: listKost.map((item) {
            final harga = double.tryParse(
                  item['harga']?.toString() ?? '0',
                ) ??
                0.0;

            final formattedHarga =
                'Rp ${harga.toInt().toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.',
                    )}';

            final listFoto =
                item['foto_kost'] as List<dynamic>? ?? [];

            final fotoUrl = listFoto.isNotEmpty
                ? listFoto.first['foto']?.toString() ?? ''
                : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: fotoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              fotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Icon(
                                  Icons.image,
                                  color: AppColors.primary,
                                  size: 26,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.apartment,
                            size: 26,
                            color: AppColors.textSecondary,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nama']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$formattedHarga/bulan',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Tersedia ${item['ketersediaan_kamar'] ?? 0} kamar',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
            _buildNavItem(context, Icons.home, 'Home', true),
            _buildNavItem(
              context,
              Icons.apartment,
              'Data Kost',
              false,
            ),
            _buildNavItem(
              context,
              Icons.chat_bubble_outline,
              'Chat',
              false,
            ),
            _buildNavItem(
              context,
              Icons.person_outline,
              'Profil',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
  ) {
    final color =
        isActive ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        switch (label) {
          case 'Home':
            break;

          case 'Data Kost':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DataKostPage(),
              ),
            );
            break;

          case 'Chat':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const DaftarChatAdminPage(chatData: {}),
              ),
            );
            break;

          case 'Profil':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilAdminPage(),
              ),
            );
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
                fontWeight: isActive
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
