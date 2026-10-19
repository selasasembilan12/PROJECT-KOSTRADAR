
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_model.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mengambil semua pesan yang melibatkan pengguna tertentu.
  Future<List<ChatModel>> getMessages(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID tidak boleh kosong.');
    }

    final response = await _supabase
        .from('messages')
        .select()
        .or(
          'penerima_id.eq.$userId,pengirim_id.eq.$userId',
        )
        .order('created_at', ascending: true);

    return (response as List)
        .map(
          (data) => ChatModel.fromJson(
            Map<String, dynamic>.from(data),
          ),
        )
        .toList();
  }

  /// Mengambil pesan dua arah antara pengguna yang login
  /// dan pengguna lain.
  Future<List<ChatModel>> getConversationMessages(
    String otherUserId,
  ) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw StateError('Pengguna belum login.');
    }

    if (otherUserId.trim().isEmpty) {
      throw ArgumentError('ID lawan bicara tidak boleh kosong.');
    }

    if (currentUser.id == otherUserId) {
      throw ArgumentError(
        'ID lawan bicara tidak boleh sama dengan ID pengguna.',
      );
    }

    final currentUserId = currentUser.id;

    final response = await _supabase
        .from('messages')
        .select()
        .or(
          'and(pengirim_id.eq.$currentUserId,penerima_id.eq.$otherUserId),'
          'and(pengirim_id.eq.$otherUserId,penerima_id.eq.$currentUserId)',
        )
        .order('created_at', ascending: true);

    return (response as List)
        .map(
          (data) => ChatModel.fromJson(
            Map<String, dynamic>.from(data),
          ),
        )
        .toList();
  }

  /// Mengirim pesan kepada pengguna lain.
  /// idKost bersifat opsional agar pemanggilan lama tetap kompatibel.
  Future<void> sendMessage(
    String receiverId,
    String messageText, {
    String? idKost,
  }) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw StateError(
        'Pengguna belum login. Pesan tidak dapat dikirim.',
      );
    }

    if (receiverId.trim().isEmpty) {
      throw ArgumentError('ID penerima tidak boleh kosong.');
    }

    if (currentUser.id == receiverId) {
      throw ArgumentError(
        'ID pengirim dan penerima tidak boleh sama.',
      );
    }

    final trimmedMessage = messageText.trim();

    if (trimmedMessage.isEmpty) {
      throw ArgumentError('Pesan tidak boleh kosong.');
    }

    final dataPesan = <String, dynamic>{
      'pengirim_id': currentUser.id,
      'penerima_id': receiverId,
      'isi_pesan': trimmedMessage,
    };

    if (idKost != null && idKost.trim().isNotEmpty) {
      dataPesan['id_kost'] = idKost;
    }

    await _supabase.from('messages').insert(dataPesan);
  }
}
