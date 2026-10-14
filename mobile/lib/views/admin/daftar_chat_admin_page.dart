
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import 'home_admin_page.dart';
import 'data_kost_page.dart';
import 'profil_admin_page.dart';

class DaftarChatAdminPage extends StatefulWidget {
  const DaftarChatAdminPage({
    super.key,
    Map<String, dynamic> chatData = const {},
  });

  @override
  State<DaftarChatAdminPage> createState() =>
      _DaftarChatAdminPageState();
}

class _DaftarChatAdminPageState extends State<DaftarChatAdminPage> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> chats = [];
  bool loading = true;
  String? error;
  RealtimeChannel? channel;

  String? get userId => supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    loadChats();

    channel = supabase
        .channel('admin-chat-list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => loadChats(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    searchController.dispose();
    if (channel != null) {
      supabase.removeChannel(channel!);
    }
    super.dispose();
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

    try {
      final rows = await supabase
          .from('messages')
          .select(
            'id_message, pengirim_id, penerima_id, id_kost, isi_pesan',
          )
          .or('penerima_id.eq.$me,pengirim_id.eq.$me');

      final latest = <String, Map<String, dynamic>>{};

      for (final row in rows) {
        final message = Map<String, dynamic>.from(row);
        final sender = message['pengirim_id']?.toString() ?? '';
        final receiver = message['penerima_id']?.toString() ?? '';
        final other = sender == me ? receiver : sender;

        if (other.isNotEmpty && other != me) {
          latest.putIfAbsent(other, () {
            return {
              'user_id': other,
              'message': message['isi_pesan'] ?? '',
              'id_kost': message['id_kost'],
            };
          });
        }
      }

      if (!mounted) return;
      setState(() {
        chats = latest.values.toList();
        loading = false;
        error = null;
      });
    } catch (e, stackTrace) {
      debugPrint('Gagal memuat chat: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Gagal memuat chat: $e';
      });
    }
  }

  List<Map<String, dynamic>> get filteredChats {
    final keyword = searchController.text.trim().toLowerCase();

    return chats.where((chat) {
      return chat['user_id']
              .toString()
              .toLowerCase()
              .contains(keyword) ||
          chat['message']
              .toString()
              .toLowerCase()
              .contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = filteredChats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.white,
              padding: const EdgeInsets.all(18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KOSTRADAR ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pesan Masuk',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kelola percakapan dengan pengguna',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari ID pengguna atau pesan...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  error!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      loading = true;
                                      error = null;
                                    });
                                    loadChats();
                                  },
                                  child: const Text('Coba lagi'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : data.isEmpty
                          ? RefreshIndicator(
                              onRefresh: loadChats,
                              child: ListView(
                                children: const [
                                  SizedBox(height: 140),
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 54,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text('Belum ada percakapan'),
                                  ),
                                  SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      'Pesan pengguna akan muncul di sini.',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: loadChats,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  final chat = data[index];
                                  final id = chat['user_id'].toString();
                                  final shortId = id.length > 8
                                      ? id.substring(0, 8)
                                      : id;

                                  return Card(
                                    color: AppColors.white,
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor:
                                            AppColors.primaryLight,
                                        child: Icon(
                                          Icons.person_outline,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      title: Text(
                                        'Pengguna $shortId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        chat['message'].toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textSecondary,
                                      ),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AdminChatDetailPage(
                                              receiverId: id,
                                              idKost: chat['id_kost']
                                                  ?.toString(),
                                            ),
                                          ),
                                        );
                                        loadChats();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppColors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(
                context,
                Icons.home_outlined,
                'Home',
                const HomeAdminPage(),
              ),
              navItem(
                context,
                Icons.apartment_outlined,
                'Data Kost',
                const DataKostPage(),
              ),
              navItem(
                context,
                Icons.chat_bubble,
                'Chat',
                null,
                active: true,
              ),
              navItem(
                context,
                Icons.person_outline,
                'Profil',
                const ProfilAdminPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(
    BuildContext context,
    IconData icon,
    String label,
    Widget? page, {
    bool active = false,
  }) {
    final color =
        active ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        if (page != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
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

class _AdminChatDetailPageState extends State<AdminChatDetailPage> {
  final supabase = Supabase.instance.client;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  String? error;
  RealtimeChannel? channel;

  String? get myId => supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    loadMessages();

    channel = supabase
        .channel('admin-conversation-${widget.receiverId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => loadMessages(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    if (channel != null) {
      supabase.removeChannel(channel!);
    }
    super.dispose();
  }

  Future<void> loadMessages() async {
    final me = myId;

    if (me == null) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Silakan login kembali.';
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
      debugPrint('Gagal memuat pesan: $e');

      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Gagal memuat pesan: $e';
      });
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    final me = myId;
    final kostId = widget.idKost;

    if (text.isEmpty || me == null || sending) return;

    if (kostId == null || kostId.isEmpty || kostId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pesan belum dapat dikirim karena ID kost belum tersedia.',
          ),
        ),
      );
      return;
    }

    setState(() => sending = true);

    try {
      await supabase.from('messages').insert({
        'pengirim_id': me,
        'penerima_id': widget.receiverId,
        'id_kost': kostId,
        'isi_pesan': text,
      });

      messageController.clear();
      await loadMessages();
    } catch (e) {
      debugPrint('Gagal mengirim pesan: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesan gagal dikirim: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = myId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Pengguna ${widget.receiverId.substring(0, widget.receiverId.length > 8 ? 8 : widget.receiverId.length)}',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : messages.isEmpty
                        ? const Center(child: Text('Belum ada pesan'))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final mine =
                                  message['pengirim_id'].toString() == me;

                              return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 290,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: mine
                                        ? AppColors.primary
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    message['isi_pesan'].toString(),
                                    style: TextStyle(
                                      color: mine
                                          ? AppColors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    onPressed: sending ? null : sendMessage,
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppColors.white,
                          ),
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
