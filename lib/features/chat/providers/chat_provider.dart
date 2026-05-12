import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../../../services/chat_service.dart';

/// Manages chat state for the entire app.
/// Uses ChatService for all Firebase operations.
class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── State ──────────────────────────────────────────────────────────────────

  List<ChatModel> _userChats = [];
  List<MessageModel> _activeMessages = [];
  String? _activeChatId;
  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;
  String? _error;

  // Cache of fetched seller profiles: sellerId → { name, avatar }
  final Map<String, Map<String, dynamic>> _sellerCache = {};

  // Subscriptions
  StreamSubscription<List<ChatModel>>? _chatListSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;

  // ─── Getters ────────────────────────────────────────────────────────────────

  String get currentUserId => _auth.currentUser?.uid ?? '';
  List<ChatModel> get userChats => _userChats;
  List<MessageModel> get activeMessages => _activeMessages;
  String? get activeChatId => _activeChatId;
  bool get isLoadingChats => _isLoadingChats;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;

  Map<String, dynamic>? getSellerProfile(String sellerId) => _sellerCache[sellerId];

  // ─── Init ───────────────────────────────────────────────────────────────────

  /// Start listening for user's chat list. Should be called when auth state changes.
  void startListening() {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    _isLoadingChats = true;
    notifyListeners();

    _chatListSub?.cancel();
    _chatListSub = _service.getUserChats(uid).listen(
      (chats) async {
        _userChats = chats;
        _isLoadingChats = false;
        // Pre-fetch unknown seller profiles
        for (final chat in chats) {
          if (!_sellerCache.containsKey(chat.sellerId)) {
            _fetchSellerProfile(chat.sellerId);
          }
        }
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoadingChats = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _chatListSub?.cancel();
    _messagesSub?.cancel();
  }

  // ─── Chat Session ───────────────────────────────────────────────────────────

  /// Subscribe to messages for a chat that was already resolved (e.g. from chat list).
  void openChatById(String chatId) {
    _activeChatId = chatId;
    _subscribeToMessages(chatId);
    notifyListeners();
  }

  /// No-op shim kept for backward compatibility with legacy call-sites.
  void markAllAsSeen() {}

  // ─── Chat Session ───────────────────────────────────────────────────────────

  /// Opens or creates a chat between the current user and a seller.
  /// Optionally linked to a product.
  /// Returns the chatId.
  Future<String> openChat({
    required String sellerId,
    String? productId,
  }) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('User not authenticated');

    final chatId = await _service.createOrGetChat(
      userId: uid,
      sellerId: sellerId,
      productId: productId,
    );

    _activeChatId = chatId;
    _subscribeToMessages(chatId);

    // Pre-fetch seller profile if not cached
    if (!_sellerCache.containsKey(sellerId)) {
      _fetchSellerProfile(sellerId);
    }

    notifyListeners();
    return chatId;
  }

  void _subscribeToMessages(String chatId) {
    _messagesSub?.cancel();
    _isLoadingMessages = true;
    notifyListeners();

    _messagesSub = _service.getChatMessages(chatId).listen(
      (msgs) {
        _activeMessages = msgs;
        _isLoadingMessages = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoadingMessages = false;
        notifyListeners();
      },
    );
  }

  // ─── Send Message ───────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final chatId = _activeChatId;
    final uid = currentUserId;
    if (chatId == null || uid.isEmpty || text.trim().isEmpty) return;

    try {
      await _service.sendMessage(
        chatId: chatId,
        senderId: uid,
        text: text.trim(),
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _fetchSellerProfile(String sellerId) async {
    final profile = await _service.getUserProfile(sellerId);
    if (profile != null) {
      _sellerCache[sellerId] = profile;
      notifyListeners();
    }
  }

  /// Public helper for callers that need a fresh refresh (e.g., from push notifications).
  void refreshChats() {
    startListening();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
