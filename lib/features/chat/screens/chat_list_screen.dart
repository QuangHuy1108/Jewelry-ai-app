import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../home/widgets/bottom_nav.dart';
import '../../../router/app_router.dart';
import '../providers/chat_provider.dart';
import '../models/chat_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start listening when screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final provider = context.watch<ChatProvider>();
    final query = _searchController.text.toLowerCase();
    
    // Filter by seller name from cached profiles
    final allChats = provider.userChats;
    final filteredChats = query.isEmpty
        ? allChats
        : allChats.where((c) {
            final profile = provider.getSellerProfile(c.sellerId);
            final name = (profile?['name'] ?? '').toString().toLowerCase();
            return name.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildHeader(),
      body: provider.isLoadingChats
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF808080)))
          : filteredChats.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: filteredChats.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFFF0F0F0), height: 1),
                  itemBuilder: (context, index) {
                    return _FadeIn(
                      delay: index * 80,
                      child: _buildChatRow(filteredChats[index], provider),
                    );
                  },
                ),
      bottomNavigationBar: isKeyboardVisible ? null : const BottomNav(),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(150),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF808080),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white30)),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('Messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 45,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                    decoration: InputDecoration(
                      hintText: 'Search Seller',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF999999), size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22.5), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF9F9F9), border: Border.all(color: const Color(0xFFEEEEEE))),
            child: const Icon(Icons.chat_bubble_outline, size: 40, color: Color(0xFFCCCCCC)),
          ),
          const SizedBox(height: 24),
          const Text('No messages yet.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 8),
          const Text('Start a conversation with a seller!', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildChatRow(ChatModel chat, ChatProvider provider) {
    final profile = provider.getSellerProfile(chat.sellerId);
    final sellerName = profile?['name'] ?? 'Seller';
    final avatarUrl = profile?['avatar'] ?? '';

    final now = DateTime.now();
    final isToday = chat.lastMessageTime.day == now.day &&
        chat.lastMessageTime.month == now.month &&
        chat.lastMessageTime.year == now.year;
    final timestamp = isToday
        ? '${chat.lastMessageTime.hour}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}'
        : '${chat.lastMessageTime.day}/${chat.lastMessageTime.month}';

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.chatDetail,
          arguments: {
            'chatId': chat.id,
            'sellerId': chat.sellerId,
            'sellerName': sellerName,
            'sellerAvatar': avatarUrl,
          },
        );
      },
      highlightColor: Colors.black.withAlpha(8),
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Avatar with online dot
            SizedBox(
              width: 52, height: 52,
              child: Stack(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF5F5F5)),
                    clipBehavior: Clip.hardEdge,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.storefront_outlined, color: Color(0xFFCCCCCC), size: 24)
                        : Image.network(avatarUrl, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 1, right: 1,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(color: const Color(0xFF4CAF50), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(sellerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF222222)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text(timestamp, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage.isEmpty ? 'Conversation started' : chat.lastMessage,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF777777)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Simple fade+slide in animation ─────────────────────────────────────────
class _FadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _FadeIn({required this.child, this.delay = 0});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _offset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: SlideTransition(position: _offset, child: widget.child));
}
