
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_config.dart';
import 'home_admin_page.dart';
import 'data_kost_page.dart';
import 'profil_admin_page.dart';

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
  }

  Future<void> loadChats() async {
    final me = userId;

    if (me == null) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Silakan login terlebih dahulu.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final rows = await supabase
          .from('messages')
          .select(
            'id_message, pengirim_id, penerima_id, id_kost, isi_pesan',
          )
          .or('penerima_id.eq.$me,pengirim_id.eq.$me');

      final Map<String, Map<String, dynamic>> grouped = {};

      for (final row in rows) {
        final message = Map<String, dynamic>.from(row);
        final sender =
            message['pengirim_id']?.toString() ?? '';
        final receiver =
            message['penerima_id']?.toString() ?? '';

        final other = sender == me ? receiver : sender;

        if (other.isEmpty || other == me) continue;

        if (!grouped.containsKey(other)) {
          grouped[other] = {
            'user_id': other,
            'message': '',
            'id_kost': message['id_kost'],
            'has_incoming': false,
            'has_outgoing': false,
          };
        }

        if (receiver == me) {
          grouped[other]!['has_incoming'] = true;
        }

        if (sender == me) {
          grouped[other]!['has_outgoing'] = true;
        }

        grouped[other]!['message'] =
            message['isi_pesan']?.toString() ?? '';

        grouped[other]!['id_kost'] = message['id_kost'];
      }

      if (!mounted) return;

      setState(() {
        chats = grouped.values.toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Gagal memuat chat: $e';
      });
    }
  }

  List<Map<String, dynamic>> get filteredChats {
    final keyword =
        searchController.text.trim().toLowerCase();

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
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = filteredChats;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'KOSTRADAR ADMIN',
          style: TextStyle(
            color: Color(0xFF2563EB),
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
              color: Color(0xFF2563EB),
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
                  color: Color(0xFF172554),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Kelola percakapan dengan calon penyewa kost Anda.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20, 18, 20, 12,
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari pengguna atau isi pesan...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
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
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : Colors.black12,
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildChatList(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(
    List<Map<String, dynamic>> data,
  ) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
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
                color: Colors.red,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadChats,
                child: const Text('Coba Lagi'),
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
                color: Colors.black26,
              ),
              const SizedBox(height: 12),
              Text(
                chats.isEmpty
                    ? 'Belum ada percakapan.'
                    : 'Tidak ada chat yang sesuai filter.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadChats,
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
            color: Colors.white,
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
                  loadChats();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: Text(
                        id.isNotEmpty
                            ? id[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengguna $shortId',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
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
                              color: Colors.black54,
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
                      color: Colors.black38,
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
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: Colors.grey,
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
          MaterialPageRoute(
            builder: (_) => page,
          ),
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
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: incoming
              ? const Color(0xFF166534)
              : const Color(0xFF1D4ED8),
        ),
      ),
    );
  }
}

class AdminChatDetailPage extends StatefulWidget {
  final String receiverId;
  final String? idKost;

  const AdminChatDetailPage({
    super.key,
    required this.receiverId,
    this.idKost,
  });

  @override
  State<AdminChatDetailPage> createState() =>
      _AdminChatDetailPageState();
}

class _AdminChatDetailPageState
    extends State<AdminChatDetailPage> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  String? error;

  final List<String> quickResponses = [
    'Halo, terima kasih sudah menghubungi kami. Ada yang bisa kami bantu?',
    'Baik, kami akan memeriksa informasi tersebut terlebih dahulu.',
    'Kost masih tersedia. Apakah Anda ingin mengetahui detail kamar?',
    'Untuk jadwal survei, silakan informasikan hari dan jam yang Anda inginkan.',
    'Terima kasih. Jika ada pertanyaan lain, silakan hubungi kami kembali.',
  ];

  String? get userId => supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    final me = userId;

    if (me == null) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Silakan login terlebih dahulu.';
      });
      return;
    }

    try {
      final rows = await supabase
          .from('messages')
          .select(
            'id_message, pengirim_id, penerima_id, id_kost, isi_pesan',
          )
          .or(
            'and(pengirim_id.eq.$me,penerima_id.eq.${widget.receiverId}),'
            'and(pengirim_id.eq.${widget.receiverId},penerima_id.eq.$me)',
          );

      if (!mounted) return;

      setState(() {
        messages = rows
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        loading = false;
        error = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(
            scrollController.position.maxScrollExtent,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Gagal memuat pesan: $e';
      });
    }
  }

  void chooseQuickResponse(String response) {
    messageController.text = response;
    messageController.selection = TextSelection.collapsed(
      offset: messageController.text.length,
    );
  }

  Future<void> sendMessage() async {
    final me = userId;
    final text = messageController.text.trim();

    if (me == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (text.isEmpty) {
      _showMessage('Tulis pesan terlebih dahulu.');
      return;
    }

    if (widget.idKost == null || widget.idKost!.isEmpty) {
      _showMessage(
        'ID kost belum tersedia. Pesan belum dapat dikirim.',
      );
      return;
    }

    setState(() => sending = true);

    try {
      await supabase.from('messages').insert({
        'pengirim_id': me,
        'penerima_id': widget.receiverId,
        'id_kost': widget.idKost,
        'isi_pesan': text,
      });

      messageController.clear();
      await loadMessages();

      if (mounted) {
        setState(() => sending = false);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => sending = false);
      _showMessage('Pesan gagal dikirim: $e');
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF172554),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Percakapan',
              style: TextStyle(
                color: Color(0xFF172554),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              widget.receiverId.length > 16
                  ? '${widget.receiverId.substring(0, 16)}...'
                  : widget.receiverId,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: loadMessages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: loadMessages,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada pesan. Mulai percakapan dengan mengirim pesan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isAdmin =
            message['pengirim_id']?.toString() == userId;

        return Align(
          alignment: isAdmin
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width * 0.78,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isAdmin
                  ? const Color(0xFF2563EB)
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft:
                    Radius.circular(isAdmin ? 16 : 4),
                bottomRight:
                    Radius.circular(isAdmin ? 4 : 16),
              ),
            ),
            child: Text(
              message['isi_pesan']?.toString() ?? '',
              style: TextStyle(
                color: isAdmin
                    ? Colors.white
                    : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.flash_on,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(width: 6),
                Text(
                  'Respons Cepat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickResponses.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    label: Text(
                      'Respons ${index + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(
                      Icons.bolt,
                      size: 16,
                    ),
                    onPressed: () => chooseQuickResponse(
                      quickResponses[index],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed: sending ? null : sendMessage,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor:
                          const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
