
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_chat_detail_page.dart';
import 'home_admin_page.dart';
import 'data_kost_page.dart';
import 'profil_admin_page.dart';

const Color _blue = Color(0xFF2563EB);
const Color _pageBg = Color(0xFFF7F8FA);
const Color _textMain = Color(0xFF18212F);
const Color _textMuted = Color(0xFF8993A4);
const Color _line = Color(0xFFE8EBF0);
const Color _unreadRed = Color(0xFFD93040);

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
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController =
      TextEditingController();

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  List<Map<String, dynamic>> _chats = [];

  bool _loading = true;
  bool _fetching = false;
  bool _fetchAgain = false;

  String _search = '';
  int _filter = 0;

  // Hanya dua filter sesuai permintaan.
  final List<String> _filters = const [
    'Semua Chat',
    'Belum Dibaca',
  ];

  String? get _myId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    _loadChats();
    _listenRealtime();
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _search = _searchController.text.trim().toLowerCase();
    });
  }

  void _listenRealtime() {
    _subscription?.cancel();

    _subscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id_message'])
        .order('created_at', ascending: false)
        .listen(
      (_) {
        if (mounted) {
          _loadChats();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Realtime daftar chat admin gagal: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Menggabungkan data profil dari beberapa tabel.
  // Kolom kosong dari users tidak menimpa data mahasiswa.
  Future<Map<String, dynamic>> _loadPartnerProfile(
    String partnerId,
  ) async {
    final merged = <String, dynamic>{};

    final lookups = [
      ('users', 'id_user'),
      ('mahasiswa', 'id_user'),
      ('mahasiswa', 'id'),
    ];

    for (final lookup in lookups) {
      try {
        final response = await _supabase
            .from(lookup.$1)
            .select()
            .eq(lookup.$2, partnerId)
            .maybeSingle();

        if (response == null) continue;

        final row = Map<String, dynamic>.from(response);

        for (final entry in row.entries) {
          final value = entry.value;

          if (value == null) continue;

          if (value is String &&
              (value.trim().isEmpty || value.trim() == 'null')) {
            continue;
          }

          final current = merged[entry.key];

          if (current == null ||
              current.toString().trim().isEmpty ||
              current.toString() == 'null') {
            merged[entry.key] = value;
          }
        }
      } catch (e) {
        // Tabel atau kolom alternatif mungkin tidak tersedia.
        debugPrint(
          'Pencarian profil ${lookup.$1}.${lookup.$2} gagal: $e',
        );
      }
    }

    debugPrint(
      'Profil chat $partnerId: '
      'username=${merged['username']}, '
      'foto_profile=${merged['foto_profile']}, '
      'foto_profil=${merged['foto_profil']}',
    );

    return merged;
  }

  String _pick(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = row[key]?.toString().trim() ?? '';

      if (value.isNotEmpty && value != 'null') {
        return value;
      }
    }

    return fallback;
  }

  Future<void> _loadChats() async {
    if (_fetching) {
      _fetchAgain = true;
      return;
    }

    _fetching = true;

    final myId = _myId;

    if (myId == null) {
      if (mounted) {
        setState(() {
          _chats = [];
          _loading = false;
        });
      }

      _fetching = false;
      return;
    }

    try {
      final response = await _supabase
          .from('messages')
          .select()
          .or('pengirim_id.eq.$myId,penerima_id.eq.$myId')
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(response);

      final latestByPartner = <String, Map<String, dynamic>>{};
      final unreadByPartner = <String, int>{};

      for (final message in rows) {
        final sender =
            message['pengirim_id']?.toString() ?? '';

        final receiver =
            message['penerima_id']?.toString() ?? '';

        if (sender.isEmpty || receiver.isEmpty) continue;

        final partnerId = sender == myId ? receiver : sender;

        if (partnerId == myId) continue;

        // Hitung seluruh pesan masuk yang belum dibaca admin.
        if (receiver == myId && message['is_read'] != true) {
          unreadByPartner[partnerId] =
              (unreadByPartner[partnerId] ?? 0) + 1;
        }

        // Pesan sudah diurutkan dari terbaru.
        latestByPartner.putIfAbsent(
          partnerId,
          () => message,
        );
      }

      final result = <Map<String, dynamic>>[];

      for (final entry in latestByPartner.entries) {
        final partnerId = entry.key;
        final message = entry.value;

        // Ambil profil lengkap agar foto bisa dicari di tabel alternatif.
        final profile = await _loadPartnerProfile(partnerId);

        final createdAt = DateTime.tryParse(
              message['created_at']?.toString() ?? '',
            )?.toLocal() ??
            DateTime.now();

        final photo = _pick(
          profile,
          [
            'foto_profile',
            'foto_profil',
            'foto_url',
            'avatar_url',
            'profile_photo_url',
            'profile_photo',
            'foto',
            'photo',
            'image',
          ],
        );

        result.add({
          'partner_id': partnerId,
          'name': _pick(
            profile,
            [
              'username',
              'nama',
              'nama_mahasiswa',
              'nama_lengkap',
              'full_name',
              'display_name',
              'name',
            ],
            fallback: 'Mahasiswa',
          ),
          'photo': photo,
          'verified': profile['is_verified'] == true,
          'message': _pick(
            message,
            ['isi_pesan', 'message'],
          ),
          'created_at': createdAt,
          'unread': unreadByPartner[partnerId] ?? 0,
          'id_kost': message['id_kost'],
        });
      }

      result.sort(
        (a, b) => (b['created_at'] as DateTime)
            .compareTo(a['created_at'] as DateTime),
      );

      if (!mounted) return;

      setState(() {
        _chats = result;
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Gagal memuat daftar chat admin: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } finally {
      _fetching = false;

      if (_fetchAgain && mounted) {
        _fetchAgain = false;
        unawaited(_loadChats());
      }
    }
  }

  String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return months[month - 1];
  }

  String _formatTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) return '';

    final local = date.toLocal();
    final now = DateTime.now();

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }

    return '${local.day.toString().padLeft(2, '0')} '
        '${_month(local.month)}';
  }

  List<Map<String, dynamic>> get _filteredChats {
    return _chats.where((chat) {
      final unread = (chat['unread'] as int? ?? 0) > 0;

      final name =
          chat['name']?.toString().toLowerCase() ?? '';

      final message =
          chat['message']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          name.contains(_search) || message.contains(_search);

      final matchesFilter = _filter == 1 ? unread : true;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  bool _isValidImageUrl(String path) {
    return path.startsWith('https://') ||
        path.startsWith('http://');
  }

  Widget _fallbackAvatar(String name) {
    final initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : 'M';

    return CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFFE4EDF9),
      child: Text(
        initial,
        style: const TextStyle(
          color: _blue,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }

  Widget _avatar(Map<String, dynamic> chat) {
    final name = chat['name']?.toString() ?? 'Mahasiswa';
    final photo = chat['photo']?.toString().trim() ?? '';

    final validImage = _isValidImageUrl(photo);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: const Color(0xFFE4EDF9),
          child: validImage
              ? ClipOval(
                  child: Image.network(
                    photo,
                    key: ValueKey(photo),
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _fallbackAvatar(name);
                    },
                  ),
                )
              : _fallbackAvatar(name),
        ),
        if (chat['verified'] == true)
          const Positioned(
            right: -2,
            top: -1,
            child: Icon(
              Icons.verified,
              color: _blue,
              size: 15,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chats = _filteredChats;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        foregroundColor: _textMain,
        elevation: 0,
        title: const Text(
          'Chat',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loadChats,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari percakapan...',
                  hintStyle: const TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: _textMuted,
                    size: 21,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF0F1F4),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final selected = _filter == index;
                  final hasUnread =
                      _chats.any((chat) => (chat['unread'] as int? ?? 0) > 0);

                  return ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _filter = index);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: _blue,
                    side: BorderSide(
                      color: selected ? _blue : _line,
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_filters[index]),
                        if (index == 1 && hasUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: _unreadRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _textMain,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _blue,
                      ),
                    )
                  : chats.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada percakapan.',
                            style: TextStyle(color: _textMuted),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadChats,
                          color: _blue,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              10, 4, 10, 10,
                            ),
                            itemCount: chats.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 7),
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              final unread =
                                  chat['unread'] as int? ?? 0;
                              final hasUnread = unread > 0;
                              final name =
                                  chat['name']?.toString() ?? 'Mahasiswa';
                              final message =
                                  chat['message']?.toString() ?? '';

                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AdminChatDetailPage(
                                          receiverId:
                                              chat['partner_id'].toString(),
                                          idKost:
                                              chat['id_kost']?.toString(),
                                        ),
                                      ),
                                    );

                                    if (mounted) _loadChats();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        _avatar(chat),
                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: _textMain,
                                                  fontSize: 13,
                                                  fontWeight: hasUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                message.isEmpty
                                                    ? 'Mulai percakapan'
                                                    : message,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: hasUnread
                                                      ? _textMain
                                                      : _textMuted,
                                                  fontSize: 11,
                                                  fontWeight: hasUnread
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 6),

                                        SizedBox(
                                          width: 43,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _formatTime(
                                                  chat['created_at'],
                                                ),
                                                style: TextStyle(
                                                  color: hasUnread
                                                      ? _blue
                                                      : _textMuted,
                                                  fontSize: 9,
                                                  fontWeight: hasUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              if (hasUnread)
                                                Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 17,
                                                    minHeight: 17,
                                                  ),
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 4,
                                                  ),
                                                  alignment: Alignment.center,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: _unreadRed,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    unread > 99
                                                        ? '99+'
                                                        : '$unread',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),

            _buildSafetyTip(),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E4F7)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: _blue,
            child: Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 15,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Komunikasi Aman',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _textMain,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Selalu lakukan transaksi dan konfirmasi sewa '
                  'melalui aplikasi KostRadar untuk keamanan deposit '
                  'dan garansi kamar Anda.',
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.35,
                    color: Color(0xFF69778A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _blue,
      unselectedItemColor: _textMuted,
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
}
