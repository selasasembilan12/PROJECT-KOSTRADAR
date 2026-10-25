
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String idMessage;
  final String pengirimId;
  final String penerimaId;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String jenisPesan;
  final String? mediaUrl;

  const ChatMessage({
    required this.idMessage,
    required this.pengirimId,
    required this.penerimaId,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.jenisPesan = 'text',
    this.mediaUrl,
  });

  bool get isImage => jenisPesan == 'image';

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      idMessage: map['id_message']?.toString() ?? '',
      pengirimId: map['pengirim_id']?.toString() ?? '',
      penerimaId: map['penerima_id']?.toString() ?? '',
      message: (map['isi_pesan'] ?? '').toString(),
      createdAt: DateTime.tryParse(
            map['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      isRead: map['is_read'] == true,
      jenisPesan: (map['jenis_pesan'] ?? 'text').toString(),
      mediaUrl: map['media_url']?.toString(),
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

  static const String _bucketName = 'chat-images';
  static const int _maxImageBytes = 10 * 1024 * 1024;

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

  // Membentuk daftar percakapan dari pesan terbaru.
  List<ChatConversation> _buildConversations(
    List<Map<String, dynamic>> rows,
    String myId,
  ) {
    final latest = <String, Map<String, dynamic>>{};
    final unread = <String, int>{};

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

      final partnerId = sender == myId ? receiver : sender;

      if (partnerId == myId) continue;

      if (receiver == myId && row['is_read'] != true) {
        unread[partnerId] = (unread[partnerId] ?? 0) + 1;
      }

      latest.putIfAbsent(partnerId, () => row);
    }

    final result = <ChatConversation>[];

    for (final entry in latest.entries) {
      final row = entry.value;
      final isImage = row['jenis_pesan'] == 'image';

      result.add(
        ChatConversation(
          lawanBicaraId: entry.key,
          pesanTerakhir: isImage
              ? 'Foto'
              : (row['isi_pesan'] ?? '').toString(),
          waktuTerakhir: DateTime.tryParse(
                row['created_at']?.toString() ?? '',
              ) ??
              DateTime.now(),
          jumlahBelumDibaca: unread[entry.key] ?? 0,
        ),
      );
    }

    result.sort(
      (a, b) => b.waktuTerakhir.compareTo(a.waktuTerakhir),
    );

    return result;
  }

  // Memuat daftar percakapan akun yang sedang login.
  Future<void> fetchConversations() async {
    if (_fetchingConversations) {
      _fetchConversationsAgain = true;
      return;
    }

    _fetchingConversations = true;
    final myId = _supabase.auth.currentUser?.id;

    if (myId == null) {
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
          .or('pengirim_id.eq.$myId,penerima_id.eq.$myId')
          .order('created_at', ascending: false);

      _conversations = _buildConversations(
        List<Map<String, dynamic>>.from(response),
        myId,
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

  // Memantau perubahan pesan untuk daftar percakapan.
  void listenToConversations() {
    final myId = _supabase.auth.currentUser?.id;

    if (myId == null) {
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
          return row['pengirim_id']?.toString() == myId ||
              row['penerima_id']?.toString() == myId;
        }).toList();

        _conversations = _buildConversations(
          relevantRows,
          myId,
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

  // Memantau pesan dua arah dalam satu room chat.
  void listenToMessages(String partnerId) {
    final myId = _supabase.auth.currentUser?.id;

    if (myId == null || partnerId.trim().isEmpty) return;

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

        final filtered = rows.where((row) {
          final sender = row['pengirim_id']?.toString();
          final receiver = row['penerima_id']?.toString();

          return (sender == myId && receiver == partnerId) ||
              (sender == partnerId && receiver == myId);
        }).toList();

        _messages = filtered
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

  // Tandai pesan masuk dari lawan bicara sebagai sudah dibaca.
  Future<void> markMessagesAsRead(String partnerId) async {
    final myId = _supabase.auth.currentUser?.id;

    if (myId == null || partnerId.trim().isEmpty) return;

    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('pengirim_id', partnerId)
        .eq('penerima_id', myId)
        .eq('is_read', false);
  }

  // Mengirim pesan teks.
  Future<void> sendNewMessage(
    String partnerId,
    String text, {
    String? idKost,
  }) async {
    final myId = _supabase.auth.currentUser?.id;
    final message = text.trim();

    if (myId == null) {
      throw StateError('Pengguna belum login.');
    }

    if (partnerId.trim().isEmpty || partnerId == myId) {
      throw ArgumentError('ID penerima tidak valid.');
    }

    if (message.isEmpty) {
      throw ArgumentError('Pesan tidak boleh kosong.');
    }

    final payload = <String, dynamic>{
      'pengirim_id': myId,
      'penerima_id': partnerId,
      'isi_pesan': message,
      'is_read': false,
      'jenis_pesan': 'text',
    };

    if (idKost != null && idKost.trim().isNotEmpty) {
      payload['id_kost'] = idKost;
    }

    await _supabase.from('messages').insert(payload);
    await fetchConversations();
  }

  // Upload foto ke Storage privat dan simpan path-nya ke messages.
  Future<void> sendImageMessage(
    String partnerId,
    XFile image, {
    String? idKost,
  }) async {
    final myId = _supabase.auth.currentUser?.id;

    if (myId == null) {
      throw StateError('Pengguna belum login.');
    }

    if (partnerId.trim().isEmpty || partnerId == myId) {
      throw ArgumentError('ID penerima tidak valid.');
    }

    final nameParts = image.name.split('.');
    final extension = nameParts.length > 1
        ? nameParts.last.toLowerCase()
        : 'jpg';

    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

    if (!allowedExtensions.contains(extension)) {
      throw ArgumentError(
        'Format foto harus JPG, JPEG, PNG, atau WEBP.',
      );
    }

    final bytes = await image.readAsBytes();

    if (bytes.isEmpty) {
      throw StateError('Foto tidak dapat dibaca.');
    }

    if (bytes.length > _maxImageBytes) {
      throw ArgumentError('Ukuran foto maksimal 10 MB.');
    }

    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final path =
        '$myId/${DateTime.now().microsecondsSinceEpoch}.$extension';

    await _supabase.storage.from(_bucketName).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: false,
      ),
    );

    try {
      final payload = <String, dynamic>{
        'pengirim_id': myId,
        'penerima_id': partnerId,
        'isi_pesan': 'Foto',
        'jenis_pesan': 'image',
        'media_url': path,
        'is_read': false,
      };

      if (idKost != null && idKost.trim().isNotEmpty) {
        payload['id_kost'] = idKost;
      }

      await _supabase.from('messages').insert(payload);
      await fetchConversations();
    } catch (e) {
      // Hapus file yang telanjur diupload jika insert pesan gagal.
      try {
        await _supabase.storage.from(_bucketName).remove([path]);
      } catch (cleanupError) {
        debugPrint('Gagal membersihkan file foto: $cleanupError');
      }

      rethrow;
    }
  }

  // Membuat URL sementara untuk menampilkan foto private.
  Future<String> getImageSignedUrl(String path) async {
    if (path.trim().isEmpty) {
      throw ArgumentError('Path foto kosong.');
    }

    // Mendukung data lama yang mungkin menyimpan URL langsung.
    if (path.startsWith('https://') || path.startsWith('http://')) {
      return path;
    }

    return _supabase.storage
        .from(_bucketName)
        .createSignedUrl(path, 3600);
  }

  // Menghapus pesan milik sendiri dan file foto terkait.
  Future<void> deleteMessage(String messageId) async {
    if (messageId.trim().isEmpty) {
      throw ArgumentError('ID pesan tidak boleh kosong.');
    }

    final myId = _supabase.auth.currentUser?.id;

    if (myId == null) {
      throw StateError('Pengguna belum login.');
    }

    final row = await _supabase
        .from('messages')
        .select('id_message, pengirim_id, media_url')
        .eq('id_message', messageId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Pesan tidak ditemukan.');
    }

    if (row['pengirim_id']?.toString() != myId) {
      throw StateError(
        'Kamu hanya dapat menghapus pesan milik sendiri.',
      );
    }

    final mediaPath = row['media_url']?.toString();

    // Hapus pesan dari database terlebih dahulu.
    await _supabase
        .from('messages')
        .delete()
        .eq('id_message', messageId)
        .eq('pengirim_id', myId);

    _messages.removeWhere(
      (message) => message.idMessage == messageId,
    );

    _notifySafely();

    // Hapus foto Storage jika pesan memiliki media.
    if (mediaPath != null && mediaPath.isNotEmpty) {
      // URL lama bukan path objek Storage.
      if (!mediaPath.startsWith('http://') &&
          !mediaPath.startsWith('https://')) {
        try {
          await _supabase.storage
              .from(_bucketName)
              .remove([mediaPath]);
        } catch (e) {
          // Pesan sudah dihapus; log jika pembersihan file gagal.
          debugPrint('Pesan terhapus, tetapi file foto gagal dihapus: $e');
        }
      }
    }

    await fetchConversations();
  }

  @override
  void dispose() {
    _disposed = true;
    _messagesSubscription?.cancel();
    _conversationsSubscription?.cancel();
    super.dispose();
  }
}
