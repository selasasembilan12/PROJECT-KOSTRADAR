import 'dart:async';

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
  StreamSubscription? _authSubscription;
  bool _isHandlingRecovery = false; // 🛡️ FLAG PENGAMAN LUPA PASSWORD

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _checkInitialSession();
  }

  void _setupAuthListener() {
    // LAPISAN 1: LISTENER RESMI SUPABASE (JANGAN DIUBAH!)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      print('[DEBUG] Auth Event: ${data.event}');

      if (data.event == AuthChangeEvent.passwordRecovery) {
        print('[DEBUG] 🚨 PASSWORD RECOVERY DETECTED BY LISTENER!');
        _isHandlingRecovery = true;
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UpdatePasswordScreen(),
            ),
          );
        }
      }
    });
  }

  Future<void> _checkInitialSession() async {
    // 1. CEK URL TERLEBIH DAHULU SEBELUM DELAY (PENTING!)
    final uri = Uri.base;
    print('[DEBUG] Full URI: ${uri.toString()}');
    print('[DEBUG] Query: ${uri.query}');
    print('[DEBUG] Fragment: ${uri.fragment}');

    // Ambil parameter dari Query (?code=...) DAN Fragment (#access_token=...)
    final queryParams = uri.queryParameters;
    final fragmentParams = Uri.splitQueryString(uri.fragment);

    final code = queryParams['code'] ?? fragmentParams['code'];
    final type = queryParams['type'] ?? fragmentParams['type'];
    final accessToken =
        queryParams['access_token'] ?? fragmentParams['access_token'];

    // Fallback: cek manual string jika parsing URL gagal karena format #/splash
    final urlString = uri.toString();
    final hasRecoveryInString =
        urlString.contains('code=') ||
        urlString.contains('type=recovery') ||
        urlString.contains('access_token=');

    final hasRecoveryCode =
        code != null ||
        type == 'recovery' ||
        accessToken != null ||
        hasRecoveryInString;

    if (hasRecoveryCode) {
      print(
        '[DEBUG] 🚨 RECOVERY LINK DETECTED! Type: $type, Has Code: ${code != null}',
      );
      _isHandlingRecovery = true;

      try {
        // Coba recover session dengan format yang paling kompatibel untuk Web
        final recoveryUrl = uri.hasFragment && !uri.hasQuery
            ? '${uri.origin}#${uri.fragment}'
            : uri.toString();

        print('[DEBUG] Attempting recoverSession with: $recoveryUrl');
        await Supabase.instance.client.auth.recoverSession(recoveryUrl);
        print('[DEBUG] Recover session SUCCESS');
      } catch (e) {
        print(
          '[DEBUG] Recover session failed: $e. (Tetap lanjut ke halaman update password)',
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
        );
      }
      return; // STOP DI SINI, jangan lanjut ke normal flow
    }

    // 2. JIKA BUKAN LINK RECOVERY, BARU PAKAI DELAY UNTUK NORMAL FLOW
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // CEK PENGAMAN: Jika listener sudah menangani recovery, STOP!
    if (_isHandlingRecovery) {
      print('[DEBUG] Recovery sudah ditangani listener, skip.');
      return;
    }

    // FLOW NORMAL: BIARKAN TETAP DI SPLASH SCREEN
    // Kita HAPUS logika auto-login ke HomePage.
    // Biar user yang manual klik "Masuk" atau "Mulai Sekarang" setelah restart.
    print('[DEBUG] Normal restart. Tetap di SplashScreen.');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
