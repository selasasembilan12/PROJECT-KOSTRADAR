
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import 'ruang_chat_page.dart';

class DaftarChatPage extends StatefulWidget {
  const DaftarChatPage({super.key});

  @override
  State<DaftarChatPage> createState() => _DaftarChatPageState();
}

class _DaftarChatPageState extends State<DaftarChatPage> {
  bool _isLoading = true;

  List<Map<String, dynamic>> _chatConversations = [];

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  // Mengambil daftar percakapan dan profil lawan bicara.
  Future<void> _fetchConversations() async {
    final supabase = Supabase.instance.client;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final myUserId = supabase.auth.currentUser?.id;

      if (myUserId == null) {
        if (!mounted) return;

        setState(() {
          _chatConversations = [];
          _isLoading = false;
        });
        return;
      }

      // Mengambil pesan milik pengguna yang sedang login.
      final response = await supabase
          .from('messages')
          .select()
          .or(
            'pengirim_id.eq.$myUserId,penerima_id.eq.$myUserId',
          )
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> groupedChat = {};

      for (final msg in response) {
        final senderId =
            msg['pengirim_id']?.toString() ?? '';

        final receiverId =
            msg['penerima_id']?.toString() ?? '';

        // Menentukan ID lawan bicara.
        final String lawanId =
            senderId == myUserId ? receiverId : senderId;

        if (lawanId.isEmpty || lawanId == myUserId) {
          continue;
        }

        // Pesan terbaru diproses lebih dahulu.
        if (groupedChat.containsKey(lawanId)) {
          continue;
        }

        final createdAt = msg['created_at'] != null
            ? DateTime.parse(
                msg['created_at'].toString(),
              ).toLocal()
            : DateTime.now();

        final String timeString =
            '${createdAt.hour.toString().padLeft(2, '0')}:'
            '${createdAt.minute.toString().padLeft(2, '0')}';

        groupedChat[lawanId] = {
          'id_lawan': lawanId,
          'nama_lawan': 'Pemilik Kost',
          'foto_lawan': null,
          'pesan_terakhir':
              msg['isi_pesan']?.toString() ?? '',
          'waktu': timeString,
          'belum_dibaca':
              receiverId == myUserId &&
              msg['is_read'] == false,
        };
      }

      // Mengambil profil dari tabel public.users.
      // Kolom disesuaikan dengan database milikmu.
      for (final entry in groupedChat.entries) {
        try {
          final profile = await supabase
              .from('users')
              .select(
                'id_user, username, foto_profile, role',
              )
              .eq('id_user', entry.key)
              .maybeSingle();

          if (profile == null) {
            debugPrint(
              'Profil tidak ditemukan untuk ID: ${entry.key}',
            );
            continue;
          }

          final username =
              profile['username']?.toString().trim();

          final foto =
              profile['foto_profile']?.toString().trim();

          final role =
              profile['role']?.toString().trim();

          if (username != null &&
              username.isNotEmpty &&
              username != 'null') {
            entry.value['nama_lawan'] = username;
          }

          if (foto != null &&
              foto.isNotEmpty &&
              foto != 'null') {
            entry.value['foto_lawan'] = foto;
          }

          entry.value['role_lawan'] = role;

          debugPrint(
            'Profil chat: ID=${entry.key}, '
            'nama=$username, role=$role',
          );
        } catch (e) {
          debugPrint(
            'Gagal mengambil profil ${entry.key}: $e',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _chatConversations = groupedChat.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat daftar percakapan: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat percakapan: $e'),
        ),
      );
    }
  }

  // Avatar menggunakan foto profil pemilik kost.
  // Jika foto tidak tersedia, tampilkan inisial nama.
  Widget _buildConversationAvatar(
    Map<String, dynamic> chat,
    String namaLawan,
  ) {
    final foto =
        chat['foto_lawan']?.toString().trim() ?? '';

    final bool hasPhoto =
        foto.startsWith('https://') ||
        foto.startsWith('http://');

    Widget fallbackAvatar() {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary,
        child: Text(
          namaLawan.isNotEmpty
              ? namaLawan[0].toUpperCase()
              : 'P',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (!hasPhoto) {
      return fallbackAvatar();
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primaryLight,
      child: ClipOval(
        child: Image.network(
          foto,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return fallbackAvatar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR — tampilan asli dipertahankan.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cari percakapan...',
                      style: TextStyle(
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FILTER TABS — tampilan asli dipertahankan.
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              children: [
                _buildFilterChip('Semua Chat', true),
                const SizedBox(width: 8),
                _buildFilterChip('Belum Dibaca', false),
                const SizedBox(width: 8),
                _buildFilterChip('Sudah Booking', false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // DAFTAR CHAT.
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _chatConversations.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: _chatConversations.length,
                        separatorBuilder: (context, index) =>
                            const Divider(
                          height: 0,
                          color: AppColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final chat =
                              _chatConversations[index];

                          final String namaLawan =
                              chat['nama_lawan']?.toString() ??
                                  'Pemilik Kost';

                          final String pesanTerakhir =
                              chat['pesan_terakhir']
                                      ?.toString() ??
                                  '';

                          final String waktuTerakhir =
                              chat['waktu']?.toString() ?? '';

                          final String idLawan =
                              chat['id_lawan']?.toString() ?? '';

                          final bool belumDibaca =
                              chat['belum_dibaca'] == true;

                          return ListTile(
                            tileColor: AppColors.white,

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RuangChatPage(
                                    idAdminTujuan: idLawan,
                                    namaAdmin: namaLawan,
                                  ),
                                ),
                              ).then((_) {
                                _fetchConversations();
                              });
                            },

                            leading: _buildConversationAvatar(
                              chat,
                              namaLawan,
                            ),

                            title: Text(
                              namaLawan,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),

                            subtitle: Text(
                              pesanTerakhir,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: belumDibaca
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: belumDibaca
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),

                            trailing: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  waktuTerakhir,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                  ),
                                ),
                                if (belumDibaca) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration:
                                        const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // TIPS KOMUNIKASI AMAN.
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
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
                    Icons.info_outline,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                        'Selalu lakukan transaksi dan konfirmasi '
                        'sewa melalui aplikasi KostRadar untuk '
                        'keamanan deposit dan garansi kamar Anda.',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppColors.textHint.withValues(
              alpha: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada percakapan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 40,
            ),
            child: Text(
              'Silakan cari kost yang Anda inginkan dan mulai '
              'mengobrol dengan pengelola kost.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColors.white
              : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }
}
