
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/smooth_motion.dart';
import 'ruang_chat_page.dart';

class DaftarChatPage extends StatefulWidget {
  const DaftarChatPage({super.key});

  @override
  State<DaftarChatPage> createState() => _DaftarChatPageState();
}

class _DaftarChatPageState extends State<DaftarChatPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController =
      TextEditingController();

  bool _isLoading = true;
  bool _hanyaBelumDibaca = false;

  List<Map<String, dynamic>> _chatConversations = [];

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // MEMUAT DAFTAR CHAT, NAMA, DAN FOTO PROFIL
  // =========================================================

  Future<void> _fetchConversations() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final currentUser = _supabase.auth.currentUser;
      final userId = currentUser?.id;

      if (userId == null) {
        if (!mounted) return;

        setState(() {
          _chatConversations = [];
          _isLoading = false;
        });
        return;
      }

      // Ambil pesan yang dikirim atau diterima oleh pengguna.
      final response = await _supabase
          .from('messages')
          .select()
          .or('pengirim_id.eq.$userId,penerima_id.eq.$userId')
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> groupedChat = {};

      for (final item in response) {
        final msg = Map<String, dynamic>.from(item);

        final senderId = msg['pengirim_id']?.toString() ?? '';
        final receiverId = msg['penerima_id']?.toString() ?? '';

        final lawanId =
            senderId == userId ? receiverId : senderId;

        if (lawanId.isEmpty || lawanId == userId) {
          continue;
        }

        // Karena pesan sudah diurutkan terbaru terlebih dahulu,
        // pesan pertama untuk setiap lawan adalah pesan terakhir.
        if (!groupedChat.containsKey(lawanId)) {
          final createdAt = DateTime.tryParse(
            msg['created_at']?.toString() ?? '',
          );

          final waktu = createdAt == null
              ? ''
              : '${createdAt.hour.toString().padLeft(2, '0')}:'
                '${createdAt.minute.toString().padLeft(2, '0')}';

          groupedChat[lawanId] = {
            'id_lawan': lawanId,
            'nama_lawan': 'Pengelola Kost',
            'foto_lawan': '',
            'pesan_terakhir':
                msg['isi_pesan']?.toString() ?? '',
            'waktu': waktu,
            'created_at': createdAt,
            'belum_dibaca': receiverId == userId &&
                msg['is_read'] == false,
          };
        }
      }

      // Ambil profil lawan chat dari tabel users.
      final lawanIds = groupedChat.keys.toList();

      if (lawanIds.isNotEmpty) {
        try {
          final profiles = await _supabase
              .from('users')
              .select('id_user, username, foto_profile')
              .inFilter('id_user', lawanIds);

          for (final item in profiles) {
            final profile = Map<String, dynamic>.from(item);
            final id = profile['id_user']?.toString() ?? '';

            if (!groupedChat.containsKey(id)) continue;

            final nama =
                profile['username']?.toString().trim() ?? '';
            final foto =
                profile['foto_profile']?.toString().trim() ?? '';

            if (nama.isNotEmpty) {
              groupedChat[id]!['nama_lawan'] = nama;
            }

            if (foto.startsWith('http')) {
              groupedChat[id]!['foto_lawan'] = foto;
            }
          }
        } catch (e) {
          // Daftar chat tetap ditampilkan jika data profil gagal diambil.
          debugPrint('Gagal memuat profil lawan chat: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _chatConversations = groupedChat.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat percakapan: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal memuat percakapan. Periksa koneksi dan database.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // PENCARIAN DAN FILTER CHAT
  // =========================================================

  List<Map<String, dynamic>> get _filteredConversations {
    final query = _searchController.text.trim().toLowerCase();

    return _chatConversations.where((chat) {
      final nama =
          (chat['nama_lawan'] ?? '').toString().toLowerCase();
      final pesan =
          (chat['pesan_terakhir'] ?? '').toString().toLowerCase();

      final belumDibaca = chat['belum_dibaca'] == true;

      final cocokPencarian = query.isEmpty ||
          nama.contains(query) ||
          pesan.contains(query);

      final cocokFilter =
          !_hanyaBelumDibaca || belumDibaca;

      return cocokPencarian && cocokFilter;
    }).toList();
  }

  // =========================================================
  // TAMPILAN UTAMA
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final conversations = _filteredConversations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          // PENCARIAN
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari percakapan...',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _searchController.clear,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

          // FILTER: HANYA SEMUA CHAT DAN BELUM DIBACA.
          // TOMBOL SUDAH BOOKING SUDAH DIHAPUS.
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  label: 'Semua Chat',
                  selected: !_hanyaBelumDibaca,
                  onTap: () {
                    setState(() => _hanyaBelumDibaca = false);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Belum Dibaca',
                  selected: _hanyaBelumDibaca,
                  showUnreadDot: true,
                  onTap: () {
                    setState(() => _hanyaBelumDibaca = true);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // DAFTAR PERCAKAPAN
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : conversations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchConversations,
                        child: ListView.separated(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          itemCount: conversations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final chat = conversations[index];

                            final nama =
                                chat['nama_lawan']?.toString() ??
                                    'Pengelola Kost';
                            final pesan =
                                chat['pesan_terakhir']?.toString() ??
                                    '';
                            final waktu =
                                chat['waktu']?.toString() ?? '';
                            final idLawan =
                                chat['id_lawan']?.toString() ?? '';
                            final foto =
                                chat['foto_lawan']?.toString() ?? '';
                            final belumDibaca =
                                chat['belum_dibaca'] == true;

                            final adaFoto = foto.startsWith('http');

                            return SmoothEntrance(
                              index: index,
                              child: Material(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RuangChatPage(
                                        idAdminTujuan: idLawan,
                                        namaAdmin: nama,
                                      ),
                                    ),
                                  ).then((_) {
                                    _fetchConversations();
                                  });
                                },

                                // FOTO PROFIL LAWAN CHAT
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      AppColors.primaryLight,
                                  backgroundImage: adaFoto
                                      ? NetworkImage(foto)
                                      : null,
                                  child: adaFoto
                                      ? null
                                      : Text(
                                          nama.isNotEmpty
                                              ? nama[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                ),

                                // NAMA LAWAN CHAT
                                title: Text(
                                  nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),

                                // PESAN TERAKHIR
                                subtitle: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 5),
                                  child: Text(
                                    pesan.isEmpty
                                        ? 'Mulai percakapan'
                                        : pesan,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: belumDibaca
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: belumDibaca
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                // WAKTU DAN INDIKATOR PESAN BARU
                                trailing: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      waktu,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                    if (belumDibaca) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration:
                                            const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ));
                          },
                        ),
                      ),
          ),

          // TIPS KOMUNIKASI AMAN
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips Komunikasi Aman',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Lakukan transaksi dan konfirmasi sewa melalui aplikasi KostRadar untuk membantu menjaga keamanan Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHIP FILTER
  // =========================================================

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool showUnreadDot = false,
  }) {
    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.white
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showUnreadDot) ...[
                const SizedBox(width: 7),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    final sedangMencari =
        _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: AppColors.textHint.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              sedangMencari
                  ? 'Percakapan tidak ditemukan'
                  : _hanyaBelumDibaca
                      ? 'Tidak ada pesan belum dibaca'
                      : 'Belum ada percakapan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sedangMencari
                  ? 'Coba gunakan kata kunci lain.'
                  : _hanyaBelumDibaca
                      ? 'Semua pesan sudah dibaca.'
                      : 'Cari kost yang Anda inginkan, lalu mulai mengobrol dengan pengelola kost.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
