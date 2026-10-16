import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';

/// Fungsi untuk menampilkan dialog konfirmasi hapus favorit sesuai UI mockup
/// [idKost] dan [onSuccess] disertakan agar langsung menghapus data di Supabase secara aman.
void showHapusFavoriteDialog(
  BuildContext context, {
  required String idKost,
  required VoidCallback onSuccess,
}) {
  final SupabaseClient supabase = Supabase.instance.client;

  showDialog(
    context: context,
    barrierDismissible: false, // User wajib memilih salah satu aksi (Batal / Hapus)
    builder: (dialogContext) {
      bool isDeleting = false;

      return StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon tempat sampah di dalam bulatan merah lembut
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Judul Dialog
                  const Text(
                    "Hapus dari Favorit?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Deskripsi Konfirmasi
                  const Text(
                    "Kost ini akan dihapus dari daftar favorit Anda.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Aksi Batal dan Hapus
                  Row(
                    children: [
                      // Tombol Batal
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 45),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isDeleting
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol Hapus (Terintegrasi ke Supabase)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(0, 45),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isDeleting
                              ? null
                              : () async {
                                  final user = supabase.auth.currentUser;
                                  if (user == null) return;

                                  setStateModal(() {
                                    isDeleting = true;
                                  });

                                  try {
                                    // Hapus data dari tabel 'favorite' di Supabase
                                    await supabase
                                        .from('favorite')
                                        .delete()
                                        .eq('id_user', user.id)
                                        .eq('id_kost', idKost);

                                    if (!context.mounted) return;
                                    Navigator.pop(dialogContext); // Tutup dialog

                                    // Jalankan callback untuk memperbarui UI halaman sebelumnya
                                    onSuccess();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Berhasil dihapus dari favorit",
                                        ),
                                        backgroundColor:
                                            AppColors.textSecondary,
                                      ),
                                    );
                                  } catch (e) {
                                    setStateModal(() {
                                      isDeleting = false;
                                    });
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Gagal menghapus: $e"),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                },
                          child: isDeleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Hapus",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
    },
  );
}