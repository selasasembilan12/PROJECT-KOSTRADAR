import 'package:flutter/material.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

class DaftarChatPage extends StatelessWidget {
  const DaftarChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy yang lebih lengkap
    final List<Map<String, dynamic>> chatList = [
      {
        "name": "Kost Adiwarna",
        "address": "Jl. Gegerkalong Hilir",
        "lastMessage": "Halo, apakah kamar masih tersedia?",
        "time": "10.30",
        "unread": 2,
        "image": "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=100",
      },
      {
        "name": "Kost Melati",
        "address": "Jl. Jati Metro No. 45",
        "lastMessage": "Baik, terima kasih informasinya",
        "time": "Kemarin",
        "unread": 0,
        "image": "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=100",
      },
      {
        "name": "Kost Cemara",
        "address": "Jl. Jati Perumnas No. 8",
        "lastMessage": "Apakah bisa survey terlebih dahulu?",
        "time": "12 Sep",
        "unread": 0,
        "image": "https://images.unsplash.com/photo-1596276020587-8044fe049813?w=100",
      },
      {
        "name": "Kost Bukit Indah",
        "address": "Jl. Bukit Indah Raya",
        "lastMessage": "Kunci kamar siap diambil hari Senin",
        "time": "08 Sep",
        "unread": 1,
        "image":
            "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=100",
      },
    ];

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
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cari percakapan...',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FILTER TABS
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

          // CHAT LIST
          Expanded(
            child: ListView.separated(
              itemCount: chatList.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 0, color: AppColors.border),
              itemBuilder: (context, index) {
                final chat = chatList[index];
                final hasUnread = chat['unread'] > 0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(chat['image']),
                    backgroundColor: AppColors.primaryLight,
                    child: chat['image'].isEmpty
                        ? Text(
                            chat["name"][0],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat["name"],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        chat["time"],
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat["lastMessage"],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              chat["unread"].toString(),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/ruang-chat');
                  },
                );
              },
            ),
          ),

          // TIPS KOMUNIKASI AMAN
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
                        'Selalu lakukan transaksi dan konfirmasi sewa melalui aplikasi KostRadar untuk keamanan deposit dan garansi kamar Anda.',
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
