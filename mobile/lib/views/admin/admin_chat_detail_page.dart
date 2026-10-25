
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _supabase = Supabase.instance.client;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  final Map<String, Future<String>> _imageUrls = {};

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
        debugPrint('Gagal mengambil profil ${lookup.$1}: $e');
      }
    }

    if (!mounted || profile == null) return;

    String? findValue(List<String> keys) {
      for (final key in keys) {
        final value = profile![key]?.toString().trim();

        if (value != null &&
            value.isNotEmpty &&
            value != 'null') {
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
      debugPrint('Gagal menandai pesan dibaca: $e');
    } finally {
      _markingRead = false;
    }
  }

  Widget _avatar() {
    final photo = _receiverPhoto?.trim() ?? '';
    final initial = _receiverName.trim().isEmpty
        ? 'M'
        : _receiverName.trim()[0].toUpperCase();

    if (photo.startsWith('http')) {
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

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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

  Future<XFile?> _captureWithCamera() async {
    CameraController? controller;

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw StateError('Kamera tidak ditemukan.');
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return null;

      final activeController = controller;

      return await showDialog<XFile>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ambil Foto'),
          content: SizedBox(
            width: 360,
            child: AspectRatio(
              aspectRatio: activeController.value.aspectRatio,
              child: CameraPreview(activeController),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () async {
                try {
                  if (!activeController.value.isInitialized ||
                      activeController.value.isTakingPicture) {
                    return;
                  }

                  final photo = await activeController.takePicture();

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, photo);
                  }
                } catch (e) {
                  debugPrint('Gagal mengambil foto: $e');

                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Gagal mengambil foto: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto'),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('Kamera tidak dapat dibuka: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) {
        _showMessage('Kamera tidak dapat dibuka: $e');
      }

      return null;
    } finally {
      await controller?.dispose();
    }
  }

  Future<void> _showImageOptions() async {
    if (_isSending) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'Kirim Foto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () =>
                  Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () =>
                  Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final image = source == ImageSource.camera
          ? await _captureWithCamera()
          : await ImagePicker().pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
              maxWidth: 1600,
              maxHeight: 1600,
            );

      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        _showMessage('Foto tidak dapat dibaca.');
        return;
      }

      if (bytes.length > 10 * 1024 * 1024) {
        _showMessage('Ukuran foto maksimal 10 MB.');
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pratinjau Foto'),
          content: Image.memory(
            bytes,
            width: 280,
            height: 280,
            fit: BoxFit.contain,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Kirim'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() => _isSending = true);

      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).sendImageMessage(
        widget.receiverId,
        image,
        idKost: widget.idKost,
      );

      if (!mounted) return;

      _scrollToLatest();
      _showMessage('Foto berhasil dikirim.');
    } catch (e, st) {
      debugPrint('Gagal mengirim foto admin: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) _showMessage('Foto gagal dikirim: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
      if (mounted) _showMessage('Pesan gagal dikirim: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // Menghapus hanya pesan milik admin yang sedang login.
  Future<void> _deleteMessage(ChatMessage message) async {
    if (message.pengirimId != userId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message.isImage ? 'Hapus Foto' : 'Hapus Pesan'),
        content: Text(
          message.isImage
              ? 'Hapus foto ini dari percakapan?'
              : 'Hapus pesan ini dari percakapan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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

      if (mounted) {
        _showMessage(
          message.isImage
              ? 'Foto berhasil dihapus.'
              : 'Pesan berhasil dihapus.',
        );
      }
    } catch (e) {
      if (mounted) _showMessage('Gagal menghapus pesan: $e');
    }
  }

  Future<String> _signedImageUrl(
    ChatProvider provider,
    String path,
  ) {
    return _imageUrls.putIfAbsent(
      path,
      () => provider.getImageSignedUrl(path),
    );
  }

  Future<void> _openImage(
    ChatProvider provider,
    String path,
  ) async {
    try {
      final url = await _signedImageUrl(provider, path);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Foto tidak dapat dimuat.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _showMessage('Foto gagal dibuka: $e');
    }
  }

  Widget _buildImage(ChatProvider provider, String path) {
    return FutureBuilder<String>(
      future: _signedImageUrl(provider, path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 190,
            height: 120,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            width: 190,
            height: 90,
            child: Center(child: Text('Foto gagal dimuat')),
          );
        }

        return GestureDetector(
          onTap: () => _openImage(provider, path),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              snapshot.data!,
              width: 210,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 190,
                height: 90,
                child: Center(child: Text('Foto gagal dimuat')),
              ),
            ),
          ),
        );
      },
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
            child: CircularProgressIndicator(),
          );
        }

        if (_lastMessageCount != messages.length) {
          _lastMessageCount = messages.length;
          _scrollToLatest();
        }

        final unreadIncoming = messages.any(
          (m) =>
              m.pengirimId == widget.receiverId &&
              m.penerimaId == myId &&
              !m.isRead,
        );

        if (unreadIncoming && !_markingRead) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _markMessagesRead();
          });
        }

        return ColoredBox(
          color: Colors.white,
          child: ListView.builder(
            controller: scrollController,
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message.pengirimId == myId;

              return Align(
                alignment:
                    isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: GestureDetector(
                  onLongPress:
                      isMe ? () => _deleteMessage(message) : null,
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
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (message.isImage &&
                            (message.mediaUrl?.isNotEmpty ?? false))
                          _buildImage(provider, message.mediaUrl!)
                        else
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
      padding: const EdgeInsets.fromLTRB(6, 7, 10, 7),
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
            IconButton(
              tooltip: 'Kirim foto',
              onPressed: _isSending ? null : _showImageOptions,
              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF64748B),
                size: 29,
              ),
            ),
            Expanded(
              child: TextField(
                controller: messageController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
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
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF2563EB),
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
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
