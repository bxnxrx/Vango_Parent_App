import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String driverName;
  final String receiverId; 

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.driverName,
    required this.receiverId, 
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String? _currentUserId =
      Supabase.instance.client.auth.currentUser?.id;

  bool _isSending = false;
  int _prevMessageCount = 0;
  final List<Map<String, dynamic>> _pendingMessages = [];

  // ✨ ADDED: Call _markAsRead as soon as the screen opens
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  // ✨ ADDED: Sets the unread count to 0 in Firestore for this parent
  void _markAsRead() {
    if (_currentUserId != null) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({'unreadCount_$_currentUserId': 0})
          .catchError((e) => debugPrint('Error marking as read: $e'));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  String _messageTimeLabel(Timestamp? ts) {
    if (ts == null) return 'Sending…';
    final dt = ts.toDate().toLocal();
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('dd MMM, HH:mm').format(dt);
  }

  Future<void> _sendMessage() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final pending = {
      'text': text,
      'senderId': _currentUserId,
      'timestamp': null, 
    };
    setState(() => _pendingMessages.add(pending));
    _scrollToBottom();

    try {
      final url = Uri.parse('https://api.vango.lk/api/chat/send'); 

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chatId': widget.chatId,
          'senderId': _currentUserId,
          'receiverId': widget.receiverId,
          'messageText': text,
          'senderName': 'VanGo Parent',
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) setState(() => _pendingMessages.remove(pending));
      } else {
        throw Exception("Backend returned status code ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('ChatScreen._sendMessage error: $e');
      if (mounted) {
        setState(() => _pendingMessages.remove(pending));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message failed to send. Please check your connection.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final inputFillColor = Theme.of(context).colorScheme.surface;

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accentColor.withValues(alpha: isDark ? 0.22 : 0.1),
              child: Text(
                widget.driverName.isNotEmpty
                    ? widget.driverName[0].toUpperCase()
                    : 'D',
                style: AppTypography.label.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driverName,
                  style: AppTypography.label.copyWith(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'VanGo Driver',
                  style: AppTypography.label.copyWith(
                    color: secondaryTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load messages.\nPlease try again.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.length > _prevMessageCount) {
                  _prevMessageCount = docs.length;
                  _scrollToBottom();
                }

                if (docs.isEmpty && _pendingMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.waving_hand_rounded,
                          size: 48,
                          color: secondaryTextColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Say hi to ${widget.driverName}!',
                          style: AppTypography.body.copyWith(
                            color: secondaryTextColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length + _pendingMessages.length,
                  itemBuilder: (context, index) {
                    final isPending = index >= docs.length;

                    final Map<String, dynamic> msgData;
                    if (isPending) {
                      msgData = _pendingMessages[index - docs.length];
                    } else {
                      msgData = docs[index].data() as Map<String, dynamic>;
                    }

                    final isSender = msgData['senderId'] == _currentUserId;
                    final ts = msgData['timestamp'] as Timestamp?;

                    bool showDateChip = false;
                    if (!isPending) {
                      if (index == 0) {
                        showDateChip = true;
                      } else {
                        final prevData =
                            docs[index - 1].data() as Map<String, dynamic>;
                        final prevTs = prevData['timestamp'] as Timestamp?;
                        if (ts != null && prevTs != null) {
                          final curr = ts.toDate().toLocal();
                          final prev = prevTs.toDate().toLocal();
                          showDateChip = curr.day != prev.day ||
                              curr.month != prev.month ||
                              curr.year != prev.year;
                        }
                      }
                    }

                    return Column(
                      children: [
                        if (showDateChip && ts != null)
                          _DateChip(
                            date: ts.toDate().toLocal(),
                            textColor: secondaryTextColor,
                          ),
                        Opacity(
                          opacity: isPending ? 0.55 : 1.0,
                          child: _MessageBubble(
                            text: msgData['text'] as String? ?? '',
                            timeLabel: _messageTimeLabel(ts),
                            isSender: isSender,
                            isDark: isDark,
                            accentColor: accentColor,
                            textColor: textColor ?? AppColors.textPrimary,
                            secondaryTextColor: secondaryTextColor,
                            maxWidth: maxBubbleWidth,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: inputFillColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTypography.body.copyWith(
                          fontSize: 15,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message…',
                          hintStyle: AppTypography.body.copyWith(
                            fontSize: 15,
                            color: secondaryTextColor,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurfaceStrong
                              : AppColors.surfaceStrong,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: _isSending
                          ? null
                          : LinearGradient(
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.75),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isSending ? secondaryTextColor : null,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
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

class _MessageBubble extends StatelessWidget {
  final String text;
  final String timeLabel;
  final bool isSender;
  final bool isDark;
  final Color accentColor;
  final Color textColor;
  final Color secondaryTextColor;
  final double maxWidth;

  const _MessageBubble({
    required this.text,
    required this.timeLabel,
    required this.isSender,
    required this.isDark,
    required this.accentColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(18);
    const sharpRadius = Radius.circular(4);

    final bubbleColor = isSender
        ? accentColor
        : (isDark ? AppColors.darkSurfaceStrong : AppColors.surfaceStrong);

    final bubbleTextColor =
        isSender ? Colors.white : textColor;

    final timeColor = isSender
        ? Colors.white.withValues(alpha: 0.65)
        : secondaryTextColor;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: isSender ? radius : sharpRadius,
            bottomRight: isSender ? sharpRadius : radius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: AppTypography.body.copyWith(
                fontSize: 15,
                color: bubbleTextColor,
                height: 1.4,
              ),
            ),
            if (timeLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: AppTypography.label.copyWith(
                  fontSize: 10,
                  color: timeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final Color textColor;

  const _DateChip({required this.date, required this.textColor});

  String get _label {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: textColor.withValues(alpha: 0.15))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _label,
              style: AppTypography.label.copyWith(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(child: Divider(color: textColor.withValues(alpha: 0.15))),
        ],
      ),
    );
  }
}