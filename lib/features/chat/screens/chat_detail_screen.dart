import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_model.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Passed via route arguments
  String? _chatId;
  String? _sellerId;
  String? _sellerName;
  String? _sellerAvatar;
  Map<String, dynamic>? _productContext; // { id, name, image, price }

  bool _initializing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializing) return; // Guard: only parse args once.
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;
    _initializing = true;

    // Support both flat keys (new standard) and legacy nested 'seller' map.
    final sellerMap = args['seller'] as Map<String, dynamic>?;
    _sellerId = args['sellerId'] as String? ?? sellerMap?['id'] as String?;
    _sellerName = args['sellerName'] as String? ?? sellerMap?['name'] as String?;
    _sellerAvatar = args['sellerAvatar'] as String? ?? sellerMap?['avatar'] as String?;
    _productContext = args['productContext'] as Map<String, dynamic>?;

    // If chatId was already pre-resolved (e.g., from chat list), use it directly.
    final preResolvedChatId = args['chatId'] as String?;
    if (preResolvedChatId != null) {
      _chatId = preResolvedChatId;
      Future.microtask(() {
        if (mounted) {
          context.read<ChatProvider>().openChatById(preResolvedChatId);
        }
      });
    } else if (_sellerId != null) {
      // Otherwise create/get chat from sellerId + optional productId.
      final productId = _productContext?['id'] as String?;
      Future.microtask(() async {
        if (!mounted) return;
        try {
          final chatId = await context.read<ChatProvider>().openChat(
            sellerId: _sellerId!,
            productId: productId,
          );
          if (mounted) setState(() => _chatId = chatId);
        } catch (e) {
          debugPrint('Error opening chat: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to open chat: $e')),
            );
            Navigator.pop(context); // Go back if we can't open the chat
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    context.read<ChatProvider>().sendMessage(text);
    _msgController.clear();
    setState(() => _isTyping = false);
    // Scroll to bottom after send
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final currentUserId = provider.currentUserId;
    final messages = provider.activeMessages;

    // Auto-scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildHeader(),
      body: SafeArea(
        child: Column(
          children: [
            // Product preview card (if a product is attached)
            if (_productContext != null) _buildProductPreview(),
            // Messages area
            Expanded(
              child: _chatId == null || provider.isLoadingMessages
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF808080)))
                  : messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.senderId == currentUserId;
                            return _FadeInMessage(
                              key: ValueKey(msg.id),
                              child: _buildMessageRow(msg, isMe),
                            );
                          },
                        ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF5F5F5)),
            child: const Icon(Icons.chat_bubble_outline, size: 32, color: Color(0xFFCCCCCC)),
          ),
          const SizedBox(height: 16),
          const Text('Say hello!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 6),
          const Text('Start the conversation below.', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildProductPreview() {
    final p = _productContext!;
    return GestureDetector(
      onTap: () => Navigator.pop(context), // Back to product
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                p['image'] ?? '',
                width: 56, height: 56, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: const Color(0xFFEEEEEE), child: const Icon(Icons.image, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    p['price'] != null ? '\$${p['price']}' : '',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFD4AF37), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
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
                  width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white30)),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                          backgroundImage: (_sellerAvatar?.isNotEmpty ?? false) ? NetworkImage(_sellerAvatar!) : null,
                          child: (_sellerAvatar?.isEmpty ?? true) ? const Icon(Icons.storefront, color: Color(0xFF999999)) : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF808080), width: 2),
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
                          Text(_sellerName ?? 'Seller', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const Text('Online', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageRow(MessageModel msg, bool isMe) {
    final time = '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(isMe: false),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubble(msg.text, isMe),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe) _buildAvatar(isMe: true),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isMe}) {
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(shape: BoxShape.circle, color: isMe ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5)),
      child: Icon(isMe ? Icons.person : Icons.storefront, size: 15, color: const Color(0xFFCCCCCC)),
    );
  }

  Widget _buildBubble(String text, bool isMe) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
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
        boxShadow: isMe ? [] : [const BoxShadow(color: Color(0x06000000), offset: Offset(0, 2), blurRadius: 4)],
      ),
      child: Text(text, style: TextStyle(fontSize: 15, color: isMe ? Colors.white : const Color(0xFF333333), height: 1.4)),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0A000000), offset: Offset(0, -2), blurRadius: 10)],
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
                  onChanged: (val) => setState(() => _isTyping = val.trim().isNotEmpty),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isTyping ? _sendMessage : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _isTyping ? const Color(0xFF333333) : const Color(0xFFF5F5F5),
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

// ─── Slide-up fade animation for new messages ───────────────────────────────
class _FadeInMessage extends StatefulWidget {
  final Widget child;
  const _FadeInMessage({super.key, required this.child});

  @override
  State<_FadeInMessage> createState() => _FadeInMessageState();
}

class _FadeInMessageState extends State<_FadeInMessage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _offset = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: SlideTransition(position: _offset, child: widget.child));
}
