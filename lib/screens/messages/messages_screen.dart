import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added Supabase
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/screens/messages/chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.onOpenDrawer});
  final VoidCallback onOpenDrawer;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // 1. GET THE REAL LOGGED-IN USER ID
  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  void _openChat(String chatId, String driverName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: chatId, driverName: driverName),
      ),
    );
  }

  // 2. FETCH REAL DRIVER NAME FROM SUPABASE
  Future<String> _getDriverName(String driverAuthId) async {
    try {
      final response = await Supabase.instance.client
          .from('drivers')
          .select('first_name, last_name')
          .eq('supabase_user_id', driverAuthId)
          .maybeSingle();

      if (response != null) {
        return "${response['first_name']} ${response['last_name']}";
      }
      return "VanGo Driver";
    } catch (e) {
      return "VanGo Driver";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 80.0,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
              ),
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
                    style: AppTypography.headline.copyWith(fontSize: 20),
                  ),
                  Text(
                    'Live conversations',
                    style: AppTypography.body.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // STREAM REAL CHATS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('users', arrayContains: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              // Added error handling to catch Firebase permission issues
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text("Error loading chats: ${snapshot.error}"),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(child: _EmptyState());
              }

              final chatDocs = snapshot.data!.docs;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final chatData =
                        chatDocs[index].data() as Map<String, dynamic>;
                    final chatId = chatDocs[index].id;

                    // Find the OTHER user's ID
                    List<dynamic> users = chatData['users'] ?? [];
                    String otherUserId = users.firstWhere(
                      (id) => id != currentUserId,
                      orElse: () => '',
                    );

                    // Build the tile with the real driver's name
                    return FutureBuilder<String>(
                      future: _getDriverName(otherUserId),
                      builder: (context, nameSnapshot) {
                        String driverName = nameSnapshot.data ?? "Loading...";

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomMessageTile(
                            chatData: chatData,
                            driverName: driverName,
                            onTap: () => _openChat(chatId, driverName),
                          ),
                        );
                      },
                    );
                  }, childCount: chatDocs.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ... Keep your CustomMessageTile and _EmptyState exactly the same as before ...
class CustomMessageTile extends StatelessWidget {
  final Map<String, dynamic> chatData;
  final String driverName;
  final VoidCallback onTap;

  const CustomMessageTile({
    super.key,
    required this.chatData,
    required this.driverName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent.withOpacity(0.1),
              child: Text(
                driverName.isNotEmpty
                    ? driverName.substring(0, 1).toUpperCase()
                    : "?",
                style: AppTypography.title.copyWith(color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(driverName, style: AppTypography.title),
                      Text(
                        'Now',
                        style: AppTypography.label.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chatData['lastMessage'] == ""
                        ? "No messages yet"
                        : chatData['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('No conversations yet', style: AppTypography.title),
          Text(
            'Your route updates will appear here.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
