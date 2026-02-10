import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/message_thread.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';
import 'package:vango_parent_app/widgets/message_thread_tile.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ParentDataService _dataService = ParentDataService.instance;
  List<MessageThread> _threads = const <MessageThread>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final threads = await _dataService.fetchThreads();
      if (!mounted) {
        return;
      }
      setState(() {
        _threads = threads;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _openChat(MessageThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(thread: thread)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text('Unable to load messages', style: AppTypography.title),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GradientButton(label: 'Retry', onPressed: _loadThreads),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          elevation: 0,
          backgroundColor: AppColors.background,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Messages', style: AppTypography.headline.copyWith(fontSize: 20)),
              Text(
                '${_threads.length} conversations',
                style: AppTypography.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final thread = _threads[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MessageThreadTile(
                    thread: thread,
                    onTap: () => _openChat(thread),
                  ),
                );
              },
              childCount: _threads.length,
            ),
          ),
        ),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.thread});

  final MessageThread thread;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ParentDataService _dataService = ParentDataService.instance;
  final TextEditingController _controller = TextEditingController();
  List<Message> _messages = const <Message>[];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await _dataService.fetchMessages(widget.thread.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final body = _controller.text.trim();
    if (body.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    try {
      final message = await _dataService.sendMessage(widget.thread.id, body);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = [..._messages, message];
        _sending = false;
        _controller.clear();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to send message: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.thread.name),
            Text('Route channel', style: AppTypography.body.copyWith(fontSize: 12)),
          ],
        ),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.call))],
      ),
      body: Column(
        children: [
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    Text('Unable to load messages', style: AppTypography.title),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    GradientButton(label: 'Retry', onPressed: _loadMessages),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final align = message.isParent ? Alignment.centerRight : Alignment.centerLeft;
                  final bubbleColor = message.isParent ? AppColors.accent : AppColors.surface;
                  final textColor = message.isParent ? Colors.white : AppColors.textPrimary;

                  return Align(
                    alignment: align,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: message.isParent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(message.body, style: AppTypography.body.copyWith(color: textColor)),
                          const SizedBox(height: 4),
                          Text(
                            message.timeLabel,
                            style: AppTypography.label.copyWith(fontSize: 10, color: textColor.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.attach_file)),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(hintText: 'Send a message'),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
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