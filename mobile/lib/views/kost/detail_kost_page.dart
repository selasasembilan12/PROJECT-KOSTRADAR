import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

import '../../models/kost_model.dart';

class DetailKostPage extends StatefulWidget {
  // Data kost dari halaman sebelumnya
  final KostModel kost;

  const DetailKostPage({super.key, required this.kost});

  @override
  State<DetailKostPage> createState() => _DetailKostPageState();
}

class _DetailKostPageState extends State<DetailKostPage> {
  // Status favorit kost
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    cekFavorite();
  }

  // Mengecek apakah kost sudah ada di favorit
  Future<void> cekFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('favorite')
        .select()
        .eq('id_user', user.id)
        .eq('id_kost', widget.kost.idKost)
        .maybeSingle();

    setState(() {
      isFavorite = data != null;
    });
  }

  // Tambah / hapus favorit database
  Future<void> toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (isFavorite) {
      await Supabase.instance.client
          .from('favorite')
          .delete()
          .eq('id_user', user.id)
          .eq('id_kost', widget.kost.idKost);
    } else {
      await Supabase.instance.client.from('favorite').insert({
        'id_user': user.id,
        'id_kost': widget.kost.idKost,
      });
    }

    setState(() {
      isFavorite = !isFavorite;
    });
  }

  // Tombol kembali
  void goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // <-- DIUBAH
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FOTO KOST
                Stack(
                  children: [
                    Image.network(
                      widget.kost.foto.isNotEmpty ? widget.kost.foto[0] : "",
                      height: 330,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 330,
                          width: double.infinity,
                          color: AppColors.backgroundGray, // <-- DIUBAH
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: AppColors.textHint, // <-- DIUBAH
                            ),
                          ),
                        );
                      },
                    ),

                    // Tombol kembali
                    Positioned(
                      top: 40,
                      left: 20,
                      child: circleButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: goBack,
                        color: AppColors.textPrimary, // <-- DIUBAH
                      ),
                    ),

                    // Tombol share
                    Positioned(
                      top: 40,
                      right: 70,
                      child: circleButton(
                        icon: Icons.share_outlined,
                        color: AppColors.textPrimary, // <-- DIUBAH
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Fitur bagikan akan segera tersedia",
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Tombol favorit
                    Positioned(
                      top: 40,
                      right: 20,
                      child: circleButton(
                        icon: isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFavorite
                            ? AppColors.error
                            : AppColors.textPrimary, // <-- DIUBAH
                        onTap: toggleFavorite,
                      ),
                    ),

                    // Jumlah foto
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors
                              .black54, // Tetap black54 untuk overlay gambar
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 14,
                              color: AppColors.white,
                            ), // <-- DIUBAH
                            SizedBox(width: 5),
                            Text(
                              "Foto", // Disederhanakan atau bisa pakai "${widget.kost.foto.length} Foto"
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                              ), // <-- DIUBAH
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // DETAIL KOST
                Container(
                  transform: Matrix4.translationValues(0, -20, 0),
                  padding: const EdgeInsets.all(
                    AppSpacing.defaultPadding,
                  ), // <-- DIUBAH
                  decoration: const BoxDecoration(
                    color: AppColors.white, // <-- DIUBAH
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge tipe dan verifikasi
                      Row(
                        children: [
                          badge(
                            "Campur",
                            AppColors.chipBackground,
                            AppColors.textPrimary,
                          ), // <-- DIUBAH
                          const SizedBox(width: 8),
                          badge(
                            "✓ Terverifikasi",
                            AppColors.successLight,
                            AppColors.success,
                          ), // <-- DIUBAH
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Nama kost dari database
                      Text(
                        widget.kost.nama,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary, // <-- DIUBAH
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Alamat kost dari database
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 18,
                          ), // <-- DIUBAH
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.kost.alamat,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ), // <-- DIUBAH
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Card harga
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight, // <-- DIUBAH
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Harga Sewa Bulanan",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ), // <-- DIUBAH
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.border, // <-- DIUBAH
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Termasuk Listrik",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ), // <-- DIUBAH
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Rp ${widget.kost.harga}", // Bisa diganti formatter nanti
                                  style: const TextStyle(
                                    color: AppColors.primary, // <-- DIUBAH
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    "/bulan",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ), // <-- DIUBAH
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Ketersediaan kamar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.successLight, // <-- DIUBAH
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 10,
                              color: AppColors.success,
                            ), // <-- DIUBAH
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Ketersediaan Kamar",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                ), // <-- DIUBAH
                              ),
                            ),
                            Text(
                              "Tersedia ${widget.kost.ketersediaanKamar} kamar",
                              style: const TextStyle(
                                color: AppColors.success, // <-- DIUBAH
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Fasilitas
                      const Text(
                        "Fasilitas Utama",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary, // <-- DIUBAH
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: facility(Icons.wifi, "WiFi")),
                          Expanded(child: facility(Icons.ac_unit, "AC")),
                          Expanded(
                            child: facility(Icons.bathroom, "K. Mandi\nDalam"),
                          ),
                          Expanded(child: facility(Icons.kitchen, "Dapur")),
                          Expanded(
                            child: facility(Icons.directions_car, "Parkir"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Deskripsi dari database
                      const Text(
                        "Deskripsi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary, // <-- DIUBAH
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.kost.deskripsi,
                        style: const TextStyle(
                          color: AppColors.textSecondary, // <-- DIUBAH
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Bottom action button
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    decoration: BoxDecoration(
                      color: AppColors.white, // <-- DIUBAH
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow, // <-- DIUBAH
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Tombol chat
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Membuka chat pemilik kost"),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text("Chat"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              side: const BorderSide(
                                color: AppColors.primary,
                              ), // <-- DIUBAH
                              foregroundColor: AppColors.primary, // <-- DIUBAH
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Tombol favorit
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await toggleFavorite();
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                            ),
                            label: Text(
                              isFavorite ? "Sudah Favorit" : "Tambah Favorit",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error, // <-- DIUBAH
                              foregroundColor: AppColors.white, // <-- DIUBAH
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tombol bulat di atas gambar
  Widget circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary, // <-- DIUBAH
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.white, // <-- DIUBAH
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // Badge kecil
  Widget badge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Item fasilitas
  Widget facility(IconData icon, String title) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.primaryLight, // <-- DIUBAH
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary, // <-- DIUBAH
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary, // <-- DIUBAH
          ),
        ),
      ],
    );
  }
}
