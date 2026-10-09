//R
import 'package:flutter/material.dart';
import 'profil_admin_page.dart';

const Color warnaBiru = Color(0xFF2563EB);
const Color warnaLatar = Color(0xFFF7F8FC);
const Color warnaTeks = Color(0xFF172033);
const Color warnaSekunder = Color(0xFF64748B);

String formatWaktu(DateTime waktu) {
  return '${waktu.hour.toString().padLeft(2, '0')}.'
      '${waktu.minute.toString().padLeft(2, '0')}';
}

class ChatAdmin {
  ChatAdmin({
    required this.nama,
    required this.kost,
    required this.kamar,
    required this.pesan,
    required this.waktu,
    this.belumDibaca = false,
  });

  final String nama;
  final String kost;
  final String kamar;
  String pesan;
  DateTime waktu;
  bool belumDibaca;
}

class PesanChat {
  PesanChat({
    required this.isi,
    required this.waktu,
    required this.dariAdmin,
  });

  final String isi;
  final DateTime waktu;
  final bool dariAdmin;
}

final List<ChatAdmin> dataContohChat = [
  ChatAdmin(
    nama: 'Alya Putri',
    kost: 'Kost Adawarna',
    kamar: 'Kamar 04',
    pesan: 'Apakah kamar masih tersedia?',
    waktu: DateTime.now(),
    belumDibaca: true,
  ),
  ChatAdmin(
    nama: 'Budi Santoso',
    kost: 'Kost Melati',
    kamar: 'Kamar 12',
    pesan: 'Terima kasih informasinya, Pak.',
    waktu: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  ChatAdmin(
    nama: 'Siti Rahma',
    kost: 'Kost Ceria',
    kamar: 'Kamar 02',
    pesan: 'Apakah bisa jadwal survei hari Sabtu?',
    waktu: DateTime.now().subtract(const Duration(days: 1)),
    belumDibaca: true,
  ),
  ChatAdmin(
    nama: 'Dimas Pratama',
    kost: 'Kost Adawarna',
    kamar: 'Kamar 08',
    pesan: 'Bukti transfer deposit sudah dikirim.',
    waktu: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

class DaftarChatAdminPage extends StatefulWidget {
  const DaftarChatAdminPage({super.key});

  @override
  State<DaftarChatAdminPage> createState() =>
      _DaftarChatAdminPageState();
}

class _DaftarChatAdminPageState
    extends State<DaftarChatAdminPage> {
  int selectedTab = 0;
  bool isSearching = false;

  final TextEditingController searchController =
      TextEditingController();

  String searchQuery = '';

  List<ChatAdmin> get filteredChats {
    return dataContohChat.where((chat) {
      final cocokTab =
          selectedTab == 0 || chat.belumDibaca;

      final query = searchQuery.toLowerCase();

      final cocokPencarian =
          chat.nama.toLowerCase().contains(query) ||
          chat.kost.toLowerCase().contains(query) ||
          chat.pesan.toLowerCase().contains(query);

      return cocokTab && cocokPencarian;
    }).toList()
      ..sort((a, b) => b.waktu.compareTo(a.waktu));
  }

  void bukaProfil() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const ProfilAdminPage(),
      ),
    );
  }

  void kirimBalasanCepat(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Balasan cepat: $pesan'),
        action: SnackBarAction(
          label: 'Pilih chat',
          onPressed: () {
            if (filteredChats.isNotEmpty) {
              bukaDetail(filteredChats.first);
            }
          },
        ),
      ),
    );
  }

  void bukaDetail(ChatAdmin chat) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetailChatAdminPage(chat: chat),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chats = filteredChats;

    return Scaffold(
      backgroundColor: warnaLatar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: warnaBiru,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KOSTRADAR ADMIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: warnaTeks,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Pesan Masuk',
                              style: TextStyle(
                                fontSize: 12,
                                color: warnaSekunder,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cari chat',
                        onPressed: () {
                          setState(() {
                            isSearching = !isSearching;
                            if (!isSearching) {
                              searchController.clear();
                              searchQuery = '';
                            }
                          });
                        },
                        icon: Icon(
                          isSearching ? Icons.close : Icons.search,
                          color: warnaTeks,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: warnaTeks,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kelola pertanyaan calon penyewa kost Anda',
                    style: TextStyle(
                      fontSize: 13,
                      color: warnaSekunder,
                    ),
                  ),
                  if (isSearching) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama, kost, atau pesan...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _tabButton('Semua', 0),
                      const SizedBox(width: 10),
                      _tabButton('Belum dibaca', 1),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: chats.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_outlined,
                            size: 52,
                            color: warnaSekunder,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada pesan ditemukan',
                            style: TextStyle(color: warnaSekunder),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: chats.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final chat = chats[index];

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => bukaDetail(chat),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor:
                                        warnaBiru.withValues(alpha: 0.10),
                                    child: Text(
                                      chat.nama.isNotEmpty
                                          ? chat.nama[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: warnaBiru,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
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
                                                chat.nama,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: warnaTeks,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              formatWaktu(chat.waktu),
                                              style: const TextStyle(
                                                color: warnaSekunder,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${chat.kost} • ${chat.kamar}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: warnaBiru,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          chat.pesan,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: chat.belumDibaca
                                                ? warnaTeks
                                                : warnaSekunder,
                                            fontWeight: chat.belumDibaca
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (chat.belumDibaca) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: warnaBiru,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: warnaBiru,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balasan Cepat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: warnaTeks,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Gunakan jawaban praktis untuk calon penyewa',
                          style: TextStyle(
                            fontSize: 11,
                            color: warnaSekunder,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Pilih balasan',
                    icon: const Icon(
                      Icons.add_circle,
                      color: warnaBiru,
                      size: 28,
                    ),
                    onSelected: kirimBalasanCepat,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value:
                            'Terima kasih sudah menghubungi kami. '
                            'Silakan informasikan kebutuhan Anda.',
                        child: Text('Sapaan awal'),
                      ),
                      PopupMenuItem(
                        value:
                            'Silakan tentukan jadwal survei yang '
                            'sesuai, nanti kami konfirmasi.',
                        child: Text('Jadwal survei'),
                      ),
                      PopupMenuItem(
                        value:
                            'Untuk informasi harga dan ketersediaan, '
                            'silakan sebutkan kamar yang diminati.',
                        child: Text('Harga dan ketersediaan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: warnaBiru,
        unselectedItemColor: warnaSekunder,
        backgroundColor: Colors.white,
        onTap: (index) {
          if (index == 3) {
            bukaProfil();
          } else if (index != 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Halaman ini dikelola oleh bagian aplikasi lainnya.',
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            label: 'Kost',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final aktif = selectedTab == index;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: aktif ? warnaBiru : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: aktif ? warnaBiru : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: aktif ? Colors.white : warnaSekunder,
          ),
        ),
      ),
    );
  }
}

class DetailChatAdminPage extends StatefulWidget {
  const DetailChatAdminPage({
    super.key,
    required this.chat,
  });

  final ChatAdmin chat;

  @override
  State<DetailChatAdminPage> createState() =>
      _DetailChatAdminPageState();
}

class _DetailChatAdminPageState
    extends State<DetailChatAdminPage> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  late final List<PesanChat> messages;

  @override
  void initState() {
    super.initState();

    widget.chat.belumDibaca = false;

    messages = [
      PesanChat(
        isi: widget.chat.pesan,
        waktu: widget.chat.waktu,
        dariAdmin: false,
      ),
    ];
  }

  void _kirimPesan() {
    final isi = _messageController.text.trim();
    if (isi.isEmpty) return;

    setState(() {
      messages.add(
        PesanChat(
          isi: isi,
          waktu: DateTime.now(),
          dariAdmin: true,
        ),
      );

      widget.chat.pesan = isi;
      widget.chat.waktu = DateTime.now();
    });

    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
      backgroundColor: warnaLatar,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: warnaTeks),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: warnaBiru.withValues(alpha: 0.10),
              child: Text(
                widget.chat.nama.isNotEmpty
                    ? widget.chat.nama[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: warnaBiru,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: warnaTeks,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.chat.kost} • ${widget.chat.kamar}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: warnaSekunder,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFEAF1FF),
            child: const Text(
              'Percakapan dengan calon penyewa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: warnaBiru,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final pesan = messages[index];

                return Align(
                  alignment: pesan.dariAdmin
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: pesan.dariAdmin
                          ? warnaBiru
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(
                          pesan.dariAdmin ? 16 : 4,
                        ),
                        bottomRight: Radius.circular(
                          pesan.dariAdmin ? 4 : 16,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          pesan.isi,
                          style: TextStyle(
                            color: pesan.dariAdmin
                                ? Colors.white
                                : warnaTeks,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          formatWaktu(pesan.waktu),
                          style: TextStyle(
                            fontSize: 10,
                            color: pesan.dariAdmin
                                ? Colors.white70
                                : warnaSekunder,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization:
                          TextCapitalization.sentences,
                      onSubmitted: (_) => _kirimPesan(),
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        filled: true,
                        fillColor: warnaLatar,
                        contentPadding:
                            const EdgeInsets.symmetric(
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
                  IconButton(
                    onPressed: _kirimPesan,
                    style: IconButton.styleFrom(
                      backgroundColor: warnaBiru,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(13),
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}