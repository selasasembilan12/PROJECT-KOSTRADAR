
import 'dart:async';

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
      idMessage: map['id_message']?.toString() ?? '',
      pengirimId: map['pengirim_id']?.toString() ?? '',
      penerimaId: map['penerima_id']?.toString() ?? '',
      message: (map['isi_pesan'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

class ChatConversation {
  final String lawanBicaraId;
  final String pesanTerakhir;
  final DateTime waktuTerakhir;

  ChatConversation({
    required this.lawanBicaraId,
    required this.pesanTerakhir,
    required this.waktuTerakhir,
  });
}

class ChatProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  List<ChatConversation> _conversations = [];
  List<ChatConversation> get conversations => _conversations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<Map<String, dynamic>>>?
      _messagesSubscription;

  StreamSubscription<List<Map<String, dynamic>>>?
      _conversationsSubscription;

  bool _disposed = false;

  void _notifySafely() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Membentuk daftar percakapan dari pesan yang melibatkan pengguna.
  List<ChatConversation> _buildConversations(
    List<Map<String, dynamic>> rows,
    String myUserId,
  ) {
    final Map<String, ChatConversation> conversationMap = {};
    final sortedRows = [...rows];

    sortedRows.sort((a, b) {
      final dateA = DateTime.tryParse(
            a['created_at']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final dateB = DateTime.tryParse(
            b['created_at']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return dateB.compareTo(dateA);
    });

    for (final row in sortedRows) {
      final pengirim = row['pengirim_id']?.toString() ?? '';
      final penerima = row['penerima_id']?.toString() ?? '';

      if (pengirim.isEmpty || penerima.isEmpty) continue;

      final lawanBicaraId =
          pengirim == myUserId ? penerima : pengirim;

      // Pesan yang dikirim ke diri sendiri bukan percakapan valid.
      if (lawanBicaraId == myUserId ||
          conversationMap.containsKey(lawanBicaraId)) {
        continue;
      }

      conversationMap[lawanBicaraId] = ChatConversation(
        lawanBicaraId: lawanBicaraId,
        pesanTerakhir: (row['isi_pesan'] ?? '').toString(),
        waktuTerakhir:
            DateTime.tryParse(
              row['created_at']?.toString() ?? '',
            ) ??
            DateTime.now(),
      );
    }

    return conversationMap.values.toList();
  }

  // Mengambil daftar percakapan untuk akun yang sedang login.
  Future<void> fetchConversations() async {
    final myUserId = _supabase.auth.currentUser?.id;

    if (myUserId == null) {
      _conversations = [];
      _isLoading = false;
      _notifySafely();
      return;
    }

    _isLoading = true;
    _notifySafely();

    try {
      final response = await _supabase
          .from('messages')
          .select()
          .or(
            'pengirim_id.eq.$myUserId,'
            'penerima_id.eq.$myUserId',
          )
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(response);

      _conversations = _buildConversations(rows, myUserId);
    } catch (e, stackTrace) {
      debugPrint('Gagal mengambil daftar percakapan: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  // Memantau daftar percakapan secara realtime.
  void listenToConversations() {
    final myUserId = _supabase.auth.currentUser?.id;

    if (myUserId == null) {
      debugPrint('Tidak dapat memantau chat: pengguna belum login.');
      return;
    }

    _conversationsSubscription?.cancel();

    _conversationsSubscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id_message'])
        .order('created_at', ascending: false)
        .listen(
      (rows) {
        if (_disposed) return;

        final relevantRows = rows.where((row) {
          return row['pengirim_id']?.toString() == myUserId ||
              row['penerima_id']?.toString() == myUserId;
        }).toList();

        _conversations = _buildConversations(
          relevantRows,
          myUserId,
        );

        _isLoading = false;
        _notifySafely();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Realtime daftar percakapan gagal: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  // Memantau pesan dua arah antara pengguna login dan lawan bicara.
  void listenToMessages(String lawanBicaraId) {
    final myUserId = _supabase.auth.currentUser?.id;

    if (myUserId == null || lawanBicaraId.trim().isEmpty) {
      return;
    }

    _messagesSubscription?.cancel();

    _messages = [];
    _isLoading = true;
    _notifySafely();

    _messagesSubscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id_message'])
        .order('created_at', ascending: true)
        .listen(
      (rows) {
        if (_disposed) return;

        final filteredRows = rows.where((row) {
          final pengirim = row['pengirim_id']?.toString();
          final penerima = row['penerima_id']?.toString();

          return (pengirim == myUserId &&
                  penerima == lawanBicaraId) ||
              (pengirim == lawanBicaraId &&
                  penerima == myUserId);
        }).toList();

        _messages = filteredRows
            .map((row) => ChatMessage.fromMap(row))
            .toList();

        _isLoading = false;
        _notifySafely();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Realtime pesan gagal: $error');
        debugPrintStack(stackTrace: stackTrace);

        if (!_disposed) {
          _isLoading = false;
          _notifySafely();
        }
      },
    );
  }

  // Mengirim pesan kepada lawan bicara.
  Future<void> sendNewMessage(
    String lawanBicaraId,
    String teksPesan, {
    String? idKost,
  }) async {
    final myUserId = _supabase.auth.currentUser?.id;
    final pesan = teksPesan.trim();

    if (myUserId == null) {
      throw StateError('Pengguna belum login.');
    }

    if (lawanBicaraId.trim().isEmpty) {
      throw ArgumentError('ID penerima tidak boleh kosong.');
    }

    if (myUserId == lawanBicaraId) {
      throw ArgumentError(
        'ID pengirim dan penerima tidak boleh sama.',
      );
    }

    if (pesan.isEmpty) {
      throw ArgumentError('Pesan tidak boleh kosong.');
    }

    final dataPesan = <String, dynamic>{
      'pengirim_id': myUserId,
      'penerima_id': lawanBicaraId,
      'isi_pesan': pesan,
    };

    if (idKost != null && idKost.trim().isNotEmpty) {
      dataPesan['id_kost'] = idKost;
    }

    try {
      await _supabase.from('messages').insert(dataPesan);
      await fetchConversations();
    } catch (e) {
      debugPrint('Gagal mengirim pesan: $e');
      rethrow;
    }
  }

  // Menghapus pesan berdasarkan primary key id_message.
  Future<void> deleteMessage(String messageId) async {
    if (messageId.trim().isEmpty) {
      throw ArgumentError('ID pesan tidak boleh kosong.');
    }

    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('id_message', messageId);

      _messages.removeWhere(
        (message) => message.idMessage == messageId,
      );

      _notifySafely();
      await fetchConversations();
    } catch (e) {
      debugPrint('Gagal menghapus pesan: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _messagesSubscription?.cancel();
    _conversationsSubscription?.cancel();
    super.dispose();
  }
}
