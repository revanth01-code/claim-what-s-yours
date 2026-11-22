import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claim_whats_yours/core/errors/app_exception.dart';
import 'package:claim_whats_yours/features/scholarships/data/scholarship_json_parser.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/scholarship_providers.dart';

/// User-safe message used when a failure carries no safe message of its own.
const String scholarshipGenericErrorMessage =
    'Something unexpected happened. Please try again.';

/// Delay between the last search keystroke and the search request.
const Duration _searchDebounce = Duration(milliseconds: 400);

/// Load state of the first page of the catalogue.
enum ScholarshipListStatus { initial, loading, loaded, error }

/// Immutable state of the scholarship catalogue list.
///
/// [errorMessage] and [loadMoreErrorMessage] are user-safe strings only. They
/// never contain technical details, stack traces or response bodies.
class ScholarshipListState {
  const ScholarshipListState({
    this.query = const ScholarshipQuery(),
    this.items = const [],
    this.total,
    this.currentPage = 0,
    this.totalPages,
    this.status = ScholarshipListStatus.initial,
    this.isLoadingMore = false,
    this.errorMessage,
    this.loadMoreErrorMessage,
  });

  /// The query used for the loaded items. Its page is the last page requested.
  final ScholarshipQuery query;

  /// Items accumulated from every loaded page, in order.
  final List<Scholarship> items;

  /// Total matching scholarships reported by the backend.
  final int? total;

  /// The last page successfully loaded. Zero before the first load.
  final int currentPage;

  /// Total pages reported by the backend, or null before the first load.
  final int? totalPages;

  /// Status of the first-page load (and refreshes).
  final ScholarshipListStatus status;

  /// True while a next page is being fetched.
  final bool isLoadingMore;

  /// User-safe message for a failed first-page load.
  final String? errorMessage;

  /// User-safe message for a failed next-page load.
  final String? loadMoreErrorMessage;

  /// True when the backend reports further pages after [currentPage].
  bool get hasMore {
    final pages = totalPages;
    return pages != null && currentPage < pages;
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// Pass `clearErrorMessage` or `clearLoadMoreErrorMessage` to remove a
  /// message, since passing null alone keeps the current value.
  ScholarshipListState copyWith({
    ScholarshipQuery? query,
    List<Scholarship>? items,
    int? total,
    int? currentPage,
    int? totalPages,
    ScholarshipListStatus? status,
    bool? isLoadingMore,
    String? errorMessage,
    String? loadMoreErrorMessage,
    bool clearErrorMessage = false,
    bool clearLoadMoreErrorMessage = false,
  }) {
    return ScholarshipListState(
      query: query ?? this.query,
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      status: status ?? this.status,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      loadMoreErrorMessage: clearLoadMoreErrorMessage
          ? null
          : (loadMoreErrorMessage ?? this.loadMoreErrorMessage),
    );
  }
}

/// Owns the catalogue list state: search, filters, sorting and pagination.
///
/// Every request bumps an internal token. A response is applied only when its
/// token is still the latest and the controller has not been disposed, so a
/// slow earlier response can never overwrite a newer query's results.
class ScholarshipListController extends Notifier<ScholarshipListState> {
  Timer? _searchTimer;
  Completer<void>? _pendingSearch;
  int _requestToken = 0;
  bool _disposed = false;

  @override
  ScholarshipListState build() {
    ref.onDispose(() {
      _disposed = true;
      _cancelPendingSearch();
    });
    return const ScholarshipListState();
  }

  /// Loads page 1 when nothing has been loaded yet. Does nothing otherwise.
  Future<void> ensureLoaded() async {
    if (state.status != ScholarshipListStatus.initial) return;
    await _loadFirstPage();
  }

  /// Reloads page 1 with the current query. Existing items stay visible until
  /// the new page arrives.
  Future<void> refresh() => _loadFirstPage();

  /// Sets the search text after a 400 ms pause. The text is trimmed; empty
  /// text clears the search. The returned future completes after the reload
  /// starts (or immediately if this call is superseded by a newer one).
  Future<void> setSearch(String text) {
    _cancelPendingSearch();
    final completer = Completer<void>();
    _pendingSearch = completer;
    final trimmed = text.trim();
    _searchTimer = Timer(_searchDebounce, () {
      _searchTimer = null;
      _pendingSearch = null;
      if (_disposed) {
        completer.complete();
        return;
      }
      final search = trimmed.isEmpty ? null : trimmed;
      if (search == state.query.search) {
        completer.complete();
        return;
      }
      state = state.copyWith(
        query: state.query.copyWith(
          search: search,
          clearSearch: search == null,
        ),
      );
      completer.complete(_loadFirstPage());
    });
    return completer.future;
  }

  /// Sets the category filter (null for all categories) and reloads at once.
  Future<void> setCategory(ScholarshipCategory? category) {
    state = state.copyWith(
      query: state.query.copyWith(
        category: category,
        clearCategory: category == null,
      ),
    );
    return _loadFirstPage();
  }

  /// Sets the sort field and direction and reloads at once.
  Future<void> setSort(
    ScholarshipSortField sortBy,
    ScholarshipSortOrder sortOrder,
  ) {
    state = state.copyWith(
      query: state.query.copyWith(sortBy: sortBy, sortOrder: sortOrder),
    );
    return _loadFirstPage();
  }

  /// Clears the search and category filter immediately and reloads.
  Future<void> clearFilters() {
    _cancelPendingSearch();
    state = state.copyWith(
      query: state.query.copyWith(clearSearch: true, clearCategory: true),
    );
    return _loadFirstPage();
  }

  /// Fetches the next page with the same query and appends its items.
  ///
  /// Returns immediately when a page is already loading, the first page is not
  /// loaded, or no further page exists. This prevents duplicate pagination.
  Future<void> loadMore() async {
    if (_disposed ||
        state.isLoadingMore ||
        state.status != ScholarshipListStatus.loaded ||
        !state.hasMore) {
      return;
    }
    final token = ++_requestToken;
    final query = state.query.copyWith(page: state.currentPage + 1);
    state = state.copyWith(
      isLoadingMore: true,
      clearLoadMoreErrorMessage: true,
    );
    try {
      final page = await ref
          .read(scholarshipRepositoryProvider)
          .fetchPage(query);
      if (!_isCurrent(token)) return;
      state = state.copyWith(
        items: _appendUnique(state.items, page.items),
        total: page.total,
        currentPage: page.page,
        totalPages: page.totalPages,
        isLoadingMore: false,
      );
    } catch (error) {
      if (!_isCurrent(token)) return;
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreErrorMessage: _safeMessage(error),
      );
    }
  }

  /// Retries the last failed request.
  ///
  /// Reloads page 1 when there are no items or the first-page load failed.
  /// Otherwise retries the failed next-page load, if there was one.
  Future<void> retry() {
    if (state.items.isEmpty || state.status == ScholarshipListStatus.error) {
      return refresh();
    }
    if (state.loadMoreErrorMessage != null) {
      return loadMore();
    }
    return Future.value();
  }

  Future<void> _loadFirstPage() async {
    if (_disposed) return;
    final token = ++_requestToken;
    final query = state.query.copyWith(page: 1);
    state = state.copyWith(
      query: query,
      status: ScholarshipListStatus.loading,
      isLoadingMore: false,
      clearErrorMessage: true,
      clearLoadMoreErrorMessage: true,
    );
    try {
      final page = await ref
          .read(scholarshipRepositoryProvider)
          .fetchPage(query);
      if (!_isCurrent(token)) return;
      state = state.copyWith(
        items: page.items,
        total: page.total,
        currentPage: page.page,
        totalPages: page.totalPages,
        status: ScholarshipListStatus.loaded,
      );
    } catch (error) {
      if (!_isCurrent(token)) return;
      state = state.copyWith(
        status: ScholarshipListStatus.error,
        errorMessage: _safeMessage(error),
      );
    }
  }

  bool _isCurrent(int token) => !_disposed && token == _requestToken;

  void _cancelPendingSearch() {
    _searchTimer?.cancel();
    _searchTimer = null;
    final pending = _pendingSearch;
    _pendingSearch = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
  }

  /// Returns only user-safe text. Unknown failures get the generic message.
  String _safeMessage(Object error) {
    if (error is AppException) return error.message;
    if (error is ScholarshipParseException) return error.message;
    return scholarshipGenericErrorMessage;
  }

  List<Scholarship> _appendUnique(
    List<Scholarship> existing,
    List<Scholarship> incoming,
  ) {
    final seenIds = <String>{for (final item in existing) item.id};
    final merged = <Scholarship>[...existing];
    for (final item in incoming) {
      if (seenIds.add(item.id)) merged.add(item);
    }
    return merged;
  }
}

/// Catalogue list state. Auto-disposed so the search timer is cancelled when
/// the screen leaves.
final scholarshipListControllerProvider =
    NotifierProvider.autoDispose<
      ScholarshipListController,
      ScholarshipListState
    >(ScholarshipListController.new);
