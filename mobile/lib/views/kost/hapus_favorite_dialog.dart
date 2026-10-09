import 'package:flutter/material.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';

// Fungsi untuk menampilkan dialog konfirmasi hapus favorit
// onHapus akan dijalankan ketika tombol "Hapus" ditekan
void showHapusFavoriteDialog(BuildContext context, VoidCallback onHapus) {
  showDialog(
    context: context,
    barrierDismissible: false, // User wajib memilih tombol aksi
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,

        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),

          // Tampilan kotak dialog
          decoration: BoxDecoration(
            color: AppColors.white, // <-- DIUBAH
            borderRadius: BorderRadius.circular(18),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // Icon tempat sampah merah
              Container(
                padding: const EdgeInsets.all(10),

                decoration: const BoxDecoration(
                  color:
                      AppColors.errorLight, // <-- DIUBAH (pengganti 0xffffeeee)
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error, // <-- DIUBAH
                  size: 30,
                ),
              ),

              const SizedBox(height: 15),

              // Judul dialog
              const Text(
                "Hapus dari Favorit?",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary, // <-- DIUBAH
                ),
              ),

              const SizedBox(height: 8),

              // Deskripsi konfirmasi
              const Text(
                "Kost ini akan dihapus dari daftar favorit Anda.",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary, // <-- DIUBAH
                ),
              ),

              const SizedBox(height: 20),

              // Tombol aksi Batal dan Hapus
              Row(
                children: [
                  // Tombol membatalkan proses hapus
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        side: const BorderSide(
                          color: AppColors.border,
                        ), // <-- DIUBAH
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      onPressed: () {
                        Navigator.pop(context);
                      },

                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          color: AppColors.textPrimary, // <-- DIUBAH
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Tombol konfirmasi hapus
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error, // <-- DIUBAH
                        minimumSize: const Size(0, 40),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      onPressed: () {
                        // Tutup dialog
                        Navigator.pop(context);

                        // Jalankan fungsi hapus dari halaman utama
                        onHapus();
                      },

                      child: const Text(
                        "Hapus",

                        style: TextStyle(
                          color: AppColors.white, // <-- DIUBAH
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
