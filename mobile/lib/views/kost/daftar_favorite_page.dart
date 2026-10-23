import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../models/kost_model.dart';
import 'detail_kost_page.dart';
import 'hapus_favorite_dialog.dart';

class DaftarFavoritePage extends StatefulWidget {
  const DaftarFavoritePage({super.key});

  @override
  State<DaftarFavoritePage> createState() => _DaftarFavoritePageState();
}

class _DaftarFavoritePageState extends State<DaftarFavoritePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<KostModel> daftarKost = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavorite();
  }

  // Mengambil data kost favorit dari tabel 'favorite' di Supabase
  Future<void> loadFavorite() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final response = await supabase
          .from('favorite')
          .select('''
            id_favorite,
            kost(
              id_kost,
              nama,
              alamat,
              harga,
              deskripsi,
              ketersediaan_kamar,
              tipe,
              terverifikasi,
              termasuk_listrik,
              foto_kost(foto),
              fasilitas_kost(fasilitas)
            )
          ''')
          .eq('id_user', user.id);

      final data = response
          .where((item) => item['kost'] != null)
          .map<KostModel>((item) {
            return KostModel.fromJson(item['kost']);
          })
          .toList();

      if (mounted) {
        setState(() {
          daftarKost = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat favorit: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Halaman
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Kost Favorit",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${daftarKost.length} Tersimpan",
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List / Konten Favorit
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : daftarKost.isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada kost favorit yang disimpan.",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: daftarKost.length,
                      itemBuilder: (context, index) {
                        final kost = daftarKost[index];

                        // Format harga otomatis
                        final double hargaVal =
                            double.tryParse(kost.harga.toString()) ?? 0.0;
                        final hargaFormatted = hargaVal
                            .toInt()
                            .toString()
                            .replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]}.',
                            );

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailKostPage(kost: kost),
                              ),
                            ).then((value) {
                              loadFavorite();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // FOTO DI KIRI DENGAN BADGE RATING DI ATASNYA
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        kost.foto.isNotEmpty
                                            ? kost.foto[0]
                                            : "",
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 100,
                                                  height: 100,
                                                  color:
                                                      AppColors.backgroundGray,
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: AppColors.textHint,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 12,
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              "4.8",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // DETAIL INFORMASI DI SEBELAH KANAN FOTO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              kost.nama,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              showHapusFavoriteDialog(
                                                context,
                                                idKost: kost.idKost,
                                                onSuccess: () {
                                                  loadFavorite();
                                                },
                                              );
                                            },
                                            child: const Icon(
                                              Icons.favorite,
                                              color: AppColors.error,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Rp $hargaFormatted /bulan",
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              kost.alamat,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "WiFi • AC",
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "Tersedia ${kost.ketersediaanKamar ?? 0} kmr",
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
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
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
