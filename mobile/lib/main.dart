// YANG DI SINI JANG KORE
// LIAT ADA YANG JANGGAL KASE INFO DI GC NANTI SA YG PERBAIKI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//CORE SERVICE
import 'core/theme/app_theme.dart';
import 'services/supabase_config.dart';
import 'models/index.dart';

// AUTH - 3 file Salmin
import 'views/auth/splash_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';

// HOME - 3 file Hesti
import 'views/home/home_page.dart';
import 'views/home/pencarian_page.dart';
import 'views/home/hasil_pencarian.dart';

// KOST - 3 file Ilham
import 'views/kost/detail_kost_page.dart';
import 'views/kost/daftar_favorite_page.dart';
// hapus_favorite_dialog.dart itu dialog, jadi tr masuk routes

// CHAT USER - 3 file Salsa
import 'views/chatUser/daftar_chat_page.dart';
import 'views/chatUser/ruang_chat_page.dart';
import 'views/chatUser/profil_page.dart';

// ADMIN - 5 file Dina & Riana
import 'views/admin/home_admin_page.dart'; //dina
import 'views/admin/data_kost_page.dart'; //dina
import 'views/admin/tambah_edit_kost_page.dart'; //dina
import 'views/admin/daftar_chat_admin_page.dart'; //riana
import 'views/admin/profil_admin_page.dart'; //riana

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const KostRadarApp());
}

class KostRadarApp extends StatelessWidget {
  const KostRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider disiapkan di sini agar state management bisa diakses di seluruh halaman
    return MultiProvider(
      providers: [
        // Contoh penambahan Provider nanti ke depannya di sini:
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => KostProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/splash',
        routes: {
          '/splash': (c) => const SplashScreen(), // 1 Salmin
          '/login': (c) => const LoginScreen(), // 2 Salmin
          '/register': (c) => const RegisterScreen(), // 3 Salmin
          '/home': (c) => const HomePage(), // 4 Hesti
          '/pencarian': (c) => const PencarianPage(), // 5 Hesti - FIX
          '/hasil-pencarian': (c) => const HasilPencarian(), // 6 Hesti - FIX
          '/detail-kost': (c) => const DetailKostPage(), // 7 Ilham
          '/daftar-favorite': (c) =>
              const DaftarFavoritePage(), // 8 Ilham - FIX
          '/daftar-chat': (c) => const DaftarChatPage(), // 10 salsa - FIX
          '/ruang-chat': (c) => const RuangChatPage(), // 11 salsa - FIX
          '/profil': (c) => const ProfilPage(), // 12 salsa - FIX
          '/home-admin': (c) => const HomeAdminPage(), // 13 Dina - FIX
          '/data-kost': (c) => const DataKostPage(), // 14 Dina - FIX
          '/tambah-edit-kost': (c) =>
              const TambahEditKostPage(), // 15 Dina - FIX
          '/daftar-chat-admin': (c) =>
              const DaftarChatAdminPage(), // 16 Riana - FIX
          '/profil-admin': (c) => const ProfilAdminPage(), // 17 Riana - FIX
        },
      ),
    );
  }
}
