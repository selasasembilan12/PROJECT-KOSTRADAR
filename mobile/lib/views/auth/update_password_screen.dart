// ============================================================
// IMPORT LIBRARY
// ============================================================
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

// ============================================================
// DEFINISI CLASS HALAMAN UPDATE PASSWORD
// ============================================================
class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  // ============================================================
  // VARIABEL & STATE
  // ============================================================
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isRecovering = true;

  @override
  void initState() {
    super.initState();
    _recoverSession();
  }

  // ============================================================
  // FUNGSI RECOVER SESSION (SOLUSI FINAL PAKAI dart:js)
  // ============================================================
  Future<void> _recoverSession() async {
    try {
      print('[DEBUG] === START RECOVER SESSION ===');

      // Baca URL LANGSUNG dari JavaScript browser (bypass Flutter)
      final jsLocation = js.context['location'];
      final href = jsLocation['href'] as String;
      final search = jsLocation['search'] as String;
      final hash = jsLocation['hash'] as String;

      print('[DEBUG] JS Href: $href');
      print('[DEBUG] JS Search: $search');
      print('[DEBUG] JS Hash: $hash');

      // Ekstrak code dari URL pakai regex
      final codeMatch = RegExp(r'[?&]code=([a-f0-9\-]+)').firstMatch(href);
      final code = codeMatch?.group(1);
      print('[DEBUG] Extracted code: $code');

      if (code != null) {
        // Tunggu sebentar
        await Future.delayed(const Duration(milliseconds: 500));

        // Rekonstruksi URL
        final host = jsLocation['host'] as String;
        final baseUrl = 'http://$host';
        final fullUrl = '$baseUrl?code=$code';
        print('[DEBUG] Reconstructed URL: $fullUrl');

        // Coba getSessionFromUrl
        try {
          await Supabase.instance.client.auth.getSessionFromUrl(
            Uri.parse(fullUrl),
          );
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            print('[DEBUG] ✅ Session recovered! User: ${session.user.id}');
            return;
          }
        } catch (e) {
          print('[DEBUG] getSessionFromUrl failed: $e');
        }

        // Fallback: recoverSession
        try {
          await Supabase.instance.client.auth.recoverSession(fullUrl);
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            print(
              '[DEBUG] ✅ Session recovered via fallback! User: ${session.user.id}',
            );
            return;
          }
        } catch (e) {
          print('[DEBUG] recoverSession failed: $e');
        }
      } else {
        print('[DEBUG] ⚠️ No code found in URL');
      }

      print('[DEBUG] ⚠️ All methods failed');
    } catch (e) {
      print('[DEBUG] ❌ Critical error: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // FUNGSI UTAMA: UPDATE PASSWORD
  // ============================================================
  Future<void> _handleUpdatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // --- LANGKAH 1: VALIDASI INPUT ---
    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password wajib diisi!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi password tidak sama!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 6 karakter!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // --- LANGKAH 1.5: CEK SESI SEBELUM UPDATE (PENTING!) ---
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesi tidak valid atau link kadaluarsa. Silakan minta link reset baru.',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Nyalakan loading
    setState(() => _isLoading = true);

    // --- LANGKAH 2: PROSES UPDATE KE DATABASE ---
    try {
      print('[DEBUG] Updating password for user: ${session.user.id}');

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      print('[DEBUG] Password update SUCCESS!');

      // --- LANGKAH 3: LOGOUT SESSION RECOVERY ---
      await Supabase.instance.client.auth.signOut();

      // --- LANGKAH 4: FEEDBACK & NAVIGASI ---
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password berhasil diubah! Silakan login dengan password baru.',
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        // Kembali ke halaman Login dan hapus semua halaman sebelumnya dari stack
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
    // --- LANGKAH 5: ERROR HANDLING ---
    catch (e) {
      print('[DEBUG] Password update error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah password: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ============================================================
  // MEMBANGUN TAMPILAN UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    // Tampilkan loading saat recover session
    if (_isRecovering) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Memverifikasi link reset...',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilan form update password (100% sama seperti kode lu)
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.defaultPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Tombol Kembali
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 48),

              // Judul Halaman
              const Text(
                "Buat Password Baru",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Masukkan password baru Anda. Pastikan password kuat dan mudah diingat.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Input Password Baru
              const Text(
                "Password Baru",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Masukkan password baru",
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Input Konfirmasi Password
              const Text(
                "Konfirmasi Password",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: "Ulangi password baru",
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    child: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Update Password
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update Password",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Link Batal
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
