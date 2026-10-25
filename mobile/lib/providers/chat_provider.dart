
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String idMessage;
  final String pengirimId;
  final String penerimaId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.idMessage,
    required this.pengirimId,
    required this.penerimaId,
    required this.message,
    required this.createdAt,
    this.isRead = false,
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
      isRead: map['is_read'] == true,
    );
  }
}

class ChatConversation {
  final String lawanBicaraId;
  final String pesanTerakhir;
  final DateTime waktuTerakhir;
  final int jumlahBelumDibaca;

  const ChatConversation({
    required this.lawanBicaraId,
    required this.pesanTerakhir,
    required this.waktuTerakhir,
    this.jumlahBelumDibaca = 0,
  });
}

class ChatProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  List<ChatConversation> _conversations = [];
  List<ChatConversation> get conversations =>
      List.unmodifiable(_conversations);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<Map<String, dynamic>>>?
      _messagesSubscription;

  StreamSubscription<List<Map<String, dynamic>>>?
      _conversationsSubscription;

  bool _disposed = false;
  bool _fetchingConversations = false;
  bool _fetchConversationsAgain = false;

  void _notifySafely() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  List<ChatConversation> _buildConversations(
    List<Map<String, dynamic>> rows,
    String myUserId,
  ) {
    final latestByPartner = <String, Map<String, dynamic>>{};
    final unreadByPartner = <String, int>{};

    final sortedRows = [...rows]
      ..sort((a, b) {
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
      final sender = row['pengirim_id']?.toString() ?? '';
      final receiver = row['penerima_id']?.toString() ?? '';

      if (sender.isEmpty || receiver.isEmpty) continue;

      final partnerId = sender == myUserId ? receiver : sender;

      if (partnerId == myUserId) continue;

      if (receiver == myUserId && row['is_read'] != true) {
        unreadByPartner[partnerId] =
            (unreadByPartner[partnerId] ?? 0) + 1;
      }

      latestByPartner.putIfAbsent(partnerId, () => row);
    }

    final result = <ChatConversation>[];

    for (final entry in latestByPartner.entries) {
      final row = entry.value;

      result.add(
        ChatConversation(
          lawanBicaraId: entry.key,
          pesanTerakhir: (row['isi_pesan'] ?? '').toString(),
          waktuTerakhir: DateTime.tryParse(
                row['created_at']?.toString() ?? '',
              ) ??
              DateTime.now(),
          jumlahBelumDibaca: unreadByPartner[entry.key] ?? 0,
        ),
      );
    }

    result.sort(
      (a, b) => b.waktuTerakhir.compareTo(a.waktuTerakhir),
    );

    return result;
  }

  Future<void> fetchConversations() async {
    if (_fetchingConversations) {
      _fetchConversationsAgain = true;
      return;
    }

    _fetchingConversations = true;

    final myUserId = _supabase.auth.currentUser?.id;

    if (myUserId == null) {
      _conversations = [];
      _isLoading = false;
      _fetchingConversations = false;
      _notifySafely();
      return;
    }

    try {
      final response = await _supabase
          .from('messages')
          .select()
          .or(
            'pengirim_id.eq.$myUserId,'
            'penerima_id.eq.$myUserId',
          )
          .order('created_at', ascending: false);

      _conversations = _buildConversations(
        List<Map<String, dynamic>>.from(response),
        myUserId,
      );
    } catch (e, stackTrace) {
      debugPrint('Gagal mengambil daftar percakapan: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _fetchingConversations = false;
      _isLoading = false;
      _notifySafely();

      if (_fetchConversationsAgain && !_disposed) {
        _fetchConversationsAgain = false;
        unawaited(fetchConversations());
      }
    }
  }

  void listenToConversations() {
    final myUserId = _supabase.auth.currentUser?.id;

    if (myUserId == null) return;

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
          final sender = row['pengirim_id']?.toString();
          final receiver = row['penerima_id']?.toString();

          return (sender == myUserId &&
                  receiver == lawanBicaraId) ||
              (sender == lawanBicaraId &&
                  receiver == myUserId);
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

  Future<void> markMessagesAsRead(String lawanBicaraId) async {
    final myUserId = _supabase.auth.currentUser?.id;

    if (myUserId == null || lawanBicaraId.trim().isEmpty) {
      return;
    }

    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('pengirim_id', lawanBicaraId)
          .eq('penerima_id', myUserId)
          .eq('is_read', false);
    } catch (e, stackTrace) {
      debugPrint('Gagal menandai pesan sebagai dibaca: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> sendNewMessage(
    String lawanBicaraId,
    String teksPesan, {
    String? idKost,
  }) async {
    final myUserId = _supabase.auth.currentUser?.id;
    final message = teksPesan.trim();

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

    if (message.isEmpty) {
      throw ArgumentError('Pesan tidak boleh kosong.');
    }

    final payload = <String, dynamic>{
      'pengirim_id': myUserId,
      'penerima_id': lawanBicaraId,
      'isi_pesan': message,
      'is_read': false,
    };

    if (idKost != null && idKost.trim().isNotEmpty) {
      payload['id_kost'] = idKost;
    }

    try {
      await _supabase.from('messages').insert(payload);
      await fetchConversations();
    } catch (e, stackTrace) {
      debugPrint('Gagal mengirim pesan: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

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
    } catch (e, stackTrace) {
      debugPrint('Gagal menghapus pesan: $e');
      debugPrintStack(stackTrace: stackTrace);
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
