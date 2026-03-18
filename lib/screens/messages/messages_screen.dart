import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/screens/messages/chat_screen.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Data holder returned by the FutureBuilder for each chat tile.
// ---------------------------------------------------------------------------
class _ChatTileInfo {
  final String driverName;
  final String? childName;

  const _ChatTileInfo({required this.driverName, this.childName});
}

// ---------------------------------------------------------------------------
// MessagesScreen
// ---------------------------------------------------------------------------
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.onOpenDrawer});
  final VoidCallback onOpenDrawer;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Current parent's Supabase Auth ID.
  final String _currentUserId =
      Supabase.instance.client.auth.currentUser!.id;

  // In-memory cache so FutureBuilders don't re-fire on every stream event.
  final Map<String, Future<_ChatTileInfo>> _infoCache = {};

  // -------------------------------------------------------------------------
  // Fetch driver + child info from Supabase for a given driver auth ID.
  // -------------------------------------------------------------------------
  Future<_ChatTileInfo> _fetchChatTileInfo(String driverAuthId) {
    return _infoCache.putIfAbsent(driverAuthId, () async {
      try {
        // 1. Get driver record using supabase_user_id.
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

        // 2. Find a child linked to this driver that belongs to this parent.
        final childRow = await Supabase.instance.client
            .from('children')
            .select('child_name')
            .eq('parent_id', _currentUserId)
            .eq('linked_driver_id', driverDbId)
            .maybeSingle();

        final childName = childRow?['child_name'] as String?;

        return _ChatTileInfo(driverName: driverName, childName: childName);
      } catch (_) {
        return const _ChatTileInfo(driverName: 'VanGo Driver');
      }
    });
  }

  // -------------------------------------------------------------------------
  // Navigate into the ChatScreen.
  // -------------------------------------------------------------------------
  void _openChat(String chatId, String driverName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: chatId, driverName: driverName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
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

          // ── Search Bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(color: secondaryTextColor),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: secondaryTextColor,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Chat List (real-time Firestore stream) ─────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('users', arrayContains: _currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              // Error
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

              // Initial load
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

              // Empty
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(child: _EmptyState());
              }

              // Sort docs by lastMessageTime descending (most recent first)
              final chatDocs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTs = aData['lastMessageTime'] as Timestamp?;
                  final bTs = bData['lastMessageTime'] as Timestamp?;
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs);
                });

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = chatDocs[index];
                      final chatData = doc.data() as Map<String, dynamic>;
                      final chatId = doc.id;

                      // Extract the OTHER user (the driver) from the users array.
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
                            // Show shimmer while the Future resolves
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
                              onTap: () =>
                                  _openChat(chatId, info.driverName),
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
    );
  }
}

// ---------------------------------------------------------------------------
// _ChatTile – the card rendered for each conversation.
// ---------------------------------------------------------------------------
class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chatData;
  final String displayName;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chatData,
    required this.displayName,
    required this.onTap,
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
            // Avatar
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
            // Content
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
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeLabel(
                          chatData['lastMessageTime'] as Timestamp?,
                        ),
                        style: AppTypography.label.copyWith(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: secondaryTextColor,
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

// ---------------------------------------------------------------------------
// Shimmer placeholder tile shown while Supabase resolves driver/child info.
// ---------------------------------------------------------------------------
class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF2A2A3D) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3F3F5A) : const Color(0xFFF5F5F5);

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

// ---------------------------------------------------------------------------
// Empty-state widget when there are no chats.
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
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
