import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final String currentUserId = 'user123';
  final String sellerId = 'seller456';

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg_0',
      text: 'Hi there! How can I help you today?',
      senderId: 'seller456',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      status: MessageStatus.seen,
    )
  ];

  // Expose messages reversed for a bottom-up ListView layout
  List<ChatMessage> get messages => _messages.toList().reversed.toList();

  ChatMessage? get pinnedMessage {
    try {
      return _messages.firstWhere((msg) => msg.isPinned);
    } catch (_) {
      return null;
    }
  }

  void markAllAsSeen() {
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].senderId != currentUserId && _messages[i].status != MessageStatus.seen) {
        _messages[i].status = MessageStatus.seen;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> sendMessage(String text, {Map<String, dynamic>? attachedProduct}) async {
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMessage = ChatMessage(
      id: msgId,
      text: text,
      senderId: currentUserId,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      attachedProduct: attachedProduct,
    );

    _messages.add(newMessage);
    notifyListeners();

    // 1. Simulate instant connection sent
    await Future.delayed(const Duration(milliseconds: 100));
    _updateMessageStatus(msgId, MessageStatus.sent);

    // 2. Simulate network transmission delay
    await Future.delayed(const Duration(milliseconds: 500));
    _updateMessageStatus(msgId, MessageStatus.delivered);

    // 3. Simulate seller opening their app and reading it
    await Future.delayed(const Duration(seconds: 2));
    _updateMessageStatus(msgId, MessageStatus.seen);

    // 4. Simulate seller typing a reply
    await Future.delayed(const Duration(seconds: 2));
    _receiveAutoReply();
  }

  void _updateMessageStatus(String id, MessageStatus status) {
    final index = _messages.indexWhere((msg) => msg.id == id);
    if (index != -1) {
      _messages[index].status = status;
      notifyListeners();
    }
  }

  void _receiveAutoReply() {
    final replyId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add(
      ChatMessage(
        id: replyId,
        text: 'Thanks for reaching out! Let me check that for you.',
        senderId: sellerId,
        timestamp: DateTime.now(),
        status: MessageStatus.delivered, // Starts as delivered until user reads it
      ),
    );
    notifyListeners();
  }

  void togglePinMessage(String id) {
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].id == id) {
        // Toggle the target
        _messages[i] = _messages[i].copyWith(isPinned: !_messages[i].isPinned);
      } else {
        // Unpin others (max 1 pin supported for simplicity)
        _messages[i] = _messages[i].copyWith(isPinned: false);
      }
    }
    notifyListeners();
  }
}
