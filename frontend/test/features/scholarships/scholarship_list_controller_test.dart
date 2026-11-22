import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/core/errors/api_exception.dart';
import 'package:claim_whats_yours/features/scholarships/data/scholarship_repository.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/presentation/scholarship_list_controller.dart';
import 'package:claim_whats_yours/features/scholarships/scholarship_providers.dart';

/// Hand-written fake. Every fetchPage call is recorded; [onFetchPage] decides
/// the response, so tests can control timing with Completers.
class _FakeScholarshipRepository implements ScholarshipRepository {
  Future<ScholarshipPage> Function(ScholarshipQuery query)? onFetchPage;
  final List<ScholarshipQuery> pageQueries = [];

  @override
  Future<ScholarshipPage> fetchPage(ScholarshipQuery query) {
    pageQueries.add(query);
    final handler = onFetchPage;
    if (handler == null) {
      throw StateError('fetchPage called without a configured response.');
    }
    return handler(query);
  }

  @override
  Future<Scholarship> fetchById(String id) {
    throw UnimplementedError(
      'fetchById is not used by the list controller tests.',
    );
  }
}

Scholarship _scholarship(String id, {String? name}) {
  return Scholarship(
    id: id,
    name: name ?? 'Scholarship $id',
    slug: 'slug-$id',
    administeringAuthority: 'Authority',
    category: 'general',
    isActive: true,
    createdAt: DateTime.utc(2025, 1, 1),
    updatedAt: DateTime.utc(2025, 1, 2),
  );
}

ScholarshipPage _page({
  required int page,
  required List<Scholarship> items,
  int totalPages = 1,
}) {
  return ScholarshipPage(
    items: items,
    page: page,
    pageSize: 20,
    total: items.length,
    totalPages: totalPages,
  );
}

void main() {
  late _FakeScholarshipRepository repo;
  late ProviderContainer container;
  late ProviderSubscription<ScholarshipListState> subscription;

  setUp(() {
    repo = _FakeScholarshipRepository();
    container = ProviderContainer(
      overrides: [scholarshipRepositoryProvider.overrideWithValue(repo)],
    );
    // Keep the autoDispose controller alive for the whole test.
    subscription = container.listen(
      scholarshipListControllerProvider,
      (_, _) {},
    );
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  ScholarshipListController controller() =>
      container.read(scholarshipListControllerProvider.notifier);

  ScholarshipListState state() =>
      container.read(scholarshipListControllerProvider);

  group('ScholarshipListController', () {
    test('ensureLoaded loads page 1 and sets status to loaded', () async {
      repo.onFetchPage = (query) async =>
          _page(page: 1, items: [_scholarship('a')], totalPages: 1);

      await controller().ensureLoaded();

      expect(repo.pageQueries, hasLength(1));
      expect(repo.pageQueries.single.page, 1);
      expect(state().status, ScholarshipListStatus.loaded);
      expect(state().items.map((s) => s.id), ['a']);
      expect(state().currentPage, 1);
      expect(state().hasMore, isFalse);
    });

    test(
      'ensureLoaded does not refetch once the first page is loaded',
      () async {
        repo.onFetchPage = (query) async =>
            _page(page: 1, items: [_scholarship('a')]);

        await controller().ensureLoaded();
        await controller().ensureLoaded();

        expect(repo.pageQueries, hasLength(1));
      },
    );

    test('loadMore appends page 2 after page 1', () async {
      repo.onFetchPage = (query) async {
        if (query.page == 1) {
          return _page(page: 1, items: [_scholarship('a')], totalPages: 2);
        }
        return _page(page: 2, items: [_scholarship('b')], totalPages: 2);
      };

      await controller().ensureLoaded();
      await controller().loadMore();

      expect(repo.pageQueries.map((q) => q.page), [1, 2]);
      expect(state().items.map((s) => s.id), ['a', 'b']);
      expect(state().currentPage, 2);
      expect(state().isLoadingMore, isFalse);
      expect(state().hasMore, isFalse);
    });

    test(
      'a second loadMore while the first is in flight does not fetch again',
      () async {
        final page2 = Completer<ScholarshipPage>();
        repo.onFetchPage = (query) {
          if (query.page == 1) {
            return Future.value(
              _page(page: 1, items: [_scholarship('a')], totalPages: 2),
            );
          }
          return page2.future;
        };

        await controller().ensureLoaded();

        final first = controller().loadMore();
        final second = controller().loadMore();

        expect(state().isLoadingMore, isTrue);
        expect(repo.pageQueries.where((q) => q.page == 2), hasLength(1));

        page2.complete(
          _page(page: 2, items: [_scholarship('b')], totalPages: 2),
        );
        await first;
        await second;

        // Page 1 plus exactly one page-2 request.
        expect(repo.pageQueries, hasLength(2));
        expect(state().items.map((s) => s.id), ['a', 'b']);
      },
    );

    test('loadMore does nothing when hasMore is false', () async {
      repo.onFetchPage = (query) async =>
          _page(page: 1, items: [_scholarship('a')], totalPages: 1);

      await controller().ensureLoaded();
      await controller().loadMore();

      expect(state().hasMore, isFalse);
      expect(repo.pageQueries, hasLength(1));
      expect(state().items, hasLength(1));
    });

    test('a stale slower response does not overwrite a newer search', () async {
      final alpha = Completer<ScholarshipPage>();
      final beta = Completer<ScholarshipPage>();
      repo.onFetchPage = (query) {
        return query.search == 'alpha' ? alpha.future : beta.future;
      };

      final firstSearch = controller().setSearch('alpha');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repo.pageQueries.last.search, 'alpha');

      final secondSearch = controller().setSearch('beta');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repo.pageQueries.last.search, 'beta');

      // The newer request finishes first.
      beta.complete(
        _page(page: 1, items: [_scholarship('b', name: 'Beta Scholarship')]),
      );
      await secondSearch;
      expect(state().items.map((s) => s.name), ['Beta Scholarship']);

      // The older request finishes last and must be ignored.
      alpha.complete(
        _page(page: 1, items: [_scholarship('a', name: 'Alpha Scholarship')]),
      );
      await firstSearch;

      expect(state().items.map((s) => s.name), ['Beta Scholarship']);
      expect(state().query.search, 'beta');
    });

    test('retry after a failed first load re-runs the request', () async {
      var calls = 0;
      repo.onFetchPage = (query) {
        calls++;
        if (calls == 1) {
          return Future<ScholarshipPage>.error(
            const ServerException('Server is unavailable.', statusCode: 503),
          );
        }
        return Future.value(_page(page: 1, items: [_scholarship('a')]));
      };

      await controller().ensureLoaded();
      expect(state().status, ScholarshipListStatus.error);
      expect(state().errorMessage, 'Server is unavailable.');
      expect(repo.pageQueries, hasLength(1));

      await controller().retry();

      expect(repo.pageQueries, hasLength(2));
      expect(state().status, ScholarshipListStatus.loaded);
      expect(state().errorMessage, isNull);
      expect(state().items.map((s) => s.id), ['a']);
    });

    test('setCategory resets to page 1 with the new category', () async {
      repo.onFetchPage = (query) async {
        return _page(
          page: query.page,
          items: [
            _scholarship(
              'p${query.page}-${query.category?.wireValue ?? 'all'}',
            ),
          ],
          totalPages: 2,
        );
      };

      await controller().ensureLoaded();
      await controller().loadMore();
      expect(state().currentPage, 2);
      expect(state().items, hasLength(2));

      await controller().setCategory(ScholarshipCategory.sc);

      expect(repo.pageQueries.last.page, 1);
      expect(repo.pageQueries.last.category, ScholarshipCategory.sc);
      expect(state().query.category, ScholarshipCategory.sc);
      expect(state().currentPage, 1);
      expect(state().items.map((s) => s.id), ['p1-sc']);
    });

    test(
      'setSearch called twice within 400 ms results in a single fetchPage call',
      () async {
        repo.onFetchPage = (query) async =>
            _page(page: 1, items: [_scholarship('a')]);

        final first = controller().setSearch('a');
        final second = controller().setSearch('ab');

        // The superseded call completes without fetching.
        await first;

        // Wait past the 400 ms debounce window.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await second;

        expect(repo.pageQueries, hasLength(1));
        expect(repo.pageQueries.single.search, 'ab');
      },
    );
  });
}
