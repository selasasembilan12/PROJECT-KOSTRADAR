import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

import '../../models/kost_model.dart';
import 'detail_kost_page.dart';
import 'hapus_favorite_dialog.dart';

class DaftarFavoritePage extends StatefulWidget {
  const DaftarFavoritePage({super.key});

  @override
  State<DaftarFavoritePage> createState() => _DaftarFavoritePageState();
}

class _DaftarFavoritePageState extends State<DaftarFavoritePage> {
  // Menyimpan data kost dari database
  List<KostModel> daftarKost = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavorite();
  }

  // Mengambil data favorit dari Supabase
  Future<void> loadFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final response = await Supabase.instance.client
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
            foto_kost(foto),
            fasilitas_kost(fasilitas)
          )
        ''')
        .eq('id_user', user.id);

    final data = response.map<KostModel>((item) {
      final kost = item['kost'];

      return KostModel(
        idKost: kost['id_kost'].toString(),
        nama: kost['nama'] ?? "",
        alamat: kost['alamat'] ?? "",
        harga: kost['harga'] ?? 0,
        deskripsi: kost['deskripsi'] ?? "",
        ketersediaanKamar: kost['ketersediaan_kamar'] ?? 0,
        foto: (kost['foto_kost'] as List)
            .map<String>((e) => e['foto'].toString())
            .toList(),
        fasilitas: (kost['fasilitas_kost'] as List)
            .map<String>((e) => e['fasilitas'].toString())
            .toList(),
      );
    }).toList();

    setState(() {
      daftarKost = data;
      isLoading = false;
    });
  }

  // Menghapus favorit dari database
  Future<void> hapusFavorite(int index) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final kost = daftarKost[index];

    await Supabase.instance.client
        .from('favorite')
        .delete()
        .eq('id_user', user.id)
        .eq('id_kost', kost.idKost);

    setState(() {
      daftarKost.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // <-- DIUBAH
      body: SafeArea(
        child: Column(
          children: [
            // Header halaman
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.smallPadding,
                10,
                AppSpacing.smallPadding,
                AppSpacing.smallSpacing,
              ), // <-- DIUBAH
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_back_ios,
                    size: 18,
                    color: AppColors.textPrimary,
                  ), // <-- DIUBAH
                  const SizedBox(width: 6),
                  const Text(
                    "Kost Favorit",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary, // <-- DIUBAH
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight, // <-- DIUBAH (pengganti Colors.red.shade50)
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${daftarKost.length} Tersimpan",
                      style: const TextStyle(
                        color: AppColors.error, // <-- DIUBAH
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ) // <-- DIUBAH
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.smallPadding,
                      ), // <-- DIUBAH
                      itemCount: daftarKost.length,
                      itemBuilder: (context, index) {
                        final kost = daftarKost[index];

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
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.smallSpacing,
                            ), // <-- DIUBAH
                            color: AppColors.white, // <-- DIUBAH
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  kost.foto.isNotEmpty ? kost.foto[0] : "",
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.broken_image,
                                        size: 70,
                                        color: AppColors.textHint,
                                      ),
                                ),
                              ),
                              title: Text(
                                kost.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary, // <-- DIUBAH
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Rp ${kost.harga}/bulan",
                                    style: const TextStyle(
                                      color: AppColors.primary, // <-- DIUBAH
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    kost.alamat,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ), // <-- DIUBAH
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    kost.fasilitas.join(" • "),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color:
                                          AppColors.textSecondary, // <-- DIUBAH
                                    ),
                                  ),
                                ],
                              ),
                              trailing: GestureDetector(
                                onTap: () {
                                  showHapusFavoriteDialog(context, () {
                                    hapusFavorite(index);
                                  });
                                },
                                child: const Icon(
                                  Icons.favorite,
                                  color: AppColors.error, // <-- DIUBAH
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
