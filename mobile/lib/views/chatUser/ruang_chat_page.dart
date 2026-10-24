
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
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
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _resolvedKostInfo;
  String _chatPartnerName = '';
  String? _chatPartnerPhoto;
  int _lastMessageCount = -1;
  bool _isLoadingKost = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _chatPartnerName = widget.namaAdmin.trim().isNotEmpty
        ? widget.namaAdmin.trim()
        : 'Pengelola Kost';
    _fetchChatPartnerProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).listenToMessages(widget.idAdminTujuan);
    });

    if (widget.kostInfo != null && widget.kostInfo!.isNotEmpty) {
      _resolvedKostInfo = widget.kostInfo;
      _isLoadingKost = false;
    } else {
      _fetchKostFromDatabase();
    }
  }


  // Mengambil nama dan foto lawan bicara dari public.users.
  // idAdminTujuan harus berisi UUID akun pemilik kost (users.id_user),
  // bukan UUID kost (kost.id_kost).
  Future<void> _fetchChatPartnerProfile() async {
    final targetId = widget.idAdminTujuan.trim();

    if (targetId.isEmpty) {
      debugPrint('ID tujuan room chat kosong.');
      return;
    }

    try {
      debugPrint('Memuat profil room chat dari users, ID: $targetId');

      final profile = await _supabase
          .from('users')
          .select('id_user, username, foto_profile, role')
          .eq('id_user', targetId)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        debugPrint(
          'Profil tidak ditemukan di public.users untuk id_user=$targetId. '
          'Pastikan ID yang dikirim saat membuka room adalah UUID pemilik kost.',
        );
        return;
      }

      final username = profile['username']?.toString().trim();
      final photo = profile['foto_profile']?.toString().trim();
      final role = profile['role']?.toString().trim();

      debugPrint(
        'Profil room chat berhasil dibaca: '
        'username=$username, role=$role, foto=$photo',
      );

      setState(() {
        if (username != null &&
            username.isNotEmpty &&
            username != 'null') {
          _chatPartnerName = username;
        }

        _chatPartnerPhoto =
            photo != null &&
                    photo.isNotEmpty &&
                    photo != 'null'
                ? photo
                : null;
      });
    } catch (e, stackTrace) {
      debugPrint('Gagal mengambil profil room chat: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Widget _buildPartnerAvatar({double radius = 18}) {
    final photo = _chatPartnerPhoto?.trim() ?? '';
    final name = _chatPartnerName.trim();

    Widget fallbackAvatar() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (photo.isEmpty ||
        !(photo.startsWith('https://') ||
            photo.startsWith('http://'))) {
      return fallbackAvatar();
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: ClipOval(
        child: Image.network(
          photo,
          key: ValueKey(photo),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Foto profil room chat gagal dimuat: $error');
            return fallbackAvatar();
          },
        ),
      ),
    );
  }

  void _scrollToLatest({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (!animate) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _fetchKostFromDatabase() async {
    try {
      // Cari kost berdasarkan ID pemilik.
      // Jika tidak ditemukan, coba berdasarkan ID kost.
      var response = await _supabase
          .from('kost')
          .select()
          .eq('id_user', widget.idAdminTujuan)
          .limit(1)
          .maybeSingle();

      response ??= await _supabase
            .from('kost')
            .select()
            .eq('id_kost', widget.idAdminTujuan)
            .maybeSingle();

      if (!mounted) return;

      setState(() {
        _resolvedKostInfo = response;
        _isLoadingKost = false;
      });
    } catch (e) {
      debugPrint('Gagal mengambil data kost: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingKost = false;
      });
    }
  }

  // Mengirim pesan dan menunggu hasil operasi Supabase.
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu.'),
        ),
      );
      return;
    }

    if (widget.idAdminTujuan.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID tujuan chat tidak valid.'),
        ),
      );
      return;
    }

    if (currentUser.id == widget.idAdminTujuan) {
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
      final idKost = _resolvedKostInfo?['id_kost']?.toString();

      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).sendNewMessage(
        widget.idAdminTujuan,
        text,
        idKost: idKost,
      );

      if (!mounted) return;

      // Kosongkan input hanya setelah pengiriman berhasil.
      _messageController.clear();
      _scrollToLatest();
    } catch (e, stackTrace) {
      debugPrint('Gagal mengirim pesan: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesan gagal dikirim: $e'),
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = _supabase.auth.currentUser?.id;

    final String namaKost =
        _resolvedKostInfo?['nama_kost'] ??
        _resolvedKostInfo?['nama'] ??
        _resolvedKostInfo?['title'] ??
        widget.namaAdmin;

    final String fotoKost =
        _resolvedKostInfo?['foto_kost'] ??
        _resolvedKostInfo?['image'] ??
        _resolvedKostInfo?['foto'] ??
        _resolvedKostInfo?['photo'] ??
        '';

    final rawHarga =
        _resolvedKostInfo?['harga'] ??
        _resolvedKostInfo?['price'] ??
        '';

    final String hargaKost = rawHarga.toString().isNotEmpty
        ? rawHarga.toString()
        : 'Hubungi Pengelola';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            _buildPartnerAvatar(radius: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _chatPartnerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          // Informasi kost.
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: fotoKost.isNotEmpty
                      ? Image.network(
                          fotoKost,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _defaultImageContainer(),
                        )
                      : _defaultImageContainer(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaKost,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Terverifikasi',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hargaKost.startsWith('Rp')
                            ? hargaKost
                            : 'Rp $hargaKost',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Daftar pesan.
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.messages;
                if (_lastMessageCount != messages.length) {
                  _lastMessageCount = messages.length;
                  _scrollToLatest(animate: messages.length > 0);
                }

                if (chatProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada percakapan.\nKirim pesan untuk mulai!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.pengirimId == myUserId;

                    final localCreatedAt = msg.createdAt.toLocal();
                    final String timeString =
                        '${localCreatedAt.hour.toString().padLeft(2, '0')}:'
                        '${localCreatedAt.minute.toString().padLeft(2, '0')}';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          if (!isMe) return;

                          showDialog<void>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Hapus Pesan'),
                                content: const Text(
                                  'Apakah kamu yakin ingin menghapus pesan ini?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                    },
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(dialogContext);

                                      try {
                                        await Provider.of<ChatProvider>(
                                          context,
                                          listen: false,
                                        ).deleteMessage(msg.idMessage);
                                      } catch (e) {
                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Gagal menghapus pesan: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              _buildPartnerAvatar(radius: 14),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.70,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.primary
                                      : AppColors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft:
                                        Radius.circular(isMe ? 16 : 4),
                                    bottomRight:
                                        Radius.circular(isMe ? 4 : 16),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.cardShadow,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      msg.message,
                                      style: TextStyle(
                                        color: isMe
                                            ? AppColors.white
                                            : AppColors.textPrimary,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeString,
                                          style: TextStyle(
                                            color: isMe
                                                ? AppColors.white.withValues(
                                                    alpha: 0.7,
                                                  )
                                                : AppColors.textHint,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Kolom input pesan.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isSending,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
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
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
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
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _defaultImageContainer() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.primaryLight,
      child: const Icon(
        Icons.home,
        color: AppColors.primary,
      ),
    );
  }
}
