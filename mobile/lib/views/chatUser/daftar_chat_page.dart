import 'package:flutter/material.dart';
// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';
// Import file ruang chat karena bakal dibutuhin buat testing ntar
import 'ruang_chat_page.dart'; 

class DaftarChatPage extends StatelessWidget {
  const DaftarChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // KITA BUAT DATANYA KOSONG (Simulasi saat user baru pertama kali pakai aplikasi)
    final List<Map<String, dynamic>> chatList = [];

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
          // SEARCH BAR (Dibiarkan sesuai desain asli)
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
          
          // FILTER TABS (Dibiarkan sesuai desain asli)
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
          
          // AREA DAFTAR CHAT
          Expanded(
            child: chatList.isEmpty
                ? _buildEmptyState() // Jika data kosong, tampilkan ini
                : ListView.separated(
                    itemCount: chatList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 0, color: AppColors.border),
                    itemBuilder: (context, index) {
                      // Ini ga akan dieksekusi selama chatList kosong, 
                      // tapi tetep gw biarin strukturnya buat ntar kalau udah disambung ke DB
                      return const SizedBox(); 
                    },
                  ),
          ),
          
          // TIPS KOMUNIKASI AMAN (Dibiarkan sesuai desain asli)
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

  // WIDGET KETIKA DATA KOSONG (EMPTY STATE)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
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
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Silakan cari kost yang Anda inginkan dan mulai mengobrol dengan pengelola kost.',
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