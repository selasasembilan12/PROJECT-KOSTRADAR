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
      }).toList();

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
                            final double hargaVal = double.tryParse(kost.harga.toString()) ?? 0.0;
                            final hargaFormatted = hargaVal.toInt().toString().replaceAllMapped(
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
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(8),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      kost.foto.isNotEmpty ? kost.foto[0] : "",
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        width: 70,
                                        height: 70,
                                        color: AppColors.backgroundGray,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    kost.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        "Rp $hargaFormatted /bulan",
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        kost.alamat,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: GestureDetector(
                                    onTap: () {
                                      // Memanggil dialog konfirmasi hapus sesuai mockup
                                      showHapusFavoriteDialog(
                                        context,
                                        idKost: kost.idKost,
                                        onSuccess: () {
                                          loadFavorite(); // Refresh data setelah terhapus dari database
                                        },
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.favorite,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
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