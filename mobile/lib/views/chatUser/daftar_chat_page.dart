
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ruang_chat_page.dart';

const Color _studentBlue = Color(0xFF2563EB);
const Color _studentPageBg = Color(0xFFF7F8FA);
const Color _studentText = Color(0xFF18212F);
const Color _studentMuted = Color(0xFF8993A4);
const Color _studentLine = Color(0xFFE8EBF0);
const Color _studentRed = Color(0xFFD93040);

class DaftarChatPage extends StatefulWidget {
  const DaftarChatPage({super.key});

  @override
  State<DaftarChatPage> createState() => _DaftarChatPageState();
}

class _DaftarChatPageState extends State<DaftarChatPage> {
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

  final List<String> _filters = const [
    'Semua Chat',
    'Belum Dibaca',
    'Sudah Booking',
  ];

  String? get _myId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchChanged);
    _loadChats();
    _listenRealtime();
  }

  void _searchChanged() {
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
        if (mounted) _loadChats();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Realtime daftar chat mahasiswa: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.removeListener(_searchChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _pick(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return fallback;
  }

  Future<Map<String, dynamic>> _loadProfile(String id) async {
    try {
      final row = await _supabase
          .from('users')
          .select()
          .eq('id_user', id)
          .maybeSingle();

      if (row != null) return Map<String, dynamic>.from(row);
    } catch (e) {
      debugPrint('Profil pemilik kost tidak tersedia: $e');
    }

    return {};
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

      final latest = <String, Map<String, dynamic>>{};
      final unread = <String, int>{};

      for (final row in rows) {
        final sender = row['pengirim_id']?.toString() ?? '';
        final receiver = row['penerima_id']?.toString() ?? '';

        if (sender.isEmpty || receiver.isEmpty) continue;

        final other = sender == myId ? receiver : sender;
        if (other == myId) continue;

        if (receiver == myId && row['is_read'] != true) {
          unread[other] = (unread[other] ?? 0) + 1;
        }

        latest.putIfAbsent(other, () => row);
      }

      final result = <Map<String, dynamic>>[];

      for (final entry in latest.entries) {
        final id = entry.key;
        final message = entry.value;
        final profile = await _loadProfile(id);

        final createdAt = DateTime.tryParse(
              message['created_at']?.toString() ?? '',
            )?.toLocal() ??
            DateTime.now();

        result.add({
          'partner_id': id,
          'name': _pick(
            profile,
            [
              'username',
              'nama',
              'nama_lengkap',
              'full_name',
              'display_name',
              'name',
            ],
            fallback: 'Pemilik Kost',
          ),
          'photo': _pick(
            profile,
            [
              'foto_profile',
              'foto_profil',
              'foto_url',
              'avatar_url',
              'profile_photo_url',
            ],
          ),
          'verified': profile['is_verified'] == true,
          'message': _pick(
            message,
            ['isi_pesan', 'message'],
          ),
          'created_at': createdAt,
          'unread': unread[id] ?? 0,
          'last_unread':
              message['penerima_id']?.toString() == myId &&
              message['is_read'] != true,
          'has_booking_context': message['id_kost'] != null,
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
      debugPrint('Gagal memuat daftar chat mahasiswa: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _loading = false);
    } finally {
      _fetching = false;

      if (_fetchAgain && mounted) {
        _fetchAgain = false;
        unawaited(_loadChats());
      }
    }
  }

  String _time(dynamic value) {
    final date = DateTime.tryParse(value.toString());
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

  String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[month - 1];
  }

  List<Map<String, dynamic>> get _filtered {
    return _chats.where((chat) {
      final unread = (chat['unread'] as int? ?? 0) > 0;
      final booked = chat['has_booking_context'] == true;

      final name = chat['name'].toString().toLowerCase();
      final message = chat['message'].toString().toLowerCase();

      final searchMatch =
          name.contains(_search) || message.contains(_search);

      final filterMatch = switch (_filter) {
        1 => unread,
        2 => booked,
        _ => true,
      };

      return searchMatch && filterMatch;
    }).toList();
  }

  Widget _avatar(Map<String, dynamic> chat) {
    final name = chat['name']?.toString() ?? 'P';
    final photo = chat['photo']?.toString() ?? '';
    final initial = name.trim().isEmpty
        ? 'P'
        : name.trim()[0].toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: const Color(0xFFE4EDF9),
          backgroundImage:
              photo.startsWith('http') ? NetworkImage(photo) : null,
          onBackgroundImageError:
              photo.startsWith('http') ? (_, _) {} : null,
          child: photo.startsWith('http')
              ? null
              : Text(
                  initial,
                  style: const TextStyle(
                    color: _studentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        if (chat['verified'] == true)
          const Positioned(
            right: -2,
            top: -1,
            child: Icon(
              Icons.verified,
              color: _studentBlue,
              size: 15,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chats = _filtered;

    return Scaffold(
      backgroundColor: _studentPageBg,
      appBar: AppBar(
        backgroundColor: _studentPageBg,
        foregroundColor: _studentText,
        elevation: 0,
        title: const Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadChats,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
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
                    color: _studentMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: _studentMuted,
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
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final selected = _filter == index;
                  final hasUnread =
                      _chats.any((c) => (c['unread'] as int) > 0);

                  return ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filter = index),
                    backgroundColor: Colors.white,
                    selectedColor: _studentBlue,
                    side: BorderSide(
                      color: selected ? _studentBlue : _studentLine,
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
                              color: _studentRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _studentText,
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
                  ? const Center(child: CircularProgressIndicator())
                  : chats.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada percakapan.',
                            style: TextStyle(color: _studentMuted),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadChats,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              10, 4, 10, 10,
                            ),
                            itemCount: chats.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 7),
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              final unread =
                                  chat['unread'] as int? ?? 0;
                              final hasUnread = unread > 0;
                              final name = chat['name'].toString();
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
                                        builder: (_) => RuangChatPage(
                                          idAdminTujuan:
                                              chat['partner_id'].toString(),
                                          namaAdmin: name,
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
                                                  color: _studentText,
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
                                                      ? _studentText
                                                      : _studentMuted,
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
                                                _time(chat['created_at']),
                                                style: TextStyle(
                                                  color: hasUnread
                                                      ? _studentBlue
                                                      : _studentMuted,
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
                                                    color: _studentRed,
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
            backgroundColor: _studentBlue,
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
                    color: _studentText,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Selalu lakukan transaksi dan konfirmasi sewa '
                  'melalui aplikasi KostRadar untuk keamanan '
                  'deposit dan garansi kamar Anda.',
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
}
