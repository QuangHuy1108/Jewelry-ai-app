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

  // Cache of fetched profiles: UID → { name, avatar }
  final Map<String, Map<String, dynamic>> _profileCache = {};

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

  Map<String, dynamic>? getParticipantProfile(String uid) => _profileCache[uid];

  /// Checks if the user is currently actively chatting with a given target ID.
  bool isChatActiveWith(String targetId) {
    if (_activeChatId == null) return false;
    try {
      final chat = _userChats.firstWhere((c) => c.id == _activeChatId);
      return chat.sellerId == targetId || chat.userId == targetId;
    } catch (_) {
      return false;
    }
  }

  /// Checks if either participant has blocked the other.
  bool isBlocked(String targetUid) {
    final uid = currentUserId;
    if (uid.isEmpty) return false;

    // Check if I blocked them
    final myProfile = _profileCache[uid];
    final myBlocked = myProfile?['blockedUsers'] as List<dynamic>? ?? [];
    if (myBlocked.contains(targetUid)) return true;

    // Check if they blocked me
    final theirProfile = _profileCache[targetUid];
    final theirBlocked = theirProfile?['blockedUsers'] as List<dynamic>? ?? [];
    if (theirBlocked.contains(uid)) return true;

    return false;
  }

  /// Checks if the current user has specifically blocked the target.
  bool amIBlocking(String targetUid) {
    final uid = currentUserId;
    if (uid.isEmpty) return false;
    final myProfile = _profileCache[uid];
    final myBlocked = myProfile?['blockedUsers'] as List<dynamic>? ?? [];
    return myBlocked.contains(targetUid);
  }

  // ─── Init ───────────────────────────────────────────────────────────────────

  /// Start listening for user's chat list. Should be called when auth state changes.
  void startListening() {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    _isLoadingChats = true;
    notifyListeners();

    // Cache current user profile for blocked status check
    _fetchProfile(uid);

    _chatListSub?.cancel();
    _chatListSub = _service.getUserChats(uid).listen(
      (chats) async {
        // Filter out chats that the user has soft-deleted
        _userChats = chats.where((c) => !c.deletedBy.contains(uid)).toList();
        _isLoadingChats = false;
        // Pre-fetch unknown profiles for the other person in each chat
        for (final chat in _userChats) {
          final otherId = chat.userId == uid ? chat.sellerId : chat.userId;
          if (!_profileCache.containsKey(otherId)) {
            _fetchProfile(otherId);
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
    closeActiveChat();
  }

  void closeActiveChat() {
    _activeChatId = null;
    _messagesSub?.cancel();
    _activeMessages = [];
    // Defer notification to avoid "setState() called during build/dispose" errors
    Future.microtask(() => notifyListeners());
  }

  // ─── Chat Session ───────────────────────────────────────────────────────────

  /// Subscribe to messages for a chat that was already resolved (e.g. from chat list).
  void openChatById(String chatId) {
    _activeChatId = chatId;
    _subscribeToMessages(chatId);
    markAllAsSeen(chatId);
    notifyListeners();
  }

  /// Marks unread messages as read
  Future<void> markAllAsSeen(String chatId) async {
    final uid = currentUserId;
    if (uid.isNotEmpty) {
      await _service.markChatAsRead(chatId, uid);
    }
  }

  /// Soft deletes a chat for the current user
  Future<void> deleteChat(String chatId) async {
    final uid = currentUserId;
    if (uid.isNotEmpty) {
      await _service.deleteChat(chatId, uid);
    }
  }

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

    // Pre-fetch profile if not cached
    if (!_profileCache.containsKey(sellerId)) {
      _fetchProfile(sellerId);
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
        
        // Auto mark as read while the chat is actively open
        markAllAsSeen(chatId);
        
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

  Future<void> sendMessage(
    String text, {
    String type = 'text',
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    final chatId = _activeChatId;
    final uid = currentUserId;
    if (chatId == null || uid.isEmpty || (text.trim().isEmpty && type == 'text')) return;

    try {
      await _service.sendMessage(
        chatId: chatId,
        senderId: uid,
        text: text.trim(),
        type: type,
        metadata: metadata,
        replyToId: replyToId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> pinMessage(String? messageId) async {
    if (_activeChatId == null) return;
    await _service.pinMessage(_activeChatId!, messageId);
  }

  Future<void> recallMessage(String messageId) async {
    if (_activeChatId == null) return;
    await _service.recallMessage(_activeChatId!, messageId);
  }

  Future<void> blockUser(String targetUid) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    
    // Update local cache for immediate UI feedback
    final myProfile = _profileCache[uid] ?? {};
    final myBlocked = List<String>.from(myProfile['blockedUsers'] as List<dynamic>? ?? []);
    if (!myBlocked.contains(targetUid)) {
      myBlocked.add(targetUid);
      myProfile['blockedUsers'] = myBlocked;
      _profileCache[uid] = myProfile;
      notifyListeners();
    }

    await _service.blockUser(uid, targetUid);
  }

  Future<void> unblockUser(String targetUid) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    // Update local cache for immediate UI feedback
    final myProfile = _profileCache[uid] ?? {};
    final myBlocked = List<String>.from(myProfile['blockedUsers'] as List<dynamic>? ?? []);
    if (myBlocked.contains(targetUid)) {
      myBlocked.remove(targetUid);
      myProfile['blockedUsers'] = myBlocked;
      _profileCache[uid] = myProfile;
      notifyListeners();
    }

    await _service.unblockUser(uid, targetUid);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _fetchProfile(String uid) async {
    final profile = await _service.getUserProfile(uid);
    if (profile != null) {
      _profileCache[uid] = profile;
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
