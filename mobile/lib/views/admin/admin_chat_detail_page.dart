
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// IMPORT CORE THEME BIAR WARNANYA NYAMBUNG!
import '../../core/theme/app_theme.dart';
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

class _AdminChatDetailPageState extends State<AdminChatDetailPage> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();

  bool _isSending = false;
  String _receiverName = 'Mahasiswa';
  String? _receiverPhoto;
  int _lastMessageCount = -1;

  // Ambil ID admin yang sedang login.
  String? get userId =>
      Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _fetchReceiverProfile();

    // Aktifkan pemantauan pesan ketika admin membuka ruang chat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).listenToMessages(widget.receiverId);
    });
  }


  // Memuat profil mahasiswa yang sedang diajak bicara.
  Future<void> _fetchReceiverProfile() async {
    Map<String, dynamic>? profile;
    try {
      profile = await Supabase.instance.client
          .from('mahasiswa')
          .select()
          .eq('id', widget.receiverId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Profil mahasiswa tidak ditemukan lewat id: $e');
    }

    if (profile == null) {
      try {
        profile = await Supabase.instance.client
            .from('mahasiswa')
            .select()
            .eq('id_user', widget.receiverId)
            .maybeSingle();
      } catch (e) {
        debugPrint('Profil mahasiswa tidak ditemukan lewat id_user: $e');
      }
    }

    if (profile == null) {
      try {
        profile = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id_user', widget.receiverId)
            .maybeSingle();
      } catch (e) {
        debugPrint('Profil fallback users tidak ditemukan: $e');
      }
    }

    if (!mounted || profile == null) return;

    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = profile?[key]?.toString().trim();
        if (value != null && value.isNotEmpty && value != 'null') {
          return value;
        }
      }
      return null;
    }

    final name = pick([
      'nama', 'nama_mahasiswa', 'nama_lengkap', 'username', 'full_name',
      'display_name', 'name',
    ]);
    final photo = pick([
      'foto', 'foto_profil', 'foto_url', 'avatar_url', 'profile_photo_url',
      'photo', 'image',
    ]);

    setState(() {
      if (name != null) _receiverName = name;
      _receiverPhoto = photo;
    });
  }

  Widget _receiverAvatar() {
    final photo = _receiverPhoto;
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: NetworkImage(photo),
        onBackgroundImageError: (_, __) {},
      );
    }
    final name = _receiverName.trim();
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'M',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _scrollToLatest({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      final target = scrollController.position.maxScrollExtent;
      if (!animate) {
        scrollController.jumpTo(target);
      } else {
        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // Mengirim balasan admin ke mahasiswa.
  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    final currentUserId = userId;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu.'),
        ),
      );
      return;
    }

    if (widget.receiverId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID penerima tidak valid.'),
        ),
      );
      return;
    }

    if (currentUserId == widget.receiverId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ID pengirim dan penerima tidak boleh sama.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

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

      // Kosongkan input hanya setelah Supabase menerima pesan.
      messageController.clear();

      _scrollToLatest();
    } catch (e, stackTrace) {
      debugPrint('Gagal mengirim balasan admin: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim balasan: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
        ),
        title: Row(
          children: [
            _receiverAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _receiverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Mahasiswa',
                    style: TextStyle(
                      color: AppColors.textSecondary,
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
      builder: (context, chatProvider, child) {
        final messages = chatProvider.messages;

        if (chatProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (messages.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada pesan.\nMulai percakapan dengan mengirim pesan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        if (_lastMessageCount != messages.length) {
          _lastMessageCount = messages.length;
          _scrollToLatest(animate: messages.isNotEmpty);
        }

        return ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isAdmin = msg.pengirimId == userId;

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
                      ? AppColors.primary
                      : AppColors.white,
                  border: isAdmin
                      ? null
                      : Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(
                      isAdmin ? 16 : 4,
                    ),
                    bottomRight: Radius.circular(
                      isAdmin ? 4 : 16,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.message,
                      style: TextStyle(
                        color: isAdmin
                            ? AppColors.white
                            : AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${msg.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${msg.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isAdmin
                            ? AppColors.white.withValues(alpha: 0.72)
                            : AppColors.textHint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: AppColors.white,
                      ),
                onPressed: _isSending ? null : sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
