//salsa
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_model.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fungsi mengambil pesan dari database
  Future<List<ChatModel>> getMessages(String receiverId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .or('receiver_id.eq.$receiverId,sender_id.eq.$receiverId')
        .order('created_at', ascending: true);

    return (response as List).map((data) => ChatModel.fromJson(data)).toList();
  }

  // Fungsi mengirim pesan baru ke database
  Future<void> sendMessage(String receiverId, String messageText) async {
    final currentUserId = _supabase.auth.currentUser!.id;
    await _supabase.from('messages').insert({
      'sender_id': currentUserId,
      'receiver_id': receiverId,
      'message': messageText,
    });
  }
}
