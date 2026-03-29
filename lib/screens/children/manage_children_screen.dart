import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/viewmodels/manage_children_viewmodel.dart';
import 'add_child_sheet.dart';

class ManageChildrenScreen extends ConsumerStatefulWidget {
  const ManageChildrenScreen({super.key});

  @override
  ConsumerState<ManageChildrenScreen> createState() =>
      _ManageChildrenScreenState();
}

class _ManageChildrenScreenState extends ConsumerState<ManageChildrenScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(manageChildrenProvider.notifier).loadMore();
    }
  }

  String _getLocalizedError(String key, AppLocalizations l10n) {
    if (key == 'deleteError') return l10n.deleteError;
    return l10n.genericError;
  }

  Future<void> _handleDelete(ChildProfile child, AppLocalizations l10n) async {
    HapticFeedback.heavyImpact();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.removeStudentTitle,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(l10n.removeStudentConfirmation(child.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancelBtn,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.removeBtn),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(manageChildrenProvider.notifier)
          .deleteChild(child.id);
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.studentRemovedSuccess(child.name)),
            backgroundColor: Colors.green.shade800,
          ),
        );
      } else {
        // Safe UI mapped error handling
        final currentError = ref.read(manageChildrenProvider).errorMessageKey;
        if (currentError != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(_getLocalizedError(currentError, l10n)),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _openChildSheet({ChildProfile? existingChild}) async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final state = ref.read(manageChildrenProvider);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
              maxWidth: 800,
            ),
            child: AddChildSheet(
              existingChild: existingChild,
              existingChildren: state.children,
            ),
          ),
        );
      },
    );

    if (result == true) {
      ref.read(manageChildrenProvider.notifier).loadInitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(manageChildrenProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: state.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openChildSheet(),
              label: Text(
                l10n.addStudentBtn,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              icon: const Icon(Icons.add_reaction_outlined),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
      // Overlay Stack enforces security by preventing UI interaction during writes
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                iconTheme: IconThemeData(
                  color: Theme.of(context).iconTheme.color,
                ),
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    l10n.manageChildrenTitle,
                    style: AppTypography.headline.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: _buildBodyContent(state, l10n),
              ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // SECURE INTERACTION BLOCKER
          if (state.isOverlayLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(ManageChildrenState state, AppLocalizations l10n) {
    if (state.isLoading && state.children.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _SkeletonChildCard(),
          childCount: 4,
        ),
      );
    }

    if (state.errorMessageKey != null && state.children.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.connectionErrorTitle,
                style: AppTypography.headline.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getLocalizedError(state.errorMessageKey!, l10n),
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(manageChildrenProvider.notifier).loadInitial(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retryConnectionBtn),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.children.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.face_retouching_natural_rounded,
                size: 80,
                color: AppColors.accent,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.noStudentsAddedTitle,
                style: AppTypography.headline.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  l10n.addChildrenSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildChildCard(state.children[index], l10n),
        childCount: state.children.length,
      ),
    );
  }

  Widget _buildChildCard(ChildProfile child, AppLocalizations l10n) {
    ImageProvider? avatarImage;
    if (child.imageUrl != null && child.imageUrl!.isNotEmpty) {
      avatarImage = CachedNetworkImageProvider(child.imageUrl!);
    }

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openChildSheet(existingChild: child),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.accentLow.withValues(
                        alpha: 0.2,
                      ),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              child.name.isNotEmpty
                                  ? child.name[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: AppTypography.title.copyWith(
                              color: textColor,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.school_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  child.school,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: dividerColor, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openChildSheet(existingChild: child),
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 20,
                        color: AppColors.accent,
                      ),
                      label: Text(
                        l10n.editProfileBtn,
                        style: const TextStyle(color: AppColors.accent),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.accent.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _handleDelete(child, l10n),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      tooltip: l10n.removeTooltip,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(
                          alpha: 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonChildCard extends StatelessWidget {
  const _SkeletonChildCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: CircularProgressIndicator(color: Theme.of(context).dividerColor),
      ),
    );
  }
}
