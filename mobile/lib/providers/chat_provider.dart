import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String idMessage;
  final String pengirimId;
  final String penerimaId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.idMessage,
    required this.pengirimId,
    required this.penerimaId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      idMessage: map['id_message'] ?? '',
      pengirimId: map['pengirim_id'] ?? '',
      penerimaId: map['penerima_id'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // FUNGSI 1: MEMBUKA JALUR REALTIME
  void listenToMessages(String lawanBicaraId) {
    final myUserId = _supabase.auth.currentUser?.id;
    if (myUserId == null) return;

    // Supabase Stream akan otomatis menarik data setiap ada pesan baru
    _supabase
        .from('messages')
        .stream(primaryKey: ['id_message'])
        .order('created_at', ascending: true) // Urutkan dari pesan terlama ke terbaru
        .listen((List<Map<String, dynamic>> data) {
          
      // Filter pesan khusus antara Mahasiswa ini dan Admin Kost tersebut
      final filteredData = data.where((msg) {
        final isMeToThem = msg['pengirim_id'] == myUserId && msg['penerima_id'] == lawanBicaraId;
        final isThemToMe = msg['pengirim_id'] == lawanBicaraId && msg['penerima_id'] == myUserId;
        return isMeToThem || isThemToMe;
      }).toList();

      _messages = filteredData.map((e) => ChatMessage.fromMap(e)).toList();
      _isLoading = false;
      notifyListeners(); // Kasih tau UI (ruang_chat_page) buat update layar
    });
  }

  // FUNGSI 2: MENGIRIM PESAN
  Future<void> sendNewMessage(String lawanBicaraId, String teksPesan) async {
    final myUserId = _supabase.auth.currentUser?.id;
    if (myUserId == null || teksPesan.trim().isEmpty) return;

    try {
      await _supabase.from('messages').insert({
        'pengirim_id': myUserId,
        'penerima_id': lawanBicaraId,
        'message': teksPesan.trim(),
      });
      // Nggak perlu tambah ke _messages manual, karena .stream() di atas akan otomatis nangkep!
    } catch (e) {
      debugPrint("Gagal kirim pesan: $e");
    }
  }
}