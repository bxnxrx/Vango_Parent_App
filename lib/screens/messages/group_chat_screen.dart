import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vango_parent_app/services/backend_client.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  bool _isSending = false;
  bool _isManagingMembers = false;
  int _prevMessageCount = 0;
  List<Map<String, dynamic>> _members = const [];

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (_currentUserId == null) return;

    try {
      final response = await BackendClient.instance
          .get('/api/groups/${widget.groupId}/members') as Map<String, dynamic>;
      final members = List<Map<String, dynamic>>.from(
        (response['members'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

      if (!mounted) return;
      setState(() => _members = members);
    } catch (_) {
      // Non-blocking, chat can still work.
    }
  }

  Future<void> _markAsRead() async {
    if (_currentUserId == null) return;

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'unreadCount_$_currentUserId': 0,
    }).catchError((_) {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _messageTimeLabel(Timestamp? ts) {
    if (ts == null) return 'Sending...';
    return DateFormat('HH:mm').format(ts.toDate().toLocal());
  }

  Future<void> _sendMessage() async {
    if (_currentUserId == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await BackendClient.instance.post('/api/groups/${widget.groupId}/messages', {
        'text': text,
        'senderName': 'VanGo Parent',
      });
      _messageController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message failed to send: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _leaveGroup() async {
    setState(() => _isManagingMembers = true);
    try {
      await BackendClient.instance.post('/api/groups/${widget.groupId}/leave', {});
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You left the group.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not leave group: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isManagingMembers = false);
    }
  }

  Future<void> _openMembersSheet() async {
    await _loadMembers();
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Members',
                  style: AppTypography.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                ..._members.map((member) {
                  final id = member['id']?.toString() ?? '';
                  final name = member['name']?.toString() ?? 'Member';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(name),
                    subtitle: id == _currentUserId ? const Text('You') : null,
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isManagingMembers ? null : _leaveGroup,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Leave Group'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          widget.groupName,
          style: AppTypography.title.copyWith(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openMembersSheet,
            icon: const Icon(Icons.group_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load messages.',
                      style: AppTypography.body.copyWith(color: AppColors.danger),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.length > _prevMessageCount) {
                  _prevMessageCount = docs.length;
                  _scrollToBottom();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No group messages yet.',
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final message = docs[index].data() as Map<String, dynamic>;
                    final isSender = message['senderId'] == _currentUserId;
                    final timestamp = message['timestamp'] as Timestamp?;

                    return Align(
                      alignment:
                          isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSender
                              ? AppColors.accent
                              : (isDark
                                  ? AppColors.darkSurfaceStrong
                                  : AppColors.surfaceStrong),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft:
                                Radius.circular(isSender ? 14 : 4),
                            bottomRight:
                                Radius.circular(isSender ? 4 : 14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isSender
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isSender)
                              Text(
                                (message['senderName'] as String?) ?? 'Member',
                                style: AppTypography.label.copyWith(
                                  fontSize: 11,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (!isSender) const SizedBox(height: 4),
                            Text(
                              (message['text'] as String?) ?? '',
                              style: AppTypography.body.copyWith(
                                color: isSender ? Colors.white : textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _messageTimeLabel(timestamp),
                              style: AppTypography.label.copyWith(
                                fontSize: 10,
                                color: isSender
                                    ? Colors.white70
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a group message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceStrong
                            : AppColors.surfaceStrong,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor:
                        _isSending ? AppColors.textSecondary : AppColors.accent,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
