import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String idMessage;
  final String pengirimId;
  final String penerimaId;
  final String message; // Kita tetap pakai variabel lokal 'message' di Dart biar gak usah ubah UI lain
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
      idMessage: map['id_message']?.toString() ?? map['id']?.toString() ?? '',
      pengirimId: map['pengirim_id'] ?? '',
      penerimaId: map['penerima_id'] ?? '',
      message: map['isi_pesan'] ?? '', // <-- DIBAHAS DARI 'isi_pesan' DATABASE
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
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
        .order('created_at', ascending: true)
        .listen((List<Map<String, dynamic>> data) {
      
      // Filter pesan khusus antara Mahasiswa ini dan Admin Kost tersebut
      final filteredData = data.where((msg) {
        final isMeToThem = msg['pengirim_id'] == myUserId && msg['penerima_id'] == lawanBicaraId;
        final isThemToMe = msg['pengirim_id'] == lawanBicaraId && msg['penerima_id'] == myUserId;
        return isMeToThem || isThemToMe;
      }).toList();

      _messages = filteredData.map((e) => ChatMessage.fromMap(e)).toList();
      _isLoading = false;
      notifyListeners();
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
        'isi_pesan': teksPesan.trim(), // <-- DISAMAKAN DENGAN KOLOM 'isi_pesan' DI SUPABASE
      });
    } catch (e) {
      debugPrint("Gagal kirim pesan: $e");
    }
  }

  // FUNGSI 3: MENGHAPUS PESAN
  Future<void> deleteMessage(String messageId) async {
    try {
      // Coba hapus berdasarkan kolom id_message terlebih dahulu
      await _supabase
          .from('messages')
          .delete()
          .eq('id_message', messageId);
          
      _messages.removeWhere((msg) => msg.idMessage == messageId);
      notifyListeners();
    } catch (e) {
      // Fallback: Jika tabel Supabase menggunakan primary key 'id'
      try {
        await _supabase
            .from('messages')
            .delete()
            .eq('id', messageId);
            
        _messages.removeWhere((msg) => msg.idMessage == messageId);
        notifyListeners();
      } catch (innerError) {
        debugPrint("Gagal menghapus pesan: $innerError");
      }
    }
  }
}