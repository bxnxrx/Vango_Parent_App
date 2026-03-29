import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/repositories/children_repository.dart';

class ManageChildrenState {
  final List<ChildProfile> children;
  final bool isLoading;
  final bool isOverlayLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessageKey;

  ManageChildrenState({
    this.children = const [],
    this.isLoading = true,
    this.isOverlayLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessageKey,
  });

  ManageChildrenState copyWith({
    List<ChildProfile>? children,
    bool? isLoading,
    bool? isOverlayLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return ManageChildrenState(
      children: children ?? this.children,
      isLoading: isLoading ?? this.isLoading,
      isOverlayLoading: isOverlayLoading ?? this.isOverlayLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessageKey: clearError
          ? null
          : (errorMessageKey ?? this.errorMessageKey),
    );
  }
}

class ManageChildrenNotifier extends Notifier<ManageChildrenState> {
  late final ChildrenRepository _repository;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  ManageChildrenState build() {
    _repository = ref.watch(childrenRepositoryProvider);
    Future.microtask(() => loadInitial());
    return ManageChildrenState();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final children = await _repository.fetchChildren(
        page: 1,
        limit: _pageSize,
      );
      state = state.copyWith(
        children: children,
        isLoading: false,
        hasMore: children.length >= _pageSize,
      );
      _currentPage = 1;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to fetch children profiles',
      );
      state = state.copyWith(isLoading: false, errorMessageKey: 'genericError');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      _currentPage++;
      final moreChildren = await _repository.fetchChildren(
        page: _currentPage,
        limit: _pageSize,
      );

      state = state.copyWith(
        isLoadingMore: false,
        children: [...state.children, ...moreChildren],
        hasMore: moreChildren.length >= _pageSize,
      );
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to load paginated children',
      );
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> deleteChild(String id) async {
    state = state.copyWith(isOverlayLoading: true, clearError: true);
    try {
      await _repository.deleteChild(id);
      await _analytics.logEvent(
        name: 'secure_delete_child',
        parameters: {'child_id': id},
      );

      state = state.copyWith(
        isOverlayLoading: false,
        children: state.children.where((c) => c.id != id).toList(),
      );
      return true;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to delete child profile',
      );
      state = state.copyWith(
        isOverlayLoading: false,
        errorMessageKey: 'deleteError',
      );
      return false;
    }
  }
}

final manageChildrenProvider =
    NotifierProvider<ManageChildrenNotifier, ManageChildrenState>(() {
      return ManageChildrenNotifier();
    });
