import 'package:flutter/material.dart';

class DaftarChatAdminPage extends StatefulWidget {
  const DaftarChatAdminPage({super.key});

  @override
  State<DaftarChatAdminPage> createState() =>
      _DaftarChatAdminPageState();
}

class _DaftarChatAdminPageState extends State<DaftarChatAdminPage> {
  final TextEditingController searchController = TextEditingController();

  // ============================================================
  // DATA SEMENTARA
  // Struktur field dibuat mengikuti tabel messages + users.
  // Nanti saat Supabase/API masuk, bagian ini yang diganti.
  // ============================================================

  final List<Map<String, dynamic>> chats = [
    {
      'id_message': 'message-001',
      'pengirim_id': 'user-001',
      'penerima_id': 'admin-001',
      'id_kost': 'kost-001',
      'isi_pesan': 'Apakah kamar masih tersedia?',
      'created_at': '2026-10-09T10:30:00',
      'username': 'Alya Putri',
      'email': 'alya@gmail.com',
      'foto_profile': '',
      'is_unread': true,
    },
    {
      'id_message': 'message-002',
      'pengirim_id': 'admin-001',
      'penerima_id': 'user-002',
      'id_kost': 'kost-001',
      'isi_pesan': 'Terima kasih informasinya Pak, besok saya...',
      'created_at': '2026-10-08T14:20:00',
      'username': 'Budi Santoso',
      'email': 'budi@gmail.com',
      'foto_profile': '',
      'is_unread': false,
    },
    {
      'id_message': 'message-003',
      'pengirim_id': 'user-003',
      'penerima_id': 'admin-001',
      'id_kost': 'kost-001',
      'isi_pesan': 'Apakah bisa jadwal survey hari Sabtu ini?',
      'created_at': '2026-09-12T09:15:00',
      'username': 'Siti Rahma',
      'email': 'siti@gmail.com',
      'foto_profile': '',
      'is_unread': true,
    },
    {
      'id_message': 'message-004',
      'pengirim_id': 'admin-001',
      'penerima_id': 'user-004',
      'id_kost': 'kost-001',
      'isi_pesan': 'Bukti transfer deposit sudah dikirim ya Pak.',
      'created_at': '2026-09-08T16:40:00',
      'username': 'Dimas Pratama',
      'email': 'dimas@gmail.com',
      'foto_profile': '',
      'is_unread': false,
    },
  ];

  int selectedTab = 0;
  bool isSearching = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER DATA
  // ============================================================

  List<Map<String, dynamic>> get filteredChats {
    List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.from(chats);

    // Tab "Belum"
    if (selectedTab == 1) {
      result = result
          .where((chat) => chat['is_unread'] == true)
          .toList();
    }

    // Search
    final query = searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((chat) {
        final username =
            chat['username'].toString().toLowerCase();

        final message =
            chat['isi_pesan'].toString().toLowerCase();

        final email =
            chat['email'].toString().toLowerCase();

        return username.contains(query) ||
            message.contains(query) ||
            email.contains(query);
      }).toList();
    }

    return result;
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String formatTime(String value) {
    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();

      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}';
      }

      if (difference.inDays == 1) {
        return 'Kemarin';
      }

      return '${date.day.toString().padLeft(2, '0')} '
          '${_monthName(date.month)}';
    } catch (_) {
      return '';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return months[month - 1];
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        chats.where((chat) => chat['is_unread'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KOSTRADAR ADMIN',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF8A8A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Chat',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isSearching = !isSearching;

                if (!isSearching) {
                  searchController.clear();
                }
              });
            },
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: Colors.black87,
            ),
          ),

          IconButton(
            onPressed: _showFilter,
            icon: const Icon(
              Icons.tune,
              color: Colors.black87,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // ====================================================
          // HEADER PESAN MASUK
          // ====================================================

          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              14,
            ),
            child: isSearching
                ? TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau pesan...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesan Masuk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kelola pertanyaan calon penyewa kost Anda',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
          ),

          // ====================================================
          // TAB
          // ====================================================

          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Row(
              children: [
                _buildTab(
                  title: 'Semua',
                  index: 0,
                  count: chats.length,
                ),
                const SizedBox(width: 8),
                _buildTab(
                  title: 'Belum',
                  index: 1,
                  count: unreadCount,
                ),
              ],
            ),
          ),

          // ====================================================
          // DAFTAR CHAT
          // ====================================================

          Expanded(
            child: filteredChats.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      8,
                    ),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      return _buildChatItem(
                        filteredChats[index],
                      );
                    },
                  ),
          ),

          // ====================================================
          // RESPONSE CEPAT
          // ====================================================

          _buildQuickResponse(),
        ],
      ),
    );
  }

  // ============================================================
  // TAB SEMUA / BELUM
  // ============================================================

  Widget _buildTab({
    required String title,
    required int index,
    required int count,
  }) {
    final isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F0FE)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.blue
                    : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.blue
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ITEM CHAT
  // ============================================================

  Widget _buildChatItem(
    Map<String, dynamic> chat,
  ) {
    final isUnread = chat['is_unread'] == true;

    final username =
        chat['username'].toString();

    final message =
        chat['isi_pesan'].toString();

    final photo =
        chat['foto_profile'].toString();

    return InkWell(
      onTap: () {
        setState(() {
          chat['is_unread'] = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminChatDetailPage(
              chatData: chat,
            ),
          ),
        );
      },

      borderRadius: BorderRadius.circular(14),

      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),

        child: Row(
          children: [
            _buildAvatar(
              username: username,
              photo: photo,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          username,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                      ),

                      Text(
                        formatTime(
                          chat['created_at'].toString(),
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUnread
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUnread
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                  ),

                  if (isUnread) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Pesan baru',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar({
    required String username,
    required String photo,
  }) {
    if (photo.isNotEmpty && photo != 'null') {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(photo),
      );
    }

    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.grey.shade200,
      child: Text(
        username.isNotEmpty
            ? username[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final searching =
        searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searching
                  ? Icons.search_off
                  : Icons.chat_bubble_outline,
              size: 60,
              color: Colors.grey,
            ),

            const SizedBox(height: 12),

            Text(
              searching
                  ? 'Pesan tidak ditemukan'
                  : 'Belum ada pesan',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              searching
                  ? 'Coba gunakan kata pencarian lain.'
                  : 'Pesan dari calon penyewa akan muncul di sini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESPONSE CEPAT
  // ============================================================

  Widget _buildQuickResponse() {
    return InkWell(
      onTap: _showQuickResponse,
      borderRadius: BorderRadius.circular(12),

      child: Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          8,
        ),
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
        ),

        child: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.bolt,
                color: Colors.white,
                size: 18,
              ),
            ),

            SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Response Cepat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Gunakan template untuk membalas pesan lebih cepat.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Filter Pesan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(
                  Icons.all_inbox_outlined,
                ),
                title: const Text(
                  'Semua Pesan',
                ),
                trailing: selectedTab == 0
                    ? const Icon(
                        Icons.check,
                        color: Colors.blue,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    selectedTab = 0;
                  });

                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.mark_email_unread_outlined,
                ),
                title: const Text(
                  'Belum Dibaca',
                ),
                trailing: selectedTab == 1
                    ? const Icon(
                        Icons.check,
                        color: Colors.blue,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    selectedTab = 1;
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // RESPONSE CEPAT
  // ============================================================

  void _showQuickResponse() {
    final responses = [
      {
        'title': 'Kamar Masih Tersedia',
        'message':
            'Halo Kak, kamar yang ditanyakan saat ini masih tersedia.',
      },
      {
        'title': 'Kost Penuh',
        'message':
            'Mohon maaf Kak, kamar yang ditanyakan saat ini sudah penuh.',
      },
      {
        'title': 'Jadwal Survey',
        'message':
            'Halo Kak, silakan pilih waktu yang tersedia untuk jadwal survey.',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Response Cepat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Pilih template jawaban yang sering digunakan.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 12),

              ...responses.map(
                (response) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,

                    leading: const CircleAvatar(
                      backgroundColor:
                          Color(0xFFE8F0FE),
                      child: Icon(
                        Icons.bolt,
                        color: Colors.blue,
                      ),
                    ),

                    title: Text(
                      response['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    subtitle: Text(
                      response['message']!,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                      ),
                    ),

                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),

                    onTap: () {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Template "${response['title']}" dipilih.',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================================================================
// HALAMAN DETAIL CHAT
// ==================================================================
//
// Masih berada di file yang sama supaya kita tidak menambah file
// ketiga. Nanti kalau temanmu sudah mempunyai halaman ruang chat,
// bagian ini bisa diganti dengan halaman milik mereka.
// ==================================================================

class AdminChatDetailPage extends StatefulWidget {
  final Map<String, dynamic> chatData;

  const AdminChatDetailPage({
    super.key,
    required this.chatData,
  });

  @override
  State<AdminChatDetailPage> createState() =>
      _AdminChatDetailPageState();
}

class _AdminChatDetailPageState
    extends State<AdminChatDetailPage> {
  final TextEditingController messageController =
      TextEditingController();

  late List<Map<String, dynamic>> messages;

  @override
  void initState() {
    super.initState();

    messages = [
      {
        'id_message': widget.chatData['id_message'],
        'pengirim_id': widget.chatData['pengirim_id'],
        'penerima_id': widget.chatData['penerima_id'],
        'id_kost': widget.chatData['id_kost'],
        'isi_pesan': widget.chatData['isi_pesan'],
        'created_at': widget.chatData['created_at'],
      },
    ];
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // KIRIM PESAN LOKAL
  // ============================================================

  void _sendMessage() {
    final text =
        messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      messages.add({
        'id_message':
            'local-${DateTime.now().millisecondsSinceEpoch}',
        'pengirim_id': 'admin-001',
        'penerima_id':
            widget.chatData['pengirim_id'],
        'id_kost':
            widget.chatData['id_kost'],
        'isi_pesan': text,
        'created_at':
            DateTime.now().toIso8601String(),
      });
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final username =
        widget.chatData['username'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  Colors.grey.shade200,
              child: Text(
                username.isNotEmpty
                    ? username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Text(
              username,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                final isAdmin =
                    message['pengirim_id'] ==
                        'admin-001';

                return _buildMessageBubble(
                  message,
                  isAdmin,
                );
              },
            ),
          ),

          _buildMessageInput(),
        ],
      ),
    );
  }

  // ============================================================
  // BUBBLE PESAN
  // ============================================================

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isAdmin,
  ) {
    return Align(
      alignment: isAdmin
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 290,
        ),

        margin: const EdgeInsets.only(
          bottom: 8,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: isAdmin
              ? Colors.blue
              : Colors.white,

          borderRadius:
              BorderRadius.circular(16),
        ),

        child: Text(
          message['isi_pesan'].toString(),

          style: TextStyle(
            fontSize: 13,
            color: isAdmin
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,

      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12,
      ),

      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,

              textInputAction:
                  TextInputAction.send,

              onSubmitted: (_) {
                _sendMessage();
              },

              decoration: InputDecoration(
                hintText: 'Tulis pesan...',
                filled: true,
                fillColor:
                    const Color(0xFFF5F6F8),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),

                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          CircleAvatar(
            backgroundColor: Colors.blue,

            child: IconButton(
              onPressed: _sendMessage,

              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}