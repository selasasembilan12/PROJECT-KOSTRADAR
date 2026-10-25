
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../models/kost_model.dart';
import 'hapus_favorite_dialog.dart';
// IMPORT HALAMAN RUANG CHAT PRIBADI
import '../chatUser/ruang_chat_page.dart';

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

  // Indeks foto yang sedang ditampilkan pada galeri detail kost.
  int _currentPhotoIndex = 0;

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

      if (mounted) {
        setState(() {
          isFavorite = data != null;
        });
      }
    } catch (e) {
      debugPrint('Error cek favorite: $e');
    }
  }

  // Tambah / hapus favorit database dengan dialog konfirmasi
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

    if (isFavorite) {
      // Tampilkan dialog konfirmasi hapus pop-up sesuai desain
      showHapusFavoriteDialog(
        context,
        idKost: widget.kost.idKost,
        onSuccess: () {
          setState(() {
            isFavorite = false;
          });
        },
      );
    } else {
      // Langsung tambahkan ke database Supabase jika belum favorit
      try {
        await Supabase.instance.client.from('favorite').insert({
          'id_user': user.id,
          'id_kost': widget.kost.idKost,
        });

        if (!mounted) return;

        setState(() {
          isFavorite = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil ditambahkan ke favorit! ❤️'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan favorit: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  void goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // Membuka chat dengan pemilik kost yang sebenarnya.
  Future<void> _bukaRuangChat() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan login terlebih dahulu untuk chat.',
          ),
        ),
      );
      return;
    }

    try {
      // Ambil ID pemilik dari data kost yang dipilih.
      final kostData = await supabase
          .from('kost')
          .select('id_user')
          .eq('id_kost', widget.kost.idKost)
          .maybeSingle();

      if (!mounted) return;

      if (kostData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data kost tidak ditemukan.'),
          ),
        );
        return;
      }

      final idPemilik = kostData['id_user']?.toString();

      if (idPemilik == null || idPemilik.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ID pemilik kost tidak ditemukan.',
            ),
          ),
        );
        return;
      }

      // Jangan membuat percakapan dengan akun sendiri.
      if (idPemilik == currentUser.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kamu sedang melihat kost milik akunmu sendiri.',
            ),
          ),
        );
        return;
      }

      final String fotoUrl = widget.kost.foto.isNotEmpty
          ? widget.kost.foto[0]
          : '';

      final double hargaVal =
          double.tryParse(widget.kost.harga.toString()) ?? 0.0;

      final formattedHarga =
          "Rp ${hargaVal.toInt().toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              )}/bulan";

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RuangChatPage(
            // Perbaikan utama: gunakan ID pemilik kost.
            idAdminTujuan: idPemilik,
            namaAdmin: 'Pengelola Kost',
            kostInfo: {
              'id_kost': widget.kost.idKost,
              'nama_kost': widget.kost.nama,
              'foto_kost': fotoUrl,
              'harga': formattedHarga,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('Gagal membuka ruang chat: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka chat: $e'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format harga secara manual agar aman tanpa error Formatter
    final double hargaVal =
        double.tryParse(widget.kost.harga.toString()) ?? 0.0;

    final formattedHarga =
        "Rp ${hargaVal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    // Data aman dengan fallback dari model
    final String tipeKost =
        widget.kost.tipe.isNotEmpty ? widget.kost.tipe : "Campur";

    final bool isVerifikasi = widget.kost.terverifikasi;
    final bool termasukListrik = widget.kost.termasukListrik;

    // Gabungkan fasilitas menjadi satu string agar mudah dicek
    final String fasilitasStr =
        widget.kost.fasilitas.map((e) => e.toLowerCase()).join(', ');

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
                    // Galeri foto kost: geser ke kiri/kanan jika ada beberapa foto.
                    SizedBox(
                      height: 330,
                      width: double.infinity,
                      child: widget.kost.foto.isEmpty
                          ? Container(
                              color: AppColors.backgroundGray,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: AppColors.textHint,
                                ),
                              ),
                            )
                          : PageView.builder(
                              itemCount: widget.kost.foto.length,
                              onPageChanged: (index) {
                                if (!mounted) return;
                                setState(() {
                                  _currentPhotoIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final fotoUrl =
                                    widget.kost.foto[index].trim();

                                if (fotoUrl.isEmpty) {
                                  return Container(
                                    color: AppColors.backgroundGray,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  );
                                }

                                return Image.network(
                                  fotoUrl,
                                  width: double.infinity,
                                  height: 330,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }

                                    return Container(
                                      color: AppColors.backgroundGray,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.backgroundGray,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 50,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
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
                            : AppColors.textPrimary,
                        onTap: toggleFavorite,
                      ),
                    ),

                    // Indikator titik untuk menunjukkan posisi foto.
                    if (widget.kost.foto.length > 1)
                      Positioned(
                        bottom: 26,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.kost.foto.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentPhotoIndex == index ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentPhotoIndex == index
                                    ? AppColors.white
                                    : AppColors.white.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
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
                              widget.kost.foto.isEmpty
                                  ? '0 Foto'
                                  : '${_currentPhotoIndex + 1} / ${widget.kost.foto.length} Foto',
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

                      // Nama kost
                      Text(
                        widget.kost.nama,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Alamat kost
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                ),
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

                      // Fasilitas utama
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
                          Expanded(
                            child: facility(
                              Icons.wifi,
                              "WiFi",
                              fasilitasStr.contains('wifi'),
                            ),
                          ),
                          Expanded(
                            child: facility(
                              Icons.ac_unit,
                              "AC",
                              fasilitasStr.contains('ac'),
                            ),
                          ),
                          Expanded(
                            child: facility(
                              Icons.bathroom,
                              "K. Mandi\nDalam",
                              fasilitasStr.contains('mandi') ||
                                  fasilitasStr.contains('bathroom'),
                            ),
                          ),
                          Expanded(
                            child: facility(
                              Icons.kitchen,
                              "Dapur",
                              fasilitasStr.contains('dapur'),
                            ),
                          ),
                          Expanded(
                            child: facility(
                              Icons.directions_car,
                              "Parkir",
                              fasilitasStr.contains('parkir'),
                            ),
                          ),
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
              decoration: const BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _bukaRuangChat,
                      icon: const Icon(
                        Icons.chat_outlined,
                        size: 18,
                      ),
                      label: const Text("Chat"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        side: const BorderSide(
                          color: AppColors.primary,
                        ),
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
                        isFavorite
                            ? "Sudah Favorit"
                            : "Tambah Favorit",
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
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  Widget badge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
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

  Widget facility(
    IconData icon,
    String title,
    bool isAvailable,
  ) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.4,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.primaryLight
                  : AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isAvailable
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
