import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/features/admin/data/admin_repository.dart';
import 'package:claim_whats_yours/features/admin/domain/admin_audit_log.dart';
import 'package:claim_whats_yours/features/admin/domain/admin_requests.dart';
import 'package:claim_whats_yours/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:claim_whats_yours/features/admin/presentation/admin_providers.dart';
import 'package:claim_whats_yours/features/auth/domain/app_user.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_state.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

class _FakeAdminRepository implements AdminRepository {
  List<Scholarship> pendingItems = [];

  @override
  Future<ScholarshipPage> getPendingScholarships({int page = 1, int pageSize = 20, String? search}) async {
    final filtered = search == null || search.isEmpty
        ? pendingItems
        : pendingItems.where((s) => s.name.toLowerCase().contains(search.toLowerCase())).toList();
    return ScholarshipPage(
      items: filtered,
      total: filtered.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
    );
  }

  @override
  Future<List<AdminAuditLog>> getAuditLogs(String scholarshipId) async => [];

  @override
  Future<EligibilityCriterion> createCriteria(String scholarshipId, AdminCriteriaCreateRequest request) {
    throw UnimplementedError();
  }


  @override
  Future<Scholarship> publishScholarship(String scholarshipId, {String? notes}) {
    throw UnimplementedError();
  }

  @override
  Future<EligibilityCriterion> reviewCriteria(String scholarshipId, String criteriaId, AdminCriteriaReviewRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<OfficialSource> reviewSource(String scholarshipId, String sourceId, AdminSourceReviewRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<Scholarship> unpublishScholarship(String scholarshipId, {String? notes}) {
    throw UnimplementedError();
  }

  @override
  Future<EligibilityCriterion> updateCriteria(String scholarshipId, String criteriaId, AdminCriteriaUpdateRequest request) {
    throw UnimplementedError();
  }
}

class _FakeAuthNotifier extends Notifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const adminUser = AppUser(
    id: 'admin-1',
    email: 'admin@cwy.org',
    emailVerified: true,
    displayName: 'Admin User',
    role: 'admin',
    isActive: true,
  );

  final sampleScholarship = Scholarship(
    id: 'sch-1',
    name: 'National Means Merit Scholarship',
    slug: 'nmms',
    administeringAuthority: 'Ministry of Education',
    category: 'merit_cum_means',
    isActive: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
    sources: const [
      OfficialSource(
        id: 'src-1',
        sourceUrl: 'https://scholarships.gov.in',
        authority: 'Ministry of Education',
        sourceType: 'official_portal',
        verificationStatus: 'pending_verification',
        title: 'NSP Portal',
      ),
    ],
    eligibilityCriteria: const [],
  );

  Widget createSubject(AdminRepository repo) {
    return ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repo),
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            AuthState.authenticated(
              user: adminUser,
              firebaseUid: 'firebase-admin',
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        home: AdminDashboardScreen(),
      ),
    );
  }

  group('AdminDashboardScreen', () {
    testWidgets('renders stats overview and pending table with loaded data', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = _FakeAdminRepository()..pendingItems = [sampleScholarship];

      await tester.pumpWidget(createSubject(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('ADMIN PORTAL'), findsOneWidget);
      expect(find.text('National Means Merit Scholarship'), findsOneWidget);
      expect(find.text('Review & Verify'), findsOneWidget);
      expect(find.text('Pending Queue'), findsOneWidget);
    });

    testWidgets('renders empty queue state when no pending scholarships exist', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = _FakeAdminRepository()..pendingItems = [];

      await tester.pumpWidget(createSubject(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Queue is Clean'), findsOneWidget);
    });

    testWidgets('filters scholarships when typing in search field', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = _FakeAdminRepository()
        ..pendingItems = [
          sampleScholarship,
          Scholarship(
            id: 'sch-2',
            name: 'State Post Matric Scholarship',
            slug: 'state-post-matric',
            administeringAuthority: 'State Govt',
            category: 'post_matric',
            isActive: false,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 2),
            sources: const [],
          ),
        ];

      await tester.pumpWidget(createSubject(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('National Means Merit Scholarship'), findsOneWidget);
      expect(find.text('State Post Matric Scholarship'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'State');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('State Post Matric Scholarship'), findsOneWidget);
      expect(find.text('National Means Merit Scholarship'), findsNothing);
    });
  });
}
