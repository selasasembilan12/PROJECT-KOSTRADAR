import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';
import 'login_screen.dart';
import 'update_password_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkRecoverySession();
  }

  Future<void> _checkRecoverySession() async {
    // Tunggu sebentar agar splash screen terlihat
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // CEK URL HASH untuk recovery token (Flutter Web menyimpan token di hash URL)
    final uri = Uri.base;
    final hashParams = Uri.splitQueryString(uri.fragment);
    final type = hashParams['type'];
    final accessToken = hashParams['access_token'];

    // Jika ada recovery token di URL
    if (type == 'recovery' && accessToken != null) {
      print('[DEBUG] Recovery token terdeteksi di URL');
      try {
        // Recover session dari token di URL
        await Supabase.instance.client.auth.recoverSession(
          '${uri.origin}#${uri.fragment}',
        );
        print('[DEBUG] Session recovery berhasil');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UpdatePasswordScreen(),
            ),
          );
        }
        return;
      } catch (e) {
        print('[DEBUG] Recovery gagal: $e');
      }
    }

    // Fallback: Cek session normal (jika user sudah login)
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.defaultPadding,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.home_filled,
                  color: AppColors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.mediumSpacing),
              const Text(
                AppTexts.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.smallSpacing),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      AppTexts.badgeText,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.largeSpacing),
              const Text(
                AppTexts.appSlogan,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.mediumSpacing),
              const Text(
                AppTexts.appDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.largeSpacing),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Mulai Sekarang",
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.mediumSpacing),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text.rich(
                  TextSpan(
                    text: "Sudah punya akun? ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "Masuk",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.mediumSpacing),
            ],
          ),
        ),
      ),
    );
  }
}
