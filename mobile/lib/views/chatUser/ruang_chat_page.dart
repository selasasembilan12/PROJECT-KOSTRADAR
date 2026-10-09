import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

import '../../providers/chat_provider.dart';

class RuangChatPage extends StatefulWidget {
  const RuangChatPage({super.key});

  @override
  State<RuangChatPage> createState() => _RuangChatPageState();
}

class _RuangChatPageState extends State<RuangChatPage> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    // Perintah Provider untuk mengirim pesan langsung dipanggil di sini
    // Ganti 'id_admin_tujuan' dengan UUID / ID admin dari database Supabase nanti
    Provider.of<ChatProvider>(
      context,
      listen: false,
    ).sendNewMessage('id_admin_tujuan', _messageController.text.trim());

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer agar tampilan ikut memperbarui pesan secara real-time dari provider
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  AppColors.primary, // <-- DIUBAH (pengganti blueAccent)
              child: Text(
                'A',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                ), // <-- DIUBAH
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Kost Adiwarna',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ), // <-- DIUBAH
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ), // <-- DIUBAH (pengganti greenAccent)
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.white, // <-- DIUBAH
        foregroundColor: AppColors.textPrimary, // <-- DIUBAH
        elevation: 0.5,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final messages = chatProvider.messages;

          return Column(
            children: [
              Expanded(
                child: chatProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ) // <-- DIUBAH
                    : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada riwayat percakapan.\nKirim pesan untuk mulai terhubung dengan pengelola!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors
                                .textSecondary, // <-- DIUBAH (pengganti grey)
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          // Tentukan apakah pesan ini dikirim oleh user yang sedang login
                          bool isMe = msg.senderId != 'id_admin_tujuan';

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors
                                          .primary // <-- DIUBAH (pengganti blueAccent)
                                    : AppColors.backgroundLight, // <-- DIUBAH (pengganti grey[200])
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    msg.message,
                                    style: TextStyle(
                                      color: isMe
                                          ? AppColors
                                                .white // <-- DIUBAH
                                          : AppColors.textPrimary, // <-- DIUBAH (pengganti black87)
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: isMe
                                          ? AppColors.white.withOpacity(
                                              0.7,
                                            ) // <-- DIUBAH (pengganti white70)
                                          : AppColors.textHint, // <-- DIUBAH (pengganti black54)
                                      fontSize: 10,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: AppColors.white, // <-- DIUBAH
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Tulis pesan...',
                          hintStyle: const TextStyle(
                            color: AppColors.textHint,
                          ), // <-- DIUBAH
                          filled: true,
                          fillColor: AppColors.backgroundLight, // <-- DIUBAH (pengganti grey[100])
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
                      backgroundColor: AppColors
                          .primary, // <-- DIUBAH (pengganti blueAccent)
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.white, // <-- DIUBAH
                          size: 18,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
