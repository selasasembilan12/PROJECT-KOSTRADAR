
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import 'home_admin_page.dart';
import 'data_kost_page.dart';
import 'profil_admin_page.dart';
import 'admin_chat_detail_page.dart';

class DaftarChatAdminPage extends StatefulWidget {
  final Map<String, dynamic> chatData;

  const DaftarChatAdminPage({
    super.key,
    this.chatData = const {},
  });

  @override
  State<DaftarChatAdminPage> createState() =>
      _DaftarChatAdminPageState();
}

class _DaftarChatAdminPageState
    extends State<DaftarChatAdminPage> {
  final TextEditingController searchController =
      TextEditingController();

  List<Map<String, dynamic>> chats = [];
  bool loading = true;
  String? error;
  int selectedFilter = 0;

  StreamSubscription<List<Map<String, dynamic>>>?
      _chatSubscription;

  final List<String> filterOptions = [
    'Semua',
    'Pesan Masuk',
    'Pesan Keluar',
  ];

  String? get userId => supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    loadChats();
    listenToChatChanges();
  }

  // Memantau perubahan pada tabel messages.
  void listenToChatChanges() {
    _chatSubscription?.cancel();

    // Primary key harus sesuai dengan tabel Supabase.
    _chatSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id_message'])
        .listen(
      (_) {
        if (!mounted) return;

        // Muat ulang daftar ketika ada perubahan pesan.
        loadChats();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Realtime daftar chat gagal: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  // Mengambil daftar percakapan yang melibatkan akun admin.
  Future<void> loadChats() async {
    final me = userId;

    if (me == null) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Silakan login terlebih dahulu.';
        chats = [];
      });
      return;
    }

    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final response = await supabase
          .from('messages')
          .select()
          .or('penerima_id.eq.$me,pengirim_id.eq.$me')
          .order('created_at', ascending: false);

      final List<dynamic> rows = response;
      final Map<String, Map<String, dynamic>> grouped = {};

      for (final row in rows) {
        final message = Map<String, dynamic>.from(row as Map);

        final sender =
            message['pengirim_id']?.toString() ?? '';
        final receiver =
            message['penerima_id']?.toString() ?? '';

        // Tentukan lawan bicara berdasarkan akun admin login.
        final other = sender == me ? receiver : sender;

        // Abaikan data yang tidak memiliki lawan bicara valid.
        if (other.isEmpty || other == me) continue;

        final String isiPesan =
            message['isi_pesan']?.toString() ??
            message['message']?.toString() ??
            '';

        // Hasil query sudah diurutkan dari pesan terbaru.
        // Karena itu, pesan pertama menjadi pesan terakhir percakapan.
        if (!grouped.containsKey(other)) {
          grouped[other] = {
            'user_id': other,
            'message': isiPesan,
            'id_kost': message['id_kost'],
            'has_incoming': false,
            'has_outgoing': false,
          };
        }

        // Pesan masuk berarti admin merupakan penerima.
        if (receiver == me) {
          grouped[other]!['has_incoming'] = true;
        }

        // Pesan keluar berarti admin merupakan pengirim.
        if (sender == me) {
          grouped[other]!['has_outgoing'] = true;
        }

        // Pertahankan pesan terbaru yang tidak kosong.
        if (grouped[other]!['message'].toString().isEmpty &&
            isiPesan.isNotEmpty) {
          grouped[other]!['message'] = isiPesan;
        }

        // Simpan ID kost jika tersedia pada pesan.
        if (message['id_kost'] != null) {
          grouped[other]!['id_kost'] = message['id_kost'];
        }
      }

      if (!mounted) return;

      setState(() {
        chats = grouped.values.toList();
        loading = false;
        error = null;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;

      debugPrint('Gagal memuat chat: $e');
      debugPrintStack(stackTrace: stackTrace);

      setState(() {
        loading = false;
        error = 'Gagal memuat chat: $e';
      });
    }
  }

  List<Map<String, dynamic>> get filteredChats {
    final keyword = searchController.text.trim().toLowerCase();

    return chats.where((chat) {
      final id =
          chat['user_id']?.toString().toLowerCase() ?? '';

      final message =
          chat['message']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          id.contains(keyword) || message.contains(keyword);

      final hasIncoming = chat['has_incoming'] == true;
      final hasOutgoing = chat['has_outgoing'] == true;

      bool matchesFilter;

      switch (selectedFilter) {
        case 1:
          matchesFilter = hasIncoming;
          break;
        case 2:
          matchesFilter = hasOutgoing;
          break;
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = filteredChats;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        title: const Text(
          'KOSTRADAR ADMIN',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: loadChats,
            icon: const Icon(
              Icons.refresh,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Pesan Masuk',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Kelola percakapan dengan calon penyewa kost Anda.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari pengguna atau isi pesan...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: filterOptions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = selectedFilter == index;

                  return ChoiceChip(
                    label: Text(filterOptions[index]),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = index;
                      });
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.white,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildChatList(data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<Map<String, dynamic>> data) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadChats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 58,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 12),
              Text(
                chats.isEmpty
                    ? 'Belum ada percakapan.'
                    : 'Tidak ada chat yang sesuai filter.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadChats,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: data.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final chat = data[index];

          final id = chat['user_id'].toString();
          final shortId =
              id.length > 12 ? '${id.substring(0, 12)}...' : id;

          return Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminChatDetailPage(
                      receiverId: id,
                      idKost: chat['id_kost']?.toString(),
                    ),
                  ),
                );

                if (mounted) {
                  await loadChats();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        id.isNotEmpty
                            ? id[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengguna $shortId',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            chat['message']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true
                                ? chat['message'].toString()
                                : 'Belum ada isi pesan',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (chat['has_incoming'] == true)
                                _directionTag('Masuk'),
                              if (chat['has_outgoing'] == true)
                                _directionTag('Keluar'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apartment_outlined),
          label: 'Data Kost',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
      onTap: (index) {
        if (index == 2) return;

        final Widget page;

        switch (index) {
          case 0:
            page = const HomeAdminPage();
            break;
          case 1:
            page = const DataKostPage();
            break;
          case 3:
            page = const ProfilAdminPage();
            break;
          default:
            return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  Widget _directionTag(String label) {
    final incoming = label == 'Masuk';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: incoming
            ? AppColors.successLight
            : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: incoming
              ? AppColors.success
              : AppColors.primary,
        ),
      ),
    );
  }
}
