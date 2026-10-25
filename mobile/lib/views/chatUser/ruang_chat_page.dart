
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/chat_provider.dart';

class RuangChatPage extends StatefulWidget {
  final String idAdminTujuan;
  final String namaAdmin;
  final Map<String, dynamic>? kostInfo;

  const RuangChatPage({
    super.key,
    required this.idAdminTujuan,
    required this.namaAdmin,
    this.kostInfo,
  });

  @override
  State<RuangChatPage> createState() => _RuangChatPageState();
}

class _RuangChatPageState extends State<RuangChatPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _kostInfo;
  String _partnerName = '';
  String? _partnerPhoto;

  bool _isSending = false;
  bool _markingRead = false;
  bool _fetchingProfile = false;

  int _lastMessageCount = -1;

  String? get _myId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();

    _partnerName = widget.namaAdmin.trim().isNotEmpty
        ? widget.namaAdmin.trim()
        : 'Pemilik Kost';

    _kostInfo = widget.kostInfo;

    _fetchPartnerProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).listenToMessages(widget.idAdminTujuan);

      _markMessagesRead();
    });

    if (_kostInfo == null || _kostInfo!.isEmpty) {
      _fetchKostInfo();
    }
  }

  Future<void> _fetchPartnerProfile() async {
    if (_fetchingProfile) return;
    _fetchingProfile = true;

    try {
      final profile = await _supabase
          .from('users')
          .select('id_user, username, foto_profile, role')
          .eq('id_user', widget.idAdminTujuan)
          .maybeSingle();

      if (!mounted || profile == null) return;

      final name = profile['username']?.toString().trim();
      final photo = profile['foto_profile']?.toString().trim();

      setState(() {
        if (name != null && name.isNotEmpty && name != 'null') {
          _partnerName = name;
        }

        _partnerPhoto =
            photo != null && photo.isNotEmpty && photo != 'null'
                ? photo
                : null;
      });
    } catch (e) {
      debugPrint('Gagal mengambil profil pemilik kost: $e');
    } finally {
      _fetchingProfile = false;
    }
  }

  Future<void> _markMessagesRead() async {
    if (_markingRead || _myId == null) return;

    _markingRead = true;

    try {
      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).markMessagesAsRead(widget.idAdminTujuan);
    } catch (e) {
      debugPrint('Gagal menandai pesan sudah dibaca: $e');
    } finally {
      _markingRead = false;
    }
  }

  Future<void> _fetchKostInfo() async {
    final myId = _myId;
    if (myId == null) return;

    try {
      final rows = await _supabase
          .from('messages')
          .select('id_kost')
          .or(
            'and(pengirim_id.eq.$myId,'
            'penerima_id.eq.${widget.idAdminTujuan}),'
            'and(pengirim_id.eq.${widget.idAdminTujuan},'
            'penerima_id.eq.$myId)',
          )
          .not('id_kost', 'is', null)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) return;

      final kostId = rows.first['id_kost'];
      if (kostId == null) return;

      final kost = await _supabase
          .from('kost')
          .select()
          .eq('id_kost', kostId)
          .maybeSingle();

      if (!mounted || kost == null) return;

      setState(() {
        _kostInfo = kost;
      });
    } catch (e) {
      debugPrint('Gagal mengambil informasi kost: $e');
    }
  }

  Widget _avatar({double radius = 20}) {
    final photo = _partnerPhoto?.trim() ?? '';
    final name = _partnerName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    if (photo.startsWith('https://') || photo.startsWith('http://')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF0F2F5),
        child: ClipOval(
          child: Image.network(
            photo,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialAvatar(initial, radius),
          ),
        ),
      );
    }

    return _initialAvatar(initial, radius);
  }

  Widget _initialAvatar(String initial, double radius) {
    return CircleAvatar(
      radius: radius,
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

  void _scrollToLatest({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final target = _scrollController.position.maxScrollExtent;

      if (!animate) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    final myId = _myId;

    if (myId == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (widget.idAdminTujuan.trim().isEmpty ||
        widget.idAdminTujuan == myId) {
      _showMessage('ID penerima tidak valid.');
      return;
    }

    setState(() => _isSending = true);

    try {
      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).sendNewMessage(
        widget.idAdminTujuan,
        text,
        idKost: _kostInfo?['id_kost']?.toString(),
      );

      if (!mounted) return;

      _messageController.clear();
      _scrollToLatest();
    } catch (e) {
      debugPrint('Gagal mengirim pesan mahasiswa: $e');

      if (mounted) {
        _showMessage('Pesan gagal dikirim: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    if (message.pengirimId != _myId) return;

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
    _messageController.dispose();
    _scrollController.dispose();
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
                    _partnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF17232B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Pemilik Kost',
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
            if (_kostInfo != null) _buildKostCard(),
            Expanded(child: _buildMessages()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildKostCard() {
    final kost = _kostInfo!;

    final name = (
      kost['nama_kost'] ??
      kost['nama'] ??
      kost['nama_kostan'] ??
      'Informasi Kost'
    ).toString();

    final price = kost['harga']?.toString() ?? '';
    final rawPhoto = kost['foto'] ?? kost['foto_kost'] ?? kost['foto_url'];

    String photo = '';

    if (rawPhoto is String && rawPhoto.startsWith('http')) {
      photo = rawPhoto;
    } else if (rawPhoto is List && rawPhoto.isNotEmpty) {
      photo = rawPhoto.first.toString();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: photo.startsWith('http')
                ? Image.network(
                    photo,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _kostPlaceholder(),
                  )
                : _kostPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17232B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Informasi kost',
                  style: TextStyle(
                    color: Color(0xFF667781),
                    fontSize: 11,
                  ),
                ),
                if (price.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    price.startsWith('Rp') ? price : 'Rp $price',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF075E54),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kostPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: const Color(0xFFF7F8FA),
      child: const Icon(
        Icons.home_outlined,
        color: Color(0xFF667781),
      ),
    );
  }

  Widget _buildMessages() {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final messages = provider.messages;
        final myId = _myId;

        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF075E54),
            ),
          );
        }

        final hasUnreadIncoming = messages.any(
          (message) =>
              message.pengirimId == widget.idAdminTujuan &&
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
          _scrollToLatest(animate: messages.isNotEmpty);
        }

        return ColoredBox(
          color: Colors.white,
          child: messages.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada percakapan.\nKirim pesan untuk mulai!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF667781),
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
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
                controller: _messageController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFF9BBEAA),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFF075E54),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
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
