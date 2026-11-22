import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/core/errors/api_exception.dart';
import 'package:claim_whats_yours/features/scholarships/data/scholarship_repository.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/presentation/scholarship_detail_screen.dart';
import 'package:claim_whats_yours/features/scholarships/presentation/scholarships_screen.dart';
import 'package:claim_whats_yours/features/scholarships/scholarship_providers.dart';

/// Hand-written fake repository. Handlers decide each response, and every
/// fetchPage query is recorded.
class _FakeScholarshipRepository implements ScholarshipRepository {
  Future<ScholarshipPage> Function(ScholarshipQuery query)? onFetchPage;
  Future<Scholarship> Function(String id)? onFetchById;
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
    final handler = onFetchById;
    if (handler == null) {
      throw StateError('fetchById called without a configured response.');
    }
    return handler(id);
  }
}

Scholarship _scholarship({
  String id = '3fa85f64-5717-4562-b3fc-2c963f66afa6',
  String name = 'National Merit Scholarship',
  List<OfficialSource> sources = const [],
}) {
  return Scholarship(
    id: id,
    name: name,
    slug: 'national-merit-scholarship',
    administeringAuthority: 'Ministry of Education',
    category: 'merit',
    isActive: true,
    createdAt: DateTime.utc(2025, 1, 1),
    updatedAt: DateTime.utc(2025, 1, 2),
    sources: sources,
  );
}

ScholarshipPage _page(List<Scholarship> items) {
  return ScholarshipPage(
    items: items,
    page: 1,
    pageSize: 20,
    total: items.length,
    totalPages: 1,
  );
}

Future<void> _pumpListScreen(
  WidgetTester tester,
  _FakeScholarshipRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [scholarshipRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: ScholarshipsScreen()),
    ),
  );
  // Let the fake's immediate future resolve and the state rebuild.
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpDetailScreen(
  WidgetTester tester,
  _FakeScholarshipRepository repo,
  String id,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [scholarshipRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: ScholarshipDetailScreen(scholarshipId: id)),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('ScholarshipsScreen', () {
    testWidgets('shows a loading indicator while the first page is pending', (
      tester,
    ) async {
      final pending = Completer<ScholarshipPage>();
      final repo = _FakeScholarshipRepository()
        ..onFetchPage = (_) => pending.future;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [scholarshipRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: ScholarshipsScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('National Merit Scholarship'), findsNothing);
    });

    testWidgets('shows the scholarship card name after the load completes', (
      tester,
    ) async {
      final repo = _FakeScholarshipRepository()
        ..onFetchPage = (_) async => _page([_scholarship()]);

      await _pumpListScreen(tester, repo);

      expect(repo.pageQueries, hasLength(1));
      expect(find.text('National Merit Scholarship'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'shows the empty catalogue message when there are no items and no filters',
      (tester) async {
        final repo = _FakeScholarshipRepository()
          ..onFetchPage = (_) async => _page(const []);

        await _pumpListScreen(tester, repo);

        expect(find.text('No scholarships are available yet.'), findsOneWidget);
        expect(find.textContaining('No scholarships match'), findsNothing);
      },
    );

    testWidgets('error state shows Try again and tapping it fetches again', (
      tester,
    ) async {
      var calls = 0;
      final repo = _FakeScholarshipRepository()
        ..onFetchPage = (_) async {
          calls++;
          if (calls == 1) {
            throw const ServerException(
              'Server is unavailable.',
              statusCode: 503,
            );
          }
          return _page([_scholarship()]);
        };

      await _pumpListScreen(tester, repo);

      expect(find.text('Could not load scholarships'), findsOneWidget);
      expect(find.text('Server is unavailable.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(repo.pageQueries, hasLength(1));

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();

      expect(repo.pageQueries, hasLength(2));
      expect(find.text('National Merit Scholarship'), findsOneWidget);
      expect(find.text('Could not load scholarships'), findsNothing);
    });

    testWidgets('a search that returns zero items shows the no-match message', (
      tester,
    ) async {
      final repo = _FakeScholarshipRepository()
        ..onFetchPage = (query) async {
          return query.search == null
              ? _page([_scholarship()])
              : _page(const []);
        };

      await _pumpListScreen(tester, repo);
      expect(find.text('National Merit Scholarship'), findsOneWidget);

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'zzz-no-match');
      // Past the 400 ms debounce window.
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      await tester.pump();

      expect(repo.pageQueries.last.search, 'zzz-no-match');
      expect(find.textContaining('No scholarships match'), findsOneWidget);
      expect(find.text('National Merit Scholarship'), findsNothing);
    });
  });

  group('ScholarshipDetailScreen', () {
    testWidgets(
      'shows the name and the verified-source line for a verified scholarship',
      (tester) async {
        final verified = _scholarship(
          sources: const [
            OfficialSource(
              id: '9e107d9d-372b-4bd0-9d4b-8f6e2a1c5b7d',
              sourceUrl: 'https://example.gov/gazette/114',
              authority: 'Ministry of Education',
              sourceType: 'gazette',
              verificationStatus: 'verified',
            ),
          ],
        );
        final repo = _FakeScholarshipRepository()
          ..onFetchById = (id) async => verified;

        await _pumpDetailScreen(tester, repo, verified.id);

        expect(find.text('National Merit Scholarship'), findsWidgets);
        expect(find.text('Verified official source'), findsOneWidget);
        expect(
          find.textContaining('Official verification not shown'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'shows the not-shown verification line when no source is verified',
      (tester) async {
        final unverified = _scholarship();
        final repo = _FakeScholarshipRepository()
          ..onFetchById = (id) async => unverified;

        await _pumpDetailScreen(tester, repo, unverified.id);

        expect(find.text('National Merit Scholarship'), findsWidgets);
        expect(
          find.textContaining('Official verification not shown'),
          findsOneWidget,
        );
        expect(find.text('Verified official source'), findsNothing);
      },
    );
  });
}
