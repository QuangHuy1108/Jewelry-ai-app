import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../router/app_router.dart';
import '../../../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  String? _chatId;
  String? _sellerId;
  String? _sellerName;
  String? _sellerAvatar;
  Map<String, dynamic>? _productContext;

  bool _initializing = false;
  MessageModel? _replyingTo;
  ChatProvider? _chatProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider ??= context.read<ChatProvider>();

    // Task 1: Robust Auth Resolution - Watch for currentUserId
    final currentUserId = context.watch<ChatProvider>().currentUserId;
    
    // If Auth hasn't finished loading (Cold Start), keep the state waiting, don't lock it with _initializing
    if (currentUserId.isEmpty) return;
    if (_initializing) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;
    _initializing = true;

    final sellerMap = args['seller'] as Map<String, dynamic>?;
    _sellerId = args['sellerId'] as String? ?? sellerMap?['id'] as String?;
    _sellerName =
        args['sellerName'] as String? ?? sellerMap?['name'] as String?;
    _sellerAvatar =
        args['sellerAvatar'] as String? ?? sellerMap?['avatar'] as String?;
    _productContext = args['productContext'] as Map<String, dynamic>?;

    final preResolvedChatId = args['chatId'] as String?;
    if (preResolvedChatId != null && preResolvedChatId.isNotEmpty) {
      _chatId = preResolvedChatId;
      Future.microtask(() {
        if (mounted) {
          context.read<ChatProvider>().openChatById(preResolvedChatId);
          
          final productId = _productContext?['id'] as String?;
          if (productId != null && _productContext != null) {
            _autoSendProductIfNeeded(preResolvedChatId, productId);
          }
        }
      });
    } else if (_sellerId != null) {
      // Calculate symmetric ID immediately to avoid split-brain
      final currentUserId = context.read<ChatProvider>().currentUserId;
      if (currentUserId.isNotEmpty) {
        final symmetricId = ChatService().getChatRoomId(
          currentUserId,
          _sellerId!,
        );
        _chatId = symmetricId;
      }

      final productId = _productContext?['id'] as String?;
      Future.microtask(() async {
        if (!mounted) return;
        try {
          final chatId = await context.read<ChatProvider>().openChat(
            sellerUserId: _sellerId!,
            productId: productId,
          );
          if (mounted) setState(() => _chatId = chatId);
          
          if (productId != null && _productContext != null) {
            _autoSendProductIfNeeded(chatId, productId);
          }
        } catch (e) {
          debugPrint('ChatDetailScreen Error: Failed to open chat session: $e');
          // Step 1: COMPLETELY remove the Navigator.pop(context) here.
          // Keep the screen open for the system to retry or show errors.
        }
      });
    }

    // Phase 2: Dynamic Name Resolution Hardening
    if (_sellerName == null ||
        _sellerName == 'Seller' ||
        _sellerName == 'Product Owner' ||
        _sellerName!.contains('💎') ||
        _sellerName!.contains('message')) {
      _resolveSenderName();
    }
  }

  Future<void> _resolveSenderName() async {
    final idToFetch = _sellerId;
    if (idToFetch == null) return;

    try {
      // 1. Try sellers collection
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(idToFetch)
          .get();
      if (sellerDoc.exists) {
        final data = sellerDoc.data();
        if (mounted) {
          setState(() {
            _sellerName = data?['name'] ?? data?['fullName'];
            _sellerAvatar = data?['avatar'];
          });
          return;
        }
      }

      // 2. Try users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(idToFetch)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            _sellerName = data?['name'] ?? data?['fullName'] ?? 'User';
            _sellerAvatar = data?['avatar'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error resolving sender name: $e');
    }
  }

  Future<void> _autoSendProductIfNeeded(String chatId, String productId) async {
    try {
      final lastMsgs = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
          
      bool shouldSend = true;
      if (lastMsgs.docs.isNotEmpty) {
        final lastMsg = MessageModel.fromDoc(lastMsgs.docs.first);
        // Check if the last message was the same shared_product card sent recently
        if (lastMsg.type == 'shared_product' && 
            lastMsg.metadata?['id'] == productId) {
          shouldSend = false;
        }
      }
      
      if (shouldSend && mounted) {
        // We do not await this, just fire and forget
        context.read<ChatProvider>().sendMessage(
          '', // Empty text for a purely product card message
          type: 'shared_product',
          metadata: _productContext,
        );
      }
    } catch (e) {
      debugPrint('Error auto sending product: $e');
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    // Clear active chat state so new messages aren't auto-read while list is open
    _chatProvider?.closeActiveChat();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    context.read<ChatProvider>().sendMessage(text, replyToId: _replyingTo?.id);
    _msgController.clear();
    setState(() {
      _isTyping = false;
      _replyingTo = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToMessage(String messageId, List<dynamic> items) {
    if (!_scrollController.hasClients) return;
    final index = items.indexWhere(
      (item) => item is MessageModel && item.id == messageId,
    );
    if (index != -1) {
      // Very rough estimation since we can't easily scroll to index with standard ScrollController
      final estimatedOffset = index * 80.0;
      _scrollController.animateTo(
        estimatedOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _blockUser() async {
    if (_sellerId != null) {
      await context.read<ChatProvider>().blockUser(_sellerId!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User blocked')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final currentUserId = provider.currentUserId;

    ChatModel? currentChat;
    try {
      currentChat = provider.userChats.firstWhere((c) => c.id == _chatId);
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildHeader(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _chatId == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF808080),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(_chatId)
                          .collection('messages')
                          .orderBy('createdAt', descending: true)
                          .snapshots(includeMetadataChanges: true),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF808080),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final messages = docs
                            .map((d) => MessageModel.fromDoc(d))
                            .toList();

                        final List<dynamic> items = [];
                        for (int i = 0; i < messages.length; i++) {
                          final msg = messages[i];
                          items.add(msg);

                          bool addDate = false;
                          final msgTime = msg.createdAt;

                          if (i == messages.length - 1) {
                            addDate = true;
                          } else {
                            final nextMsg = messages[i + 1];
                            final nextMsgTime = nextMsg.createdAt;

                            final msgDate = DateTime(
                              msgTime.year,
                              msgTime.month,
                              msgTime.day,
                            );
                            final nextMsgDate = DateTime(
                              nextMsgTime.year,
                              nextMsgTime.month,
                              nextMsgTime.day,
                            );
                            if (msgDate != nextMsgDate) {
                              addDate = true;
                            }
                          }

                          if (addDate) {
                            items.add(
                              DateTime(
                                msgTime.year,
                                msgTime.month,
                                msgTime.day,
                              ),
                            );
                          }
                        }

                        if (items.isEmpty) return _buildEmptyState();

                        return Column(
                          children: [
                            if (currentChat?.pinnedMessageId != null)
                              _buildPinnedMessageView(
                                currentChat!,
                                messages,
                                items,
                              ),
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  if (item is DateTime) {
                                    return _DateHeader(date: item);
                                  }
                                  final msg = item as MessageModel;
                                  final isMe = msg.senderId == currentUserId;
                                  return _FadeInMessage(
                                    key: ValueKey(msg.id),
                                    child: _buildMessageRow(
                                      msg,
                                      isMe,
                                      provider,
                                      messages,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            if (_replyingTo != null) _buildReplyPreview(),
            (_sellerId != null && provider.isBlocked(_sellerId!))
                ? _buildBlockedInput()
                : _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedMessageView(
    ChatModel chat,
    List<MessageModel> messages,
    List<dynamic> items,
  ) {
    final pinnedMsg = messages.cast<MessageModel?>().firstWhere(
      (m) => m?.id == chat.pinnedMessageId,
      orElse: () => null,
    );
    if (pinnedMsg == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _scrollToMessage(chat.pinnedMessageId!, items),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9F9),
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, color: Color(0xFFD4AF37), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pinned Message',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  Text(
                    pinnedMsg.text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
              onPressed: () => context.read<ChatProvider>().pinMessage(null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          const Icon(Icons.reply, color: Color(0xFF808080)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Replying to message',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  _replyingTo!.text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF5F5F5),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 32,
              color: Color(0xFFCCCCCC),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Say hello!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start the conversation below.',
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    final provider = context.read<ChatProvider>();
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: const BoxDecoration(
          color: Color(0xFF808080),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFEEEEEE),
                          backgroundImage: (_sellerAvatar?.isNotEmpty ?? false)
                              ? NetworkImage(_sellerAvatar!)
                              : null,
                          child: (_sellerAvatar?.isEmpty ?? true)
                              ? const Icon(
                                  Icons.storefront,
                                  color: Color(0xFF999999),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF808080),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _sellerName ?? '...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'block') {
                    if (_sellerId != null && provider.amIBlocking(_sellerId!)) {
                      provider.unblockUser(_sellerId!);
                    } else {
                      _blockUser();
                    }
                  }
                },
                itemBuilder: (context) {
                  final isBlocked =
                      _sellerId != null && provider.amIBlocking(_sellerId!);
                  return [
                    PopupMenuItem(
                      value: 'block',
                      child: Text(
                        isBlocked ? 'Unblock User' : 'Block User',
                        style: TextStyle(
                          color: isBlocked ? Colors.blue : Colors.red,
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageRow(
    MessageModel msg,
    bool isMe,
    ChatProvider provider,
    List<MessageModel> messages,
  ) {
    if (msg.isRecalled) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '🚫 Message has been recalled',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ),
        ),
      );
    }

    final time =
        '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    // Find replied message context
    MessageModel? repliedMsg;
    if (msg.replyToId != null) {
      repliedMsg = messages.cast<MessageModel?>().firstWhere(
        (m) => m?.id == msg.replyToId,
        orElse: () => null,
      );
    }

    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(msg, isMe, provider);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) _buildAvatar(isMe: false),
            if (!isMe) const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (repliedMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: Color(0xFFD4AF37), width: 3),
                        ),
                      ),
                      child: Text(
                        repliedMsg.text,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777777),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (msg.type == 'shared_product')
                    _buildSharedProductCard(msg)
                  else
                    _buildBubble(msg.text, isMe),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                        ),
                      ),
                      if (isMe &&
                          messages.isNotEmpty &&
                          msg.id == messages.first.id) ...[
                        const SizedBox(width: 6),
                        Text(
                          msg.isRead ? 'Seen' : 'Sent',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFBDBDBD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isMe) const SizedBox(width: 8),
            if (isMe) _buildAvatar(isMe: true),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(MessageModel msg, bool isMe, ChatProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyingTo = msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Pin Message'),
              onTap: () {
                Navigator.pop(context);
                provider.pinMessage(msg.id);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.red),
                title: const Text(
                  'Recall',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  provider.recallMessage(msg.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedProductCard(MessageModel msg) {
    final meta = msg.metadata ?? {};
    final imageList = meta['images'] as List<dynamic>?;
    final String imageUrl = meta['image'] ?? 
        (imageList?.isNotEmpty == true 
            ? imageList!.firstWhere((u) => !u.toString().endsWith('.mp4'), orElse: () => '').toString() 
            : '');
    final price = meta['price'] ?? meta['basePrice'];
    final rating = meta['rating'] ?? '0.0';
    final reviews = meta['reviewCount'] ?? meta['reviews'] ?? 0;

    return GestureDetector(
      onTap: () {
        if (meta['id'] != null) {
          Navigator.pushNamed(
            context,
            AppRouter.product,
            arguments: meta,
          );
        }
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: const Color(0xFFEEEEEE),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              meta['name'] ?? 'Product',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFD4AF37), size: 14),
                const SizedBox(width: 4),
                Text(
                  '$rating',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                ),
                Text(
                  ' ($reviews)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price != null ? '\$$price' : '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({required bool isMe}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isMe ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
      ),
      child: Icon(
        isMe ? Icons.person : Icons.storefront,
        size: 15,
        color: const Color(0xFFCCCCCC),
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF808080) : Colors.white,
        border: isMe ? null : Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 20),
        ),
        boxShadow: isMe
            ? []
            : [
                const BoxShadow(
                  color: Color(0x06000000),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: isMe ? Colors.white : const Color(0xFF333333),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBlockedInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: const Center(
        child: Text(
          'You cannot reply to this chat.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: TextField(
                  controller: _msgController,
                  onChanged: (val) =>
                      setState(() => _isTyping = val.trim().isNotEmpty),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isTyping ? _sendMessage : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isTyping
                      ? const Color(0xFF333333)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isTyping ? Icons.send_rounded : Icons.mic_none,
                  color: _isTyping ? Colors.white : const Color(0xFF777777),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1;

    String label;
    if (isToday) {
      label = 'Today';
    } else if (isYesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('dd/MM/yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FadeInMessage extends StatefulWidget {
  final Widget child;
  const _FadeInMessage({super.key, required this.child});

  @override
  State<_FadeInMessage> createState() => _FadeInMessageState();
}

class _FadeInMessageState extends State<_FadeInMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _offset, child: widget.child),
  );
}
