import 'package:flutter/material.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

class DaftarChatPage extends StatelessWidget {
  const DaftarChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Catatan: Nanti data list ini akan ditarik oleh backend/provider dari database Supabase
    final List<Map<String, String>> chatList = [
      {
        "name": "Admin Kost Bunga Dahlia",
        "lastMessage": "Baik kak, silakan datang untuk survei kamar.",
        "time": "12:30",
        "unread": "2",
      },
      {
        "name": "Pengelola Kost Mawar",
        "lastMessage": "Fasilitas AC dan WiFi sudah termasuk listrik ya.",
        "time": "Kemarin",
        "unread": "0",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pesan Masuk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary, // <-- DIUBAH
          ),
        ),
        backgroundColor: AppColors.white, // <-- DIUBAH
        foregroundColor: AppColors.textPrimary, // <-- DIUBAH
        elevation: 0.5,
      ),
      body: ListView.separated(
        itemCount: chatList.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: AppColors.border, // <-- DIUBAH (biar garis pembatas rapi)
        ),
        itemBuilder: (context, index) {
          final chat = chatList[index];
          int unreadCount = int.parse(chat["unread"]!);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.smallPadding, // <-- DIUBAH (16)
              vertical: AppSpacing.smallSpacing, // <-- DIUBAH (8)
            ),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors
                  .primaryLight, // <-- DIUBAH (pengganti blue.shade100)
              child: Text(
                chat["name"]![0],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary, // <-- DIUBAH (pengganti blueAccent)
                ),
              ),
            ),
            title: Text(
              chat["name"]!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary, // <-- DIUBAH
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                chat["lastMessage"]!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0
                      ? AppColors.textPrimary
                      : AppColors.textSecondary, // <-- DIUBAH
                  fontWeight: unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat["time"]!,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textHint, // <-- DIUBAH (pengganti grey[500])
                  ),
                ),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors
                          .primary, // <-- DIUBAH (pengganti blueAccent)
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chat["unread"]!,
                      style: const TextStyle(
                        color: AppColors.white, // <-- DIUBAH
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Navigasi ke ruang chat personal
              Navigator.pushNamed(context, '/ruang-chat');
            },
          );
        },
      ),
    );
  }
}
