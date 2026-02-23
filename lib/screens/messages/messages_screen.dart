import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/message_thread.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';
import 'package:vango_parent_app/screens/app_shell.dart';
import 'package:vango_parent_app/screens/messages/chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  // We use the function passed from AppShell here
  const MessagesScreen({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

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
      if (!mounted) return;
      setState(() {
        _threads = threads;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _loadThreads);
    }

    return CustomScrollView(
      slivers: [
        // 1. Modern Sticky App Bar WITH Side Nav Trigger
        SliverAppBar(
          floating: true,
          pinned: true,
          expandedHeight: 80.0,
          backgroundColor: AppColors.background,
          elevation: 0,
          // --- Added leading icon for Side Nav ---
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: widget.onOpenDrawer,
          ),
          flexibleSpace: FlexibleSpaceBar(
            // titlePadding adjusted so text doesn't hide behind menu icon
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 20),
            centerTitle: false,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages', 
                  style: AppTypography.headline.copyWith(fontSize: 20)
                ),
                Text(
                  '${_threads.length} conversations',
                  style: AppTypography.body.copyWith(
                    fontSize: 10, 
                    color: AppColors.textSecondary
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),

        // 3. Thread List or Empty State
        _threads.isEmpty
            ? const SliverFillRemaining(child: _EmptyState())
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final thread = _threads[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomMessageTile(
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

// --- Supporting Widgets (Remaining the same but included for completeness) ---

class CustomMessageTile extends StatelessWidget {
  final MessageThread thread;
  final VoidCallback onTap;

  const CustomMessageTile({super.key, required this.thread, required this.onTap});

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
                thread.name.substring(0, 1).toUpperCase(),
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
                      Text(thread.name, style: AppTypography.title),
                      Text('12:45 PM', 
                          style: AppTypography.label.copyWith(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap to view latest updates...",
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
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
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

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Connection Error', style: AppTypography.title),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: AppTypography.body),
            const SizedBox(height: 24),
            GradientButton(label: 'Retry Loading', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}