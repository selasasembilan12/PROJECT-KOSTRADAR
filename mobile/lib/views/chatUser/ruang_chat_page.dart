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
  final TextEditingController _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _resolvedKostInfo;
  bool _isLoadingKost = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false)
          .listenToMessages(widget.idAdminTujuan);
    });

    // Jika kostInfo dikirim dari halaman detail, langsung pakai. Jika tidak, ambil dari database.
    if (widget.kostInfo != null && widget.kostInfo!.isNotEmpty) {
      setState(() {
        _resolvedKostInfo = widget.kostInfo;
        _isLoadingKost = false;
      });
    } else {
      _fetchKostFromDatabase();
    }
  }

  // Ambil data kost langsung dari Supabase berdasarkan idAdminTujuan
  Future<void> _fetchKostFromDatabase() async {
    try {
      // Coba cari di tabel kost berdasarkan pemilik atau id
      var response = await _supabase
          .from('kost')
          .select()
          .eq('pemilik_id', widget.idAdminTujuan)
          .maybeSingle();

      if (response == null) {
        response = await _supabase
            .from('kost')
            .select()
            .eq('id', widget.idAdminTujuan)
            .maybeSingle();
      }

      if (response != null && mounted) {
        setState(() {
          _resolvedKostInfo = response;
          _isLoadingKost = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingKost = false);
      }
    } catch (e) {
      debugPrint("Gagal mengambil data kost: $e");
      if (mounted) setState(() => _isLoadingKost = false);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    Provider.of<ChatProvider>(context, listen: false)
        .sendNewMessage(widget.idAdminTujuan, _messageController.text.trim());
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = _supabase.auth.currentUser?.id;
    
    // Ambil data dari _resolvedKostInfo (hasil kiriman atau hasil fetch database)
    final String namaKost = _resolvedKostInfo?['nama_kost'] ?? _resolvedKostInfo?['nama'] ?? _resolvedKostInfo?['title'] ?? widget.namaAdmin;
    final String fotoKost = _resolvedKostInfo?['foto_kost'] ?? _resolvedKostInfo?['image'] ?? _resolvedKostInfo?['foto'] ?? _resolvedKostInfo?['photo'] ?? '';
    
    var rawHarga = _resolvedKostInfo?['harga'] ?? _resolvedKostInfo?['price'] ?? '';
    final String hargaKost = rawHarga.toString().isNotEmpty ? rawHarga.toString() : 'Hubungi Pengelola';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                widget.namaAdmin.isNotEmpty ? widget.namaAdmin[0] : 'P',
                style: const TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.namaAdmin,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // KARTU INFORMASI KOST
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
                          errorBuilder: (_, __, ___) => _defaultImageContainer(),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                        hargaKost.startsWith('Rp') ? hargaKost : 'Rp $hargaKost',
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
          
          // DAFTAR PESAN
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.messages;
                if (chatProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada percakapan.\nKirim pesan untuk mulai!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.pengirimId == myUserId;
                    final String timeString = '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          if (isMe) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Hapus Pesan'),
                                  content: const Text('Apakah kamu yakin ingin menghapus pesan ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Provider.of<ChatProvider>(context, listen: false)
                                            .deleteMessage(msg.idMessage);
                                      },
                                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : AppColors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
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
                                  color: isMe ? AppColors.white : AppColors.textPrimary,
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
                                      color: isMe ? AppColors.white.withOpacity(0.7) : AppColors.textHint,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check, size: 12, color: Colors.white70),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // INPUT FIELD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      icon: const Icon(Icons.send_rounded, color: AppColors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultImageContainer() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.primaryLight,
      child: const Icon(Icons.home, color: AppColors.primary),
    );
  }
}