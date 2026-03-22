import 'package:flutter/material.dart';
import 'package:vango_parent_app/supportbot/supportbot_message.dart';
import 'package:vango_parent_app/supportbot/supportbot_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class SupportbotScreen extends StatefulWidget {
  const SupportbotScreen({super.key});

  @override
  State<SupportbotScreen> createState() => _SupportbotScreenState();
}

class _SupportbotScreenState extends State<SupportbotScreen> {
  final SupportbotService _service = SupportbotService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final String _sessionId;
  late final String _lang;

  bool _isSending = false;
  final List<SupportbotMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _lang = _resolveLanguage();
    _sessionId = 'parent-${DateTime.now().millisecondsSinceEpoch}';
    _messages.add(
      SupportbotMessage(
        id: 'welcome',
        role: 'assistant',
        content: _welcomeFor(_lang),
      ),
    );
  }

  String _resolveLanguage() {
    final languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (languageCode == 'si' || languageCode == 'ta') {
      return languageCode;
    }
    return 'en';
  }

  String _welcomeFor(String lang) {
    if (lang == 'si') {
      return 'à¶†à¶ºà·”à¶¶à·à·€à¶±à·Š! VanGo support bot à¶‘à¶šà¶§ à¶”à¶¶à·€ à·ƒà·à¶¯à¶»à¶ºà·™à¶±à·Š à¶´à·’à·…à·’à¶œà¶±à·’à¶¸à·”.';
    }
    if (lang == 'ta') {
      return 'à®µà®£à®•à¯à®•à®®à¯! VanGo support bot à®‰à®™à¯à®•à®³à¯à®•à¯à®•à¯ à®‰à®¤à®µ à®¤à®¯à®¾à®°à®¾à®• à®‰à®³à¯à®³à®¤à¯.';
    }
    return 'Hi! I am the VanGo support assistant. How can I help you today?';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(
        SupportbotMessage(
          id: 'u-${DateTime.now().microsecondsSinceEpoch}',
          role: 'user',
          content: text,
        ),
      );
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final answer = await _service.sendMessage(
        message: text,
        lang: _lang,
        sessionId: _sessionId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(
          SupportbotMessage(
            id: 'a-${DateTime.now().microsecondsSinceEpoch}',
            role: 'assistant',
            content: answer,
          ),
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(
          const SupportbotMessage(
            id: 'fallback',
            role: 'assistant',
            content:
                'Support is currently unavailable. Please try again shortly.',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        toolbarHeight: 72,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'VanGo Support',
              style: AppTypography.title
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Ask in English, Sinhala, or Tamil',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isSending && index == _messages.length) {
                  return const _TypingBubble();
                }

                final msg = _messages[index];
                return _MessageBubble(message: msg);
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type your question...',
                          hintStyle: AppTypography.bodySmall,
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surface
                              : AppColors.surfaceStrong,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isSending ? AppColors.surfaceStrong : AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _isSending ? null : _send,
                      splashRadius: 20,
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
  const _MessageBubble({required this.message});

  final SupportbotMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    final bubbleColor =
        isUser ? AppColors.accent : Theme.of(context).colorScheme.surface;

    final textColor = isUser ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: Text(
          message.content,
          style: AppTypography.bodySmall.copyWith(color: textColor, height: 1.35),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const _TypingDots(),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = AppColors.textSecondary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        double opacityFor(int index) {
          final phase = (t + index * 0.2) % 1;
          return 0.35 + (phase < 0.5 ? phase * 1.3 : (1 - phase) * 1.3);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 4),
              decoration: BoxDecoration(
                color: dotColor.withOpacity(opacityFor(index).clamp(0.25, 1)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
