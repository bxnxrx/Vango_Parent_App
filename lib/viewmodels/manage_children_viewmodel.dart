import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';

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

// 1. Updated to use the modern 'Notifier' from Riverpod 2.0+
class ManageChildrenNotifier extends Notifier<ManageChildrenState> {
  final ParentDataService _dataService = ParentDataService.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  ManageChildrenState build() {
    // 2. Trigger the initial fetch securely without blocking the UI build
    Future.microtask(() => loadInitial());
    return ManageChildrenState();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final children = await _dataService.fetchChildren();
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
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      _currentPage++;
      // Backend should support pagination (e.g., fetchChildren(page: _currentPage))
      final moreChildren = await _dataService.fetchChildren();

      state = state.copyWith(
        isLoadingMore: false,
        // 3. Fixed Unused Variable: Appended newly fetched children to the existing list
        children: [...state.children, ...moreChildren],
        // 4. Fixed Unused Variable logic: Check if we received a full page to determine if there are more
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
      await _dataService.deleteChild(id);
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

// 5. Updated Provider to match NotifierProvider syntax
final manageChildrenProvider =
    NotifierProvider<ManageChildrenNotifier, ManageChildrenState>(() {
      return ManageChildrenNotifier();
    });
