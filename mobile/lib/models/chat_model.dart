//salsa
class ChatModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;
  final bool isRead; // <-- Tambahan penanda status baca

  ChatModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  // Mengubah data JSON dari Supabase menjadi objek Dart
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id_message']?.toString() ?? json['id']?.toString() ?? '',
      senderId: json['pengirim_id']?.toString() ?? json['sender_id']?.toString() ?? '',
      receiverId: json['penerima_id']?.toString() ?? json['receiver_id']?.toString() ?? '',
      message: json['isi_pesan'] ?? json['message'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      isRead: json['is_read'] ?? false, // <-- Membaca status dari database
    );
  }
}