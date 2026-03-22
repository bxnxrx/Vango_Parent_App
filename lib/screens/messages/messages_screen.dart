import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/screens/messages/chat_screen.dart';
import 'package:intl/intl.dart';

class _ChatTileInfo {
  final String driverName;
  final String? childName;

  const _ChatTileInfo({required this.driverName, this.childName});
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.onOpenDrawer});
  final VoidCallback onOpenDrawer;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final String? _currentUserId =
      Supabase.instance.client.auth.currentUser?.id;

  final Map<String, Future<_ChatTileInfo>> _infoCache = {};

  Future<_ChatTileInfo> _fetchChatTileInfo(String driverAuthId) {
    return _infoCache.putIfAbsent(driverAuthId, () async {
      if (_currentUserId == null) {
        return const _ChatTileInfo(driverName: 'VanGo Driver');
      }
      try {
        final driverRow = await Supabase.instance.client
            .from('drivers')
            .select('id, first_name, last_name')
            .eq('supabase_user_id', driverAuthId)
            .maybeSingle();

        if (driverRow == null) {
          return const _ChatTileInfo(driverName: 'VanGo Driver');
        }

        final driverName =
            '${driverRow['first_name']} ${driverRow['last_name']}';
        final driverDbId = driverRow['id'];

        final childRow = await Supabase.instance.client
            .from('children')
            .select('child_name')
            .eq('parent_id', _currentUserId!)
            .eq('linked_driver_id', driverDbId)
            .maybeSingle();

        final childName = childRow?['child_name'] as String?;

        return _ChatTileInfo(driverName: driverName, childName: childName);
      } catch (_) {
        return const _ChatTileInfo(driverName: 'VanGo Driver');
      }
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _infoCache.clear());
  }

  void _openChat(String chatId, String driverName, String receiverId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId, 
          driverName: driverName,
          receiverId: receiverId, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'Session expired. Please log in again.',
            style: AppTypography.body.copyWith(color: AppColors.danger),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 80.0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.menu_rounded, color: textColor),
                onPressed: widget.onOpenDrawer,
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  left: 56,
                  bottom: 16,
                  right: 20,
                ),
                centerTitle: false,
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: AppTypography.headline.copyWith(
                        fontSize: 20,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Live conversations',
                      style: AppTypography.body.copyWith(
                        fontSize: 10,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('users', arrayContains: _currentUserId)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error loading chats.\nPlease try again later.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _ShimmerTile(),
                        ),
                        childCount: 4,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyState());
                }

                final chatDocs = snapshot.data!.docs;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = chatDocs[index];
                        final chatData = doc.data() as Map<String, dynamic>;
                        final chatId = doc.id;

                        final users = List<String>.from(
                          (chatData['users'] as List<dynamic>?) ?? [],
                        );
                        final driverAuthId = users.firstWhere(
                          (id) => id != _currentUserId,
                          orElse: () => '',
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FutureBuilder<_ChatTileInfo>(
                            future: _fetchChatTileInfo(driverAuthId),
                            builder: (context, infoSnap) {
                              if (infoSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const _ShimmerTile();
                              }

                              final info = infoSnap.data ??
                                  const _ChatTileInfo(driverName: 'VanGo Driver');

                              final displayName = info.childName != null
                                  ? '${info.driverName} (Driving ${info.childName})'
                                  : info.driverName;

                              return _ChatTile(
                                chatData: chatData,
                                displayName: displayName,
                                currentUserId: _currentUserId!,
                                onTap: () =>
                                    _openChat(chatId, info.driverName, driverAuthId),
                              );
                            },
                          ),
                        );
                      },
                      childCount: chatDocs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chatData;
  final String displayName;
  final VoidCallback onTap;
  final String currentUserId;

  const _ChatTile({
    required this.chatData,
    required this.displayName,
    required this.onTap,
    required this.currentUserId,
  });

  String _timeLabel(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate().toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    final lastMessage = (chatData['lastMessage'] as String?)?.trim();
    final snippet = (lastMessage != null && lastMessage.isNotEmpty)
        ? lastMessage
        : 'No messages yet';

    final initials = displayName.isNotEmpty
        ? displayName.split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';

    // ✅ FIXED: Bulletproof parsing to prevent layout crash
    final rawUnread = chatData['unreadCount_$currentUserId'];
    final unreadCount = (rawUnread is num) ? rawUnread.toInt() : 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: accentColor.withValues(alpha: isDark ? 0.22 : 0.1),
              child: Text(
                initials,
                style: AppTypography.label.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppTypography.label.copyWith(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ✨ WHATSAPP-STYLE ALIGNMENT
                      Column(
                        mainAxisSize: MainAxisSize.min, // Hugs the content tightly
                        crossAxisAlignment: CrossAxisAlignment.end, // Aligns to the far right
                        mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
                        children: [
                          Text(
                            _timeLabel(chatData['lastMessageTime'] as Timestamp?),
                            style: AppTypography.label.copyWith(
                              fontSize: 11,
                              color: unreadCount > 0 ? accentColor : secondaryTextColor,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4), // Very tight gap, just like WhatsApp
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor,
                                // Pill-shape handles "1" or "99+" smoothly
                                borderRadius: BorderRadius.circular(12), 
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              // A tightly bound Column centers the text safely without stretching
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0, // Removes default flutter text margin
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            // Transparent spacer prevents time text from jumping when read
                            const SizedBox(height: 22), 
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: unreadCount > 0 ? textColor : secondaryTextColor,
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
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

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A3D) : const Color(0xFFE0E0E0);
    final highlightColor = isDark ? const Color(0xFF3F3F5A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 26, backgroundColor: Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 11,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: accentColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No conversations yet',
              style: AppTypography.title.copyWith(
                fontSize: 18,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once your driver is linked, your chat will appear here automatically.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}