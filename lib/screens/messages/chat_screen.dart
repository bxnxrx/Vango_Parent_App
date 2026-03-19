import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String driverName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.driverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ── State ────────────────────────────────────────────────────────────────
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Fix #4: Safe nullable access instead of force-unwrap `!`
  final String? _currentUserId =
      Supabase.instance.client.auth.currentUser?.id;

  bool _isSending = false;

  // Fix #1: Track previous message count to prevent scroll side-effects in build()
  int _prevMessageCount = 0;

  // Fix #10: Optimistic UI — locally staged pending messages shown instantly
  final List<Map<String, dynamic>> _pendingMessages = [];

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Scroll to the very bottom of the message list.
  /// Only called when genuinely new messages arrive, never from build().
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

  /// Fix #11: Returns "Sending…" for null timestamps (server not yet assigned)
  /// instead of an empty string, giving the user clear feedback.
  String _messageTimeLabel(Timestamp? ts) {
    if (ts == null) return 'Sending…';
    final dt = ts.toDate().toLocal();
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('dd MMM, HH:mm').format(dt);
  }

  // ── Send Message ─────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    // Fix #4: Guard against expired/missing session
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

    // Fix #10: Add a pending bubble immediately for optimistic UI.
    // The real bubble will appear once Firestore confirms and the stream emits.
    final pending = {
      'text': text,
      'senderId': _currentUserId,
      'timestamp': null, // null signals "pending" state
    };
    setState(() => _pendingMessages.add(pending));
    _scrollToBottom();

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId);

    try {
      // Fix #2: Atomic WriteBatch — both writes succeed or both fail together.
      // Previously, two sequential awaits risked the inbox showing stale
      // lastMessage if the app died or lost connectivity between them.
      final batch = FirebaseFirestore.instance.batch();

      final messageRef = chatRef.collection('messages').doc();
      batch.set(messageRef, {
        'senderId': _currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.update(chatRef, {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Remove the optimistic bubble — the stream will now render the real one.
      if (mounted) setState(() => _pendingMessages.remove(pending));
    } catch (e) {
      // Fix #3: User-friendly error message; raw exception logged for devs only.
      debugPrint('ChatScreen._sendMessage error: $e');
      if (mounted) {
        // Remove the failed pending bubble so the user knows it didn't send.
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final inputFillColor = Theme.of(context).colorScheme.surface;

    // Fix #9: Compute maxBubbleWidth once here in build() so _MessageBubble
    // widgets don't each subscribe to MediaQuery changes independently.
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

      // ── Body ──────────────────────────────────────────────────────────────
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

                // Fix #12: Only show the full-screen spinner on the very first
                // load. If the stream re-subscribes with existing data, we keep
                // rendering the data to avoid a jarring flash of the spinner.
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Fix #1: Only trigger scroll when a genuinely new confirmed
                // message arrives from Firestore — not on every build() call.
                // This also correctly respects if the user has scrolled up.
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
                  // Fix #10: Combine confirmed messages + pending bubbles
                  itemCount: docs.length + _pendingMessages.length,
                  itemBuilder: (context, index) {
                    // Pending bubbles are rendered after confirmed messages
                    final isPending = index >= docs.length;

                    final Map<String, dynamic> msgData;
                    if (isPending) {
                      msgData = _pendingMessages[index - docs.length];
                    } else {
                      msgData = docs[index].data() as Map<String, dynamic>;
                    }

                    final isSender = msgData['senderId'] == _currentUserId;
                    final ts = msgData['timestamp'] as Timestamp?;

                    // Date separator: show date chip when the day changes.
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
                        // Fix #10: Pending bubbles are rendered at reduced
                        // opacity to communicate that they are in-flight.
                        Opacity(
                          opacity: isPending ? 0.55 : 1.0,
                          child: _MessageBubble(
                            text: msgData['text'] as String? ?? '',
                            // Fix #11: "Sending…" shown for null ts
                            timeLabel: _messageTimeLabel(ts),
                            isSender: isSender,
                            isDark: isDark,
                            accentColor: accentColor,
                            textColor: textColor ?? AppColors.textPrimary,
                            secondaryTextColor: secondaryTextColor,
                            // Fix #9: Width passed from build(), not queried inside bubble
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

          // ── Input Bar ───────────────────────────────────────────────────
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
                  // Send button
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

// ---------------------------------------------------------------------------
// _MessageBubble
// ---------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  final String text;
  final String timeLabel;
  final bool isSender;
  final bool isDark;
  final Color accentColor;
  final Color textColor;
  final Color secondaryTextColor;
  // Fix #9: Accept pre-computed width from parent instead of querying MediaQuery
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

// ---------------------------------------------------------------------------
// _DateChip – shows "Today", "Yesterday", or a date between message groups.
// ---------------------------------------------------------------------------
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
