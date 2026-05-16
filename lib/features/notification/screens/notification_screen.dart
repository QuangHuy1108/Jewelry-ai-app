import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../router/app_router.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import 'package:collection/collection.dart'; // for groupBy

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  int _previousCount = 0;
  bool _showNewPill = false;
  String? _newestProcessedId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Register initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<NotificationProvider>();
      _previousCount = provider.notifications.length;
      if (provider.notifications.isNotEmpty) {
        _newestProcessedId = provider.notifications.first.id;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset < 50 && _showNewPill) {
      if (mounted) setState(() => _showNewPill = false);
    }
  }

  void _scrollToTop() {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() => _showNewPill = false);
    }
  }

  void _checkAutoScroll(List<NotificationItem> currentList) {
    if (currentList.isEmpty) return;

    final currentCount = currentList.length;
    final currentNewestId = currentList.first.id;

    if (currentCount > _previousCount && currentNewestId != _newestProcessedId) {
      // Meaning a new item arrived
      if (_scrollController.hasClients && _scrollController.offset > 100) {
        // User is scrolled down, show pill
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _showNewPill = true);
        });
      } else {
        // Automatically scroll to top
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToTop();
        });
      }
    }

    _previousCount = currentCount;
    _newestProcessedId = currentNewestId;
  }

  void _handleTap(NotificationItem n, NotificationProvider provider) {
    if (!n.isRead) {
      provider.markAsRead(n.id);
    }
    HapticFeedback.selectionClick();

    if (n.type == 'order') {
      Navigator.pushNamed(context, AppRouter.myOrders);
    } else if (n.type == 'promotion') {
      Navigator.pop(context); // back to home maybe
    } else if (n.type == 'chat') {
      final senderName = n.metadata?['senderName'] ?? n.title;
      Navigator.pushNamed(context, AppRouter.chatDetail, arguments: {
        'chatId': n.chatId,
        'seller': {
          'id': n.sellerId ?? n.targetId,
          'name': senderName,
          'avatar': ''
        }
      });
    }
  }
  
  void _showLongPressMenu(NotificationItem n, NotificationProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(n.isRead ? Icons.mark_chat_unread_outlined : Icons.mark_email_read_outlined),
                title: Text(n.isRead ? 'Mark as unread' : 'Mark as read'),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.toggleReadStatus(n.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleDelete(NotificationItem n, NotificationProvider provider) {
    provider.deleteNotification(n.id);
    HapticFeedback.mediumImpact();
    AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('Notification deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFFD4AF37),
          onPressed: () {
            provider.undoDelete(n);
          },
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _getIcon(String type, bool isRead) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'order':
        iconData = Icons.local_shipping_outlined;
        iconColor = const Color(0xFF333333);
        break;
      case 'promotion':
        iconData = Icons.local_offer_outlined;
        iconColor = const Color(0xFFD4AF37); // Gold for sales
        break;
      case 'chat':
        iconData = Icons.chat_bubble_outline;
        iconColor = const Color(0xFF4CAF50);
        break;
      default:
        iconData = Icons.notifications_outlined;
        iconColor = const Color(0xFF333333);
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFFAFAFA) : const Color(0xFFF5EEF8), // purple tint highlight
        shape: BoxShape.circle,
        border: Border.all(color: isRead ? Colors.transparent : const Color(0xFFE1BEE7), width: 1),
      ),
      child: Icon(iconData, color: isRead ? const Color(0xFFBBBBBB) : iconColor, size: 24),
    );
  }

  String _getBucketGroup(NotificationItem n) {
    if (n.isPinned || n.priority == 'high') return '📌 Pinned';
    if (n.relevanceScore >= 120) return '⭐ Recommended';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);

    if (checkDate == today) return 'Today';
    if (checkDate == yesterday) return 'Yesterday';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            
            // Check for auto-scroll before rendering
            _checkAutoScroll(provider.notifications);

            if (provider.notifications.isEmpty) {
              return Column(
                children: [
                  _buildHeader(provider.unreadCount),
                  Expanded(child: _buildEmptyState()),
                ],
              );
            }

            // Group by Time & Priority
            final grouped = groupBy(provider.notifications, (NotificationItem n) => _getBucketGroup(n));
            final sortedKeys = ['📌 Pinned', '⭐ Recommended', 'Today', 'Yesterday', 'Earlier'].where((k) => grouped.containsKey(k)).toList();

            return Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(provider.unreadCount),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, sectionIndex) {
                          final groupKey = sortedKeys[sectionIndex];
                          final groupItems = grouped[groupKey]!;

                          return _buildSection(groupKey, groupItems, provider, sectionIndex * 10);
                        },
                      ),
                    ),
                  ],
                ),

                // Floating "New Notifications" Pill
                if (_showNewPill)
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _scrollToTop,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('New notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
            ),
          ),
          const Text(
            'Notification Center',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          Opacity(
            opacity: unreadCount > 0 ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount NEW',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _FadeIn(
      delay: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Icon(Icons.notifications_off_outlined, size: 40, color: Color(0xFFCCCCCC)),
            ),
            const SizedBox(height: 24),
            const Text(
              "You're all caught up!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            const Text(
              "No new notifications at the moment.",
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<NotificationItem> items, NotificationProvider provider, int globalIndexOffset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF222222), letterSpacing: 0.5)),
        const SizedBox(height: 16),
        
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(color: Color(0xFFF0F0F0), height: 1),
          itemBuilder: (context, index) {
            // Sort items inside the group by createdAt desc
            final sortedItems = List<NotificationItem>.from(items)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final item = sortedItems[index];

            return _FadeIn(
              delay: (globalIndexOffset + index) * 30, // faster staggered
              child: _buildNotificationItem(item, provider),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationItem item, NotificationProvider provider) {
    // Determine age string precisely
    final now = DateTime.now();
    final diff = now.difference(item.createdAt);
    String ageStr = '';
    if (diff.inMinutes < 60) {
      ageStr = '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      ageStr = '${diff.inHours}h';
    } else {
      ageStr = '${diff.inDays}d';
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart, // iOS style right to left swipe to delete
      onDismissed: (_) {
        _handleDelete(item, provider);
      },
      background: Container(
        color: const Color(0xFFE53935), // Red
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: _InteractiveNotificationItem(
        onTap: () => _handleTap(item, provider),
        onLongPress: () => _showLongPressMenu(item, provider),
        child: Container(
          color: item.isRead ? Colors.transparent : const Color(0xFFFFF9F9), // Slight tint for unread
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Opacity(
            opacity: item.isRead ? 0.6 : 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getIcon(item.type, item.isRead),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(item.title, style: TextStyle(fontSize: 16, fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800, color: const Color(0xFF333333)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (item.isPinned || item.priority == 'high') ...[
                            const SizedBox(width: 8),
                            _buildMiniBadge('IMPORTANT', const Color(0xFFD4AF37)),
                          ] else if (item.relevanceScore >= 120) ...[
                            const SizedBox(width: 8),
                            _buildMiniBadge('RECOMMENDED', const Color(0xFF2196F3)),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: TextStyle(fontSize: 14, color: item.isRead ? const Color(0xFF777777) : const Color(0xFF444444), height: 1.4, fontWeight: item.isRead ? FontWeight.normal : FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(ageStr, style: TextStyle(fontSize: 12, fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold, color: item.isRead ? const Color(0xFF999999) : const Color(0xFFE53935))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(100), width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
    );
  }
}

// ===== FADE IN + SCALE ANIMATION =====
class _FadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _FadeIn({required this.child, this.delay = 0});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ===== INTERACTIVE NOTIFICATION WRAPPER (SCALE DOWN ON TAP) =====
class _InteractiveNotificationItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _InteractiveNotificationItem({
    required this.child,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_InteractiveNotificationItem> createState() => _InteractiveNotificationItemState();
}

class _InteractiveNotificationItemState extends State<_InteractiveNotificationItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
         _controller.reverse();
         widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
