
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/chat_provider.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController messageController =
      TextEditingController();
  final ScrollController scrollController = ScrollController();

  String _receiverName = 'Mahasiswa';
  String? _receiverPhoto;

  bool _isSending = false;
  bool _markingRead = false;
  int _lastMessageCount = -1;

  String? get userId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();

    _fetchReceiverProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).listenToMessages(widget.receiverId);

      _markMessagesRead();
    });
  }

  Future<void> _fetchReceiverProfile() async {
    Map<String, dynamic>? profile;

    for (final lookup in [
      ('users', 'id_user'),
      ('mahasiswa', 'id_user'),
      ('mahasiswa', 'id'),
    ]) {
      try {
        profile = await _supabase
            .from(lookup.$1)
            .select()
            .eq(lookup.$2, widget.receiverId)
            .maybeSingle();

        if (profile != null) break;
      } catch (e) {
        debugPrint('Pencarian profil ${lookup.$1} gagal: $e');
      }
    }

    if (!mounted || profile == null) return;

    String? findValue(List<String> keys) {
      for (final key in keys) {
        final value = profile![key]?.toString().trim();

        if (value != null && value.isNotEmpty && value != 'null') {
          return value;
        }
      }
      return null;
    }

    final name = findValue([
      'username',
      'nama',
      'nama_mahasiswa',
      'nama_lengkap',
      'full_name',
      'display_name',
      'name',
    ]);

    final photo = findValue([
      'foto_profile',
      'foto_profil',
      'foto',
      'foto_url',
      'avatar_url',
      'profile_photo_url',
      'profile_photo',
    ]);

    setState(() {
      if (name != null) _receiverName = name;
      _receiverPhoto = photo;
    });
  }

  Future<void> _markMessagesRead() async {
    if (_markingRead || userId == null) return;

    _markingRead = true;

    try {
      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).markMessagesAsRead(widget.receiverId);
    } catch (e) {
      debugPrint('Gagal menandai pesan sudah dibaca: $e');
    } finally {
      _markingRead = false;
    }
  }

  Widget _avatar() {
    final photo = _receiverPhoto?.trim() ?? '';
    final name = _receiverName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    if (photo.startsWith('https://') || photo.startsWith('http://')) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFF0F2F5),
        child: ClipOval(
          child: Image.network(
            photo,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialAvatar(initial),
          ),
        ),
      );
    }

    return _initialAvatar(initial);
  }

  Widget _initialAvatar(String initial) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFF0F2F5),
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF075E54),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    final myId = userId;

    if (myId == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (widget.receiverId.isEmpty || widget.receiverId == myId) {
      _showMessage('ID penerima tidak valid.');
      return;
    }

    setState(() => _isSending = true);

    try {
      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).sendNewMessage(
        widget.receiverId,
        text,
        idKost: widget.idKost,
      );

      if (!mounted) return;

      messageController.clear();
      _scrollToLatest();
    } catch (e) {
      debugPrint('Gagal mengirim pesan admin: $e');

      if (mounted) {
        _showMessage('Pesan gagal dikirim: $e');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    if (message.pengirimId != userId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pesan'),
        content: const Text('Yakin ingin menghapus pesan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).deleteMessage(message.idMessage);
    } catch (e) {
      _showMessage('Gagal menghapus pesan: $e');
    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF25313A),
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            _avatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _receiverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF17232B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Mahasiswa',
                    style: TextStyle(
                      color: Color(0xFF667781),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildMessages()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final messages = provider.messages;
        final myId = userId;

        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF075E54),
            ),
          );
        }

        final hasUnreadIncoming = messages.any(
          (message) =>
              message.pengirimId == widget.receiverId &&
              message.penerimaId == myId &&
              !message.isRead,
        );

        if (hasUnreadIncoming && !_markingRead) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _markMessagesRead();
          });
        }

        if (_lastMessageCount != messages.length) {
          _lastMessageCount = messages.length;
          _scrollToLatest();
        }

        return ColoredBox(
          color: Colors.white,
          child: messages.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada pesan.\nMulai percakapan dengan mengirim pesan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF667781),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.pengirimId == myId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isMe
                            ? () => _deleteMessage(message)
                            : null,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.60,
                          ),
                          margin: const EdgeInsets.only(bottom: 7),
                          padding: const EdgeInsets.fromLTRB(8, 6, 6, 4),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFFD9FDD3)
                                : const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(8),
                              topRight: const Radius.circular(8),
                              bottomLeft: Radius.circular(isMe ? 8 : 2),
                              bottomRight: Radius.circular(isMe ? 2 : 8),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                message.message,
                                softWrap: true,
                                style: const TextStyle(
                                  color: Color(0xFF17232B),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(message.createdAt),
                                    style: const TextStyle(
                                      color: Color(0xFF596B73),
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.done_all,
                                      size: 17,
                                      color: message.isRead
                                          ? const Color(0xFF34B7F1)
                                          : const Color(0xFF8696A0),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                );
              },
            ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF667781),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFF075E54),
              child: IconButton(
                onPressed: _isSending ? null : sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
