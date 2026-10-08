//Salsa
import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<ChatModel> _messages = [];
  bool _isLoading = false;

  List<ChatModel> get messages => _messages;
  bool get isLoading => _isLoading;

  // Mengambil data lewat service
  Future<void> fetchMessages(String receiverId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _messages = await _chatService.getMessages(receiverId);
    } catch (e) {
      debugPrint("Error ambil pesan: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Mengirim pesan baru
  Future<void> sendNewMessage(String receiverId, String messageText) async {
    try {
      await _chatService.sendMessage(receiverId, messageText);
      await fetchMessages(receiverId); // Refresh pesan setelah dikirim
    } catch (e) {
      debugPrint("Error kirim pesan: $e");
    }
  }
}
