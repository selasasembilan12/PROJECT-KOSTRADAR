import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
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

    try {
      final data = await Supabase.instance.client
          .from('favorite')
          .select()
          .eq('id_user', user.id)
          .eq('id_kost', widget.kost.idKost)
          .maybeSingle();

      setState(() {
        isFavorite = data != null;
      });
    } catch (e) {
      print('Error cek favorite: $e');
    }
  }

  // Tambah / hapus favorit database
  Future<void> toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan login terlebih dahulu untuk menyimpan favorit.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      if (isFavorite) {
        await Supabase.instance.client
            .from('favorite')
            .delete()
            .eq('id_user', user.id)
            .eq('id_kost', widget.kost.idKost);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dihapus dari favorit'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      } else {
        await Supabase.instance.client.from('favorite').insert({
          'id_user': user.id,
          'id_kost': widget.kost.idKost,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil ditambahkan ke favorit! ❤️'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      setState(() {
        isFavorite = !isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mode simulasi: Favorit diupdate (DB: $e)'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format harga secara manual agar aman tanpa error Formatter
    final double hargaVal = double.tryParse(widget.kost.harga.toString()) ?? 0.0;
    final formattedHarga = "Rp ${hargaVal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    // Data aman dengan fallback dari model
    final String tipeKost = widget.kost.tipe.isNotEmpty ? widget.kost.tipe : "Campur";
    final bool isVerifikasi = widget.kost.terverifikasi;
    final bool termasukListrik = widget.kost.termasukListrik;
    
    // Gabungkan List<String> fasilitas menjadi satu string huruf kecil agar mudah dicek
    final String fasilitasStr = widget.kost.fasilitas.map((e) => e.toLowerCase()).join(', ');
    
    final String deskripsiKost = widget.kost.deskripsi.isNotEmpty
        ? widget.kost.deskripsi
        : "Kost nyaman, aman, dan strategis dekat kampus.";

    return Scaffold(
      backgroundColor: AppColors.background,
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
                          color: AppColors.backgroundGray,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: AppColors.textHint,
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
                        color: AppColors.textPrimary,
                      ),
                    ),

                    // Tombol share
                    Positioned(
                      top: 40,
                      right: 70,
                      child: circleButton(
                        icon: Icons.share_outlined,
                        color: AppColors.textPrimary,
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

                    // Tombol favorit (di atas gambar)
                    Positioned(
                      top: 40,
                      right: 20,
                      child: circleButton(
                        icon: isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFavorite
                            ? AppColors.error
                            : AppColors.textPrimary,
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
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              size: 14,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${widget.kost.foto.length} Foto",
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                              ),
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
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
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
                            tipeKost,
                            AppColors.chipBackground,
                            AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          if (isVerifikasi)
                            badge(
                              "✓ Terverifikasi",
                              AppColors.successLight,
                              AppColors.success,
                            ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Nama kost dari database
                      Text(
                        widget.kost.nama,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.kost.alamat,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
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
                          color: AppColors.backgroundLight,
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
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    termasukListrik
                                        ? "Termasuk Listrik"
                                        : "Tidak Termasuk Listrik",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formattedHarga,
                                  style: const TextStyle(
                                    color: AppColors.primary,
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
                                    ),
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
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 10,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Ketersediaan Kamar",
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                            Text(
                              "Tersedia ${widget.kost.ketersediaanKamar} kamar",
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Fasilitas Utama
                      const Text(
                        "Fasilitas Utama",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: facility(Icons.wifi, "WiFi", fasilitasStr.contains('wifi'))),
                          Expanded(child: facility(Icons.ac_unit, "AC", fasilitasStr.contains('ac'))),
                          Expanded(child: facility(Icons.bathroom, "K. Mandi\nDalam", fasilitasStr.contains('mandi') || fasilitasStr.contains('bathroom'))),
                          Expanded(child: facility(Icons.kitchen, "Dapur", fasilitasStr.contains('dapur'))),
                          Expanded(child: facility(Icons.directions_car, "Parkir", fasilitasStr.contains('parkir'))),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Deskripsi
                      const Text(
                        "Deskripsi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        deskripsiKost,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
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
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(color: AppColors.cardShadow, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/ruang-chat');
                            },
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text("Chat"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: toggleFavorite,
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
                              backgroundColor: isFavorite
                                  ? AppColors.textSecondary
                                  : AppColors.error,
                              foregroundColor: AppColors.white,
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

  Widget circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

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

  Widget facility(IconData icon, String title, bool isAvailable) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.4,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.primaryLight : AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isAvailable ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}