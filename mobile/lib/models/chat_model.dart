//salsa
class ChatModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });

  // Mengubah data JSON dari Supabase menjadi objek Dart
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'].toString(),
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
