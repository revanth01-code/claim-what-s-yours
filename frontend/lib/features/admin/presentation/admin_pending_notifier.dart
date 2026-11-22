import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'admin_providers.dart';

/// State of the pending verification queue in Admin Dashboard.
class AdminPendingNotifier extends AsyncNotifier<ScholarshipPage> {
  int _currentPage = 1;
  String _searchQuery = '';

  int get currentPage => _currentPage;
  String get searchQuery => _searchQuery;

  @override
  Future<ScholarshipPage> build() async {
    return _fetch(page: 1);
  }

  Future<ScholarshipPage> _fetch({required int page}) async {
    final repository = ref.read(adminRepositoryProvider);
    return repository.getPendingScholarships(page: page);
  }

  /// Reloads current queue (e.g., after review or refresh).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(page: _currentPage));
  }

  /// Changes page.
  Future<void> goToPage(int page) async {
    if (page == _currentPage) return;
    _currentPage = page;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(page: page));
  }

  /// Updates local search query.
  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
  }

  /// Removes or updates a scholarship in the local list (e.g. after publishing).
  void removeScholarship(String scholarshipId) {
    state.whenData((page) {
      final updated = page.items.where((s) => s.id != scholarshipId).toList();
      state = AsyncValue.data(
        ScholarshipPage(
          items: updated,
          page: page.page,
          pageSize: page.pageSize,
          total: (page.total - 1).clamp(0, 999999),
          totalPages: page.totalPages,
        ),
      );
    });
  }

  /// Replaces or updates a scholarship in the local list (e.g. after verifying source).
  void updateScholarship(Scholarship updated) {
    state.whenData((page) {
      final index = page.items.indexWhere((s) => s.id == updated.id);
      if (index >= 0) {
        final newItems = List<Scholarship>.from(page.items);
        if (updated.isActive) {
          // If published, it's no longer pending!
          newItems.removeAt(index);
        } else {
          newItems[index] = updated;
        }
        state = AsyncValue.data(
          ScholarshipPage(
            items: newItems,
            page: page.page,
            pageSize: page.pageSize,
            total: updated.isActive ? (page.total - 1).clamp(0, 999999) : page.total,
            totalPages: page.totalPages,
          ),
        );
      }
    });
  }
}
