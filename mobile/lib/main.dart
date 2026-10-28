
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
  // Navigator global agar dialog dapat dibuka dari halaman mana pun.
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Listener panggilan dan autentikasi.
  StreamSubscription<List<Map<String, dynamic>>>?
      callsSubscription;

  StreamSubscription<AuthState>? authSubscription;

  // Akun yang sedang dipantau.
  String? listeningUserId;

  // ID panggilan yang sudah diterima listener.
  final Set<String> seenCalls = <String>{};

  // Antrean panggilan masuk.
  final List<Map<String, dynamic>> pendingIncomingCalls =
      <Map<String, dynamic>>[];

  bool isProcessingIncomingCalls = false;
  bool isIncomingDialogOpen = false;

  @override
  void initState() {
    super.initState();

    _listenIncomingCalls();

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

    // Listener akun yang sama tidak perlu dibuat ulang.
    if (currentUserId == listeningUserId) {
      return;
    }

    callsSubscription?.cancel();
    callsSubscription = null;

    listeningUserId = currentUserId;

    seenCalls.clear();
    pendingIncomingCalls.clear();

    if (currentUserId == null) {
      debugPrint('CALL: tidak ada akun yang login.');
      return;
    }

    debugPrint(
      'CALL: listener aktif untuk $currentUserId',
    );

    callsSubscription = supabase
        .from('voice_calls')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', currentUserId)
        .listen(
      (rows) {
        // Pastikan akun belum berubah sejak listener dibuat.
        final activeUserId =
            Supabase.instance.client.auth.currentUser?.id;

        if (activeUserId != currentUserId) {
          return;
        }

        debugPrint(
          'CALL DEBUG: snapshot diterima; jumlah baris=${rows.length}',
        );

        for (final call in rows) {
          debugPrint(
            'CALL DEBUG ROW: id=${call['id']}, '
            'caller=${call['caller_id']}, '
            'receiver=${call['receiver_id']}, '
            'status=${call['status']}, '
            'created_at=${call['created_at']}',
          );
          if (call['status']?.toString() != 'ringing') {
            continue;
          }

          final callId = call['id']?.toString();
          final callerId = call['caller_id']?.toString();
          final receiverId = call['receiver_id']?.toString();

          if (callId == null ||
              callerId == null ||
              receiverId != currentUserId ||
              callerId == currentUserId) {
            continue;
          }

          // Periksa timestamp panggilan.
          final createdAt = DateTime.tryParse(
            call['created_at']?.toString() ?? '',
          );

          if (createdAt == null) {
            debugPrint(
              'CALL: created_at tidak valid untuk $callId',
            );
            continue;
          }

          final age = DateTime.now().toUtc().difference(
                createdAt.toUtc(),
              );

          // Panggilan lama tidak ditampilkan.
          if (age.isNegative ||
              age > const Duration(seconds: 45)) {
            debugPrint('CALL: panggilan kedaluwarsa $callId');
            seenCalls.add(callId);
            continue;
          }

          // Jangan memasukkan ID yang sama berkali-kali.
          if (seenCalls.contains(callId)) {
            continue;
          }

          // Tandai setelah panggilan masuk ke antrean,
          // bukan sebelum dialog siap ditampilkan.
          pendingIncomingCalls.add(
            Map<String, dynamic>.from(call),
          );
          seenCalls.add(callId);

          debugPrint('CALL: panggilan masuk $callId');
        }

        _processIncomingCallQueue();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('CALL LISTENER ERROR: $error');
        debugPrint('$stackTrace');
      },
    );
  }

  // =====================================================
  // ANTREAN PANGGILAN MASUK
  // =====================================================

  Future<void> _processIncomingCallQueue() async {
    if (!mounted ||
        isProcessingIncomingCalls ||
        isIncomingDialogOpen ||
        pendingIncomingCalls.isEmpty) {
      return;
    }

    if (navigatorKey.currentContext == null) {
      debugPrint(
        'CALL: Navigator belum siap; panggilan tetap di antrean.',
      );

      // Coba lagi setelah frame berikutnya.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _processIncomingCallQueue();
        }
      });

      return;
    }

    isProcessingIncomingCalls = true;

    try {
      while (mounted &&
          pendingIncomingCalls.isNotEmpty) {
        if (isIncomingDialogOpen) {
          break;
        }

        if (navigatorKey.currentContext == null) {
          break;
        }

        final call = pendingIncomingCalls.first;

        final handled = await _showIncomingCall(call);

        if (!handled) {
          // Jangan membuang panggilan jika belum berhasil
          // ditampilkan atau ditangani.
          break;
        }

        // Hapus hanya setelah panggilan selesai ditangani.
        if (pendingIncomingCalls.isNotEmpty &&
            pendingIncomingCalls.first['id']?.toString() ==
                call['id']?.toString()) {
          pendingIncomingCalls.removeAt(0);
        } else {
          pendingIncomingCalls.removeWhere(
            (item) =>
                item['id']?.toString() ==
                call['id']?.toString(),
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint('CALL QUEUE ERROR: $error');
      debugPrint('$stackTrace');
    } finally {
      isProcessingIncomingCalls = false;
    }
  }

  // =====================================================
  // DIALOG PANGGILAN MASUK
  // =====================================================

  Future<bool> _showIncomingCall(
    Map<String, dynamic> call,
  ) async {
    if (!mounted || isIncomingDialogOpen) {
      return false;
    }

    final callId = call['id']?.toString();
    final callerId = call['caller_id']?.toString();

    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    debugPrint(
      'CALL DEBUG: mulai tampilkan dialog; id=$callId, '
      'caller=$callerId, currentUser=$currentUserId',
    );

    if (callId == null ||
        callerId == null ||
        currentUserId == null) {
      debugPrint('CALL: data panggilan tidak lengkap.');
      return false;
    }

    if (callerId == currentUserId) {
      return true;
    }

    final context = navigatorKey.currentContext;

    if (context == null) {
      return false;
    }

    isIncomingDialogOpen = true;

    try {
      // Periksa status terbaru sebelum menampilkan dialog.
      final latestCall = await Supabase.instance.client
          .from('voice_calls')
          .select('id, caller_id, receiver_id, status, created_at')
          .eq('id', callId)
          .maybeSingle();

      if (!mounted) {
        return false;
      }

      debugPrint(
        'CALL DEBUG: hasil validasi terbaru untuk $callId: '
        '$latestCall',
      );

      if (latestCall == null ||
          latestCall['status']?.toString() != 'ringing' ||
          latestCall['receiver_id']?.toString() !=
              currentUserId) {
        debugPrint(
          'CALL DEBUG: dialog dilewati; status/receiver tidak cocok untuk $callId',
        );
        return true;
      }

      final latestCreatedAt = DateTime.tryParse(
        latestCall['created_at']?.toString() ?? '',
      );

      if (latestCreatedAt == null) {
        return true;
      }

      final latestAge = DateTime.now().toUtc().difference(
            latestCreatedAt.toUtc(),
          );

      if (latestAge.isNegative ||
          latestAge > const Duration(seconds: 45)) {
        debugPrint(
          'CALL DEBUG: dialog dilewati karena umur panggilan '
          'tidak valid/kedaluwarsa: $latestAge, id=$callId',
        );
        return true;
      }

      debugPrint('CALL DEBUG: menampilkan dialog untuk $callId');
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
                  child: Text('Panggilan Masuk'),
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
                  'Menghubungi Anda melalui panggilan suara.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                icon: const Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
                label: const Text(
                  'Tolak',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
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
        return false;
      }

      // Periksa apakah akun masih sama.
      final activeUserId =
          Supabase.instance.client.auth.currentUser?.id;

      if (activeUserId != currentUserId) {
        return true;
      }

      // Pastikan panggilan belum dibatalkan oleh pemanggil.
      final finalCall = await Supabase.instance.client
          .from('voice_calls')
          .select('status, caller_id, receiver_id')
          .eq('id', callId)
          .maybeSingle();

      if (!mounted) {
        return false;
      }

      if (finalCall == null ||
          finalCall['status']?.toString() != 'ringing' ||
          finalCall['receiver_id']?.toString() !=
              currentUserId) {
        return true;
      }

      debugPrint('CALL DEBUG: hasil dialog id=$callId, accepted=$accepted');

      if (accepted == true) {
        // Buka halaman panggilan untuk menerima panggilan.
        final navigator = navigatorKey.currentState;

        if (navigator == null) {
          return false;
        }

        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => VoiceCallPage(
              peerId: callerId,
              peerName: 'Pengguna KOSTRADAR',
              incomingCallId: callId,
            ),
          ),
        );

        return true;
      }

      // Tolak panggilan jika pengguna menekan tombol Tolak.
      await Supabase.instance.client
          .from('voice_calls')
          .update({
            'status': 'declined',
            'ended_at': DateTime.now()
                .toUtc()
                .toIso8601String(),
          })
          .eq('id', callId)
          .eq('status', 'ringing');

      debugPrint('CALL: panggilan ditolak $callId');

      return true;
    } catch (error, stackTrace) {
      debugPrint('CALL DIALOG ERROR: $error');
      debugPrint('$stackTrace');
      return false;
    } finally {
      isIncomingDialogOpen = false;

      // Proses panggilan berikutnya setelah dialog ditutup.
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _processIncomingCallQueue();
          }
        });
      }
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
          '/daftar-chat': (c) => const DaftarChatPage(),
          '/profil': (c) => const ProfilPage(),

          // ADMIN
          '/home-admin': (c) => const HomeAdminPage(),
          '/data-kost': (c) => const DataKostPage(),
          '/tambah-edit-kost': (c) =>
              const TambahEditKostPage(),
          '/daftar-chat-admin': (c) =>
              const DaftarChatAdminPage(
                chatData: {},
              ),
          '/profil-admin': (c) => const ProfilAdminPage(),
        },
      ),
    );
  }
}
