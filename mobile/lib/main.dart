
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// CORE SERVICE
import 'core/theme/app_theme.dart';
import 'services/supabase_config.dart';
import 'models/index.dart';

// PROVIDERS
import 'providers/chat_provider.dart';

// AUTH
import 'views/auth/splash_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';

// HOME
import 'views/home/home_page.dart';
import 'views/home/pencarian_page.dart';
import 'views/home/hasil_pencarian.dart';

// KOST
import 'views/kost/detail_kost_page.dart';
import 'views/kost/daftar_favorite_page.dart';

// CHAT USER
import 'views/chatUser/daftar_chat_page.dart';
import 'views/chatUser/profil_page.dart';
import 'views/chatUser/voice_call_page.dart';

// ADMIN
import 'views/admin/home_admin_page.dart';
import 'views/admin/data_kost_page.dart';
import 'views/admin/tambah_edit_kost_page.dart';
import 'views/admin/daftar_chat_admin_page.dart';
import 'views/admin/profil_admin_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSupabase();

  runApp(const KostRadarApp());
}

class KostRadarApp extends StatefulWidget {
  const KostRadarApp({super.key});

  @override
  State<KostRadarApp> createState() => _KostRadarAppState();
}

class _KostRadarAppState extends State<KostRadarApp> {
  // Navigator global untuk menampilkan panggilan
  // dari halaman mana pun.
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Listener Supabase
  StreamSubscription<List<Map<String, dynamic>>>?
      callsSubscription;

  StreamSubscription<AuthState>? authSubscription;

  // ID akun yang sedang dipantau
  String? listeningUserId;

  // Mencegah dialog panggilan yang sama muncul berulang
  final Set<String> seenCalls = {};

  // Mencegah beberapa dialog tampil bersamaan
  bool isIncomingDialogOpen = false;

  @override
  void initState() {
    super.initState();

    // Mulai memantau panggilan masuk
    _listenIncomingCalls();

    // Memperbarui listener ketika akun login/logout
    authSubscription = Supabase.instance.client.auth
        .onAuthStateChange
        .listen((authState) {
      _listenIncomingCalls();
    });
  }

  // =====================================================
  // LISTENER PANGGILAN MASUK
  // =====================================================

  void _listenIncomingCalls() {
    final supabase = Supabase.instance.client;

    final currentUserId = supabase.auth.currentUser?.id;

    // Jangan membuat listener ganda
    if (currentUserId == listeningUserId) {
      return;
    }

    // Hentikan listener akun sebelumnya
    callsSubscription?.cancel();
    callsSubscription = null;

    listeningUserId = currentUserId;

    seenCalls.clear();

    if (currentUserId == null) {
      return;
    }

    // Pantau tabel voice_calls untuk akun penerima
    callsSubscription = supabase
        .from('voice_calls')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', currentUserId)
        .listen(
      (rows) {
        for (final call in rows) {
          if (call['status'] != 'ringing') {
            continue;
          }

          final callId = call['id'] as String;

          // Jangan memproses panggilan yang sama
          if (!seenCalls.add(callId)) {
            continue;
          }

          final createdAt = DateTime.tryParse(
            call['created_at']?.toString() ?? '',
          );

          if (createdAt == null) {
            continue;
          }

          // Abaikan panggilan lama
          final callAge = DateTime.now()
              .toUtc()
              .difference(createdAt.toUtc());

          if (callAge.isNegative ||
              callAge > const Duration(seconds: 45)) {
            continue;
          }

          // Tampilkan dialog panggilan masuk
          _showIncomingCall(call);
        }
      },
      onError: (error) {
        debugPrint(
          'Gagal mendeteksi panggilan: $error',
        );
      },
    );
  }

  // =====================================================
  // DIALOG PANGGILAN MASUK
  // =====================================================

  Future<void> _showIncomingCall(
    Map<String, dynamic> call,
  ) async {
    if (isIncomingDialogOpen || !mounted) {
      return;
    }

    final callId = call['id'] as String;
    final callerId = call['caller_id'] as String;

    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null) {
      return;
    }

    // Jangan menerima panggilan sendiri
    if (callerId == currentUserId) {
      return;
    }

    final context = navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    isIncomingDialogOpen = true;

    try {
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.call,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Panggilan Masuk',
                  ),
                ),
              ],
            ),

            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 35,
                  child: Icon(
                    Icons.person,
                    size: 40,
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'Pengguna KOSTRADAR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Menghubungi Anda melalui '
                  'panggilan suara',
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            actionsAlignment:
                MainAxisAlignment.spaceEvenly,

            actions: [
              // TOMBOL TOLAK
              TextButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop(false);
                },
                icon: const Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
                label: const Text(
                  'Tolak',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),

              // TOMBOL TERIMA
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop(true);
                },
                icon: const Icon(Icons.call),
                label: const Text('Terima'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      // Pastikan panggilan masih aktif
      final latestCall = await Supabase.instance.client
          .from('voice_calls')
          .select('status')
          .eq('id', callId)
          .maybeSingle();

      if (latestCall == null ||
          latestCall['status'] != 'ringing') {
        return;
      }

      if (accepted == true) {
        // Buka halaman panggilan suara
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => VoiceCallPage(
              peerId: callerId,
              peerName: 'Pengguna KOSTRADAR',
              incomingCallId: callId,
            ),
          ),
        );
      } else {
        // Ubah status menjadi ditolak
        await Supabase.instance.client
            .from('voice_calls')
            .update({
              'status': 'declined',
              'ended_at':
                  DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', callId)
            .eq('status', 'ringing');
      }
    } catch (error) {
      debugPrint(
        'Error saat menangani panggilan: $error',
      );
    } finally {
      isIncomingDialogOpen = false;
    }
  }

  // =====================================================
  // MEMBERSIHKAN LISTENER
  // =====================================================

  @override
  void dispose() {
    callsSubscription?.cancel();
    authSubscription?.cancel();

    super.dispose();
  }

  // =====================================================
  // APLIKASI UTAMA KOSTRADAR
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
      ],

      child: MaterialApp(
        navigatorKey: navigatorKey,

        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,

        initialRoute: '/splash',

        routes: {
          // AUTH
          '/splash': (c) => const SplashScreen(),

          '/login': (c) => const LoginScreen(),

          '/register': (c) => const RegisterScreen(),

          // HOME
          '/home': (c) => const HomePage(),

          '/pencarian': (c) => const PencarianPage(),

          '/hasil-pencarian': (c) =>
              const HasilPencarianPage(),

          // KOST
          '/detail-kost': (c) => DetailKostPage(
                kost: KostModel(
                  idKost: 'dummy',
                  nama: 'Dummy Kost',
                  alamat: 'Alamat',
                  harga: 0,
                  deskripsi: 'Deskripsi',
                  ketersediaanKamar: 1,
                  foto: [],
                  fasilitas: [],
                ),
              ),

          '/daftar-favorite': (c) =>
              const DaftarFavoritePage(),

          // CHAT USER
          '/daftar-chat': (c) =>
              const DaftarChatPage(),

          '/profil': (c) =>
              const ProfilPage(),

          // ADMIN
          '/home-admin': (c) =>
              const HomeAdminPage(),

          '/data-kost': (c) =>
              const DataKostPage(),

          '/tambah-edit-kost': (c) =>
              const TambahEditKostPage(),

          '/daftar-chat-admin': (c) =>
              const DaftarChatAdminPage(
                chatData: {},
              ),

          '/profil-admin': (c) =>
              const ProfilAdminPage(),
        },
      ),
    );
  }
}
