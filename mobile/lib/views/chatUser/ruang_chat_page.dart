import 'voice_call_page.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  final Map<String, Future<String>> _imageUrls = {};

  Map<String, dynamic>? _kostInfo;
  String _partnerName = '';
  String? _partnerPhoto;

  bool _isSending = false;
  bool _markingRead = false;
  int _lastMessageCount = -1;

  String? get _myId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();

    _partnerName = widget.namaAdmin.trim().isNotEmpty
        ? widget.namaAdmin.trim()
        : 'Pemilik Kost';

    // Data kost dari halaman detail harus didahulukan.
    _kostInfo = widget.kostInfo == null
        ? null
        : Map<String, dynamic>.from(widget.kostInfo!);

    _fetchPartnerProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).listenToMessages(widget.idAdminTujuan);

      _markMessagesRead();
    });

    // Cari kost dari riwayat chat hanya jika belum ada data kost.
    if (_kostInfo == null || _kostInfo!.isEmpty) {
      _fetchKostInfo();
    }
  }

  Future<void> _fetchPartnerProfile() async {
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
      debugPrint('Gagal menandai pesan dibaca: $e');
    } finally {
      _markingRead = false;
    }
  }

  // Mengubah bentuk data relasi foto menjadi string URL.
  String _extractPhoto(dynamic raw) {
    if (raw == null) return '';

    if (raw is String) {
      return raw.trim();
    }

    if (raw is List && raw.isNotEmpty) {
      return _extractPhoto(raw.first);
    }

    if (raw is Map) {
      return _extractPhoto(
        raw['foto_url'] ??
            raw['foto'] ??
            raw['url'] ??
            raw['foto_kost'],
      );
    }

    return '';
  }

  // Mencari data kost ketika room dibuka tanpa data dari detail kost.
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

      final kostId = rows.first['id_kost']?.toString();

      if (kostId == null || kostId.isEmpty) return;

      // Relasi foto mengikuti model KostModel pada proyek.
      final response = await _supabase
          .from('kost')
          .select('*, foto_kost(foto)')
          .eq('id_kost', kostId)
          .maybeSingle();

      if (!mounted || response == null) return;

      final data = Map<String, dynamic>.from(response);
      final photo = _extractPhoto(data['foto_kost']);

      if (photo.isNotEmpty) {
        data['foto_kost'] = photo;
      }

      setState(() {
        _kostInfo = data;
      });
    } catch (e) {
      debugPrint('Gagal mengambil informasi kost: $e');
    }
  }

  Widget _avatar() {
    final photo = _partnerPhoto?.trim() ?? '';

    final initial = _partnerName.trim().isNotEmpty
        ? _partnerName.trim()[0].toUpperCase()
        : 'P';

    if (photo.startsWith('http://') ||
        photo.startsWith('https://')) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFF0F2F5),
        backgroundImage: NetworkImage(photo),
        onBackgroundImageError: (_, __) {},
      );
    }

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
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
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

                  final photo =
                      await activeController.takePicture();

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, photo);
                  }
                } catch (e) {
                  debugPrint('Gagal mengambil foto: $e');

                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengambil foto: $e'),
                      ),
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
      debugPrint('Kamera gagal dibuka: $e');
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
        widget.idAdminTujuan,
        image,
        idKost: _kostInfo?['id_kost']?.toString(),
      );

      if (!mounted) return;

      _scrollToLatest();
      _showMessage('Foto berhasil dikirim.');
    } catch (e, st) {
      debugPrint('Gagal mengirim foto mahasiswa: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) _showMessage('Foto gagal dikirim: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    final myId = _myId;

    if (myId == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (widget.idAdminTujuan.isEmpty ||
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
      if (mounted) _showMessage('Pesan gagal dikirim: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    if (message.pengirimId != _myId) return;

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

  Widget _kostPhotoPlaceholder() {
    return Container(
      color: const Color(0xFFF0F2F5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.home_outlined,
        size: 25,
        color: Color(0xFF8291A2),
      ),
    );
  }

  // Kartu kost responsif dengan foto, nama, harga, dan sisa kamar.
  Widget _buildKostCard() {
    final kost = _kostInfo!;

    final name = (
      kost['nama_kost'] ??
      kost['nama'] ??
      kost['nama_kostan'] ??
      'Informasi Kost'
    ).toString();

    final rawPrice = kost['harga']?.toString().trim() ?? '';

    String formattedPrice;

    if (rawPrice.startsWith('Rp')) {
      formattedPrice = rawPrice;
    } else {
      final amount = double.tryParse(rawPrice) ?? 0;
      final digits = amount.toInt().toString();
      final buffer = StringBuffer();

      for (var i = 0; i < digits.length; i++) {
        if (i > 0 && (digits.length - i) % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(digits[i]);
      }

      formattedPrice =
          'Rp ${buffer.toString()}/bulan';
    }

    final availableRooms = kost['ketersediaan_kamar'] ??
        kost['ketersediaanKamar'] ??
        kost['sisa_kamar'] ??
        kost['kamar_tersedia'];

    final photoUrl = _extractPhoto(
      kost['foto_kost'] ??
          kost['foto'] ??
          kost['foto_url'],
    );

    final hasPhoto = photoUrl.startsWith('http://') ||
        photoUrl.startsWith('https://');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE6ECF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 54,
              height: 58,
              child: hasPhoto
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _kostPhotoPlaceholder(),
                    )
                  : _kostPhotoPlaceholder(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF25313A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formattedPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (availableRooms != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F8EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A765),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sisa $availableRooms',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF168653),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
        actions: [IconButton(tooltip: 'Telepon suara', icon: const Icon(Icons.call), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VoiceCallPage(peerId: widget.idAdminTujuan, peerName: _partnerName))) )],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_kostInfo != null && _kostInfo!.isNotEmpty)
              _buildKostCard(),
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
        final myId = _myId;

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
          (message) =>
              message.pengirimId == widget.idAdminTujuan &&
              message.penerimaId == myId &&
              !message.isRead,
        );

        if (unreadIncoming && !_markingRead) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _markMessagesRead();
          });
        }

        return ColoredBox(
          color: Colors.white,
          child: ListView.builder(
            controller: _scrollController,
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
                controller: _messageController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
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
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
