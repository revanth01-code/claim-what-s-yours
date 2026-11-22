import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/features/admin/data/admin_repository.dart';
import 'package:claim_whats_yours/features/admin/domain/admin_audit_log.dart';
import 'package:claim_whats_yours/features/admin/domain/admin_requests.dart';
import 'package:claim_whats_yours/features/admin/presentation/admin_providers.dart';
import 'package:claim_whats_yours/features/admin/presentation/admin_verification_screen.dart';
import 'package:claim_whats_yours/features/auth/domain/app_user.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_state.dart';
import 'package:claim_whats_yours/features/scholarships/data/scholarship_repository.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/scholarship_providers.dart';

class _FakeScholarshipRepository implements ScholarshipRepository {
  Scholarship? scholarshipToReturn;

  @override
  Future<Scholarship> fetchById(String id) async {
    if (scholarshipToReturn != null) return scholarshipToReturn!;
    throw Exception('Not found');
  }

  @override
  Future<ScholarshipPage> fetchPage(ScholarshipQuery query) {
    throw UnimplementedError();
  }

  @override
  Future<List<Scholarship>> fetchSaved() async => const [];

  @override
  Future<bool> saveScholarship(String id) async => true;

  @override
  Future<bool> unsaveScholarship(String id) async => false;

  @override
  Future<bool> isSaved(String id) async => false;
}

class _FakeAdminRepository implements AdminRepository {
  bool reviewSourceCalled = false;
  bool reviewCriteriaCalled = false;
  bool publishCalled = false;

  @override
  Future<OfficialSource> reviewSource(String scholarshipId, String sourceId, AdminSourceReviewRequest request) async {
    reviewSourceCalled = true;
    return OfficialSource(
      id: sourceId,
      sourceUrl: 'https://example.com',
      title: request.title ?? 'Official Portal',
      authority: request.authority ?? 'Authority',
      sourceType: 'official_portal',
      verificationStatus: request.status,
      documentReference: request.documentReference,
      lastVerifiedAt: DateTime.utc(2026, 1, 2),
      verifiedBy: 'admin-1',
    );
  }

  @override
  Future<EligibilityCriterion> reviewCriteria(String scholarshipId, String criteriaId, AdminCriteriaReviewRequest request) async {
    reviewCriteriaCalled = true;
    return EligibilityCriterion(
      id: criteriaId,
      isVerified: request.isVerified,
    );
  }

  @override
  Future<Scholarship> publishScholarship(String scholarshipId, {String? notes}) async {
    publishCalled = true;
    return Scholarship(
      id: scholarshipId,
      name: 'Published Scholarship',
      slug: 'pub-sch',
      administeringAuthority: 'Authority',
      category: 'merit',
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      sources: const [],
    );
  }

  @override
  Future<EligibilityCriterion> createCriteria(String scholarshipId, AdminCriteriaCreateRequest request) {
    throw UnimplementedError();
  }


  @override
  Future<List<AdminAuditLog>> getAuditLogs(String scholarshipId) async => [];

  @override
  Future<ScholarshipPage> getPendingScholarships({int page = 1, int pageSize = 20, String? search}) {
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
    name: 'National Scholarship Portal Scheme',
    slug: 'nsp-scheme',
    administeringAuthority: 'Ministry of Minority Affairs',
    category: 'merit_cum_means',
    isActive: false,
    academicYears: const [
      AcademicYearAvailability(academicYear: '2026-2027'),
    ],
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
    sources: const [
      OfficialSource(
        id: 'src-1',
        sourceUrl: 'https://scholarships.gov.in',
        title: 'NSP Official',
        authority: 'Ministry of Minority Affairs',
        sourceType: 'official_portal',
        verificationStatus: 'pending_verification',
      ),
    ],
    eligibilityCriteria: const [
      EligibilityCriterion(
        id: 'crit-1',
        minimumAcademicPercentage: '60.0',
        isVerified: false,
      ),
    ],
  );

  Widget createSubject({
    required AdminRepository adminRepo,
    required ScholarshipRepository scholarshipRepo,
  }) {
    return ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(adminRepo),
        scholarshipRepositoryProvider.overrideWithValue(scholarshipRepo),
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
        home: AdminVerificationScreen(scholarshipId: 'sch-1'),
      ),
    );
  }

  group('AdminVerificationScreen', () {
    testWidgets('renders scholarship details, sources, criteria, and publication gate', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeAdminRepo = _FakeAdminRepository();
      final fakeSchRepo = _FakeScholarshipRepository()..scholarshipToReturn = sampleScholarship;

      await tester.pumpWidget(createSubject(
        adminRepo: fakeAdminRepo,
        scholarshipRepo: fakeSchRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('National Scholarship Portal Scheme'), findsAtLeastNWidgets(1));
      expect(find.text('Publication Requirements Gate'), findsOneWidget);
      expect(find.text('Official Sources (1)'), findsOneWidget);
      expect(find.text('Eligibility Criteria (1)'), findsOneWidget);
      expect(find.text('PENDING PUBLICATION'), findsOneWidget);
    });

    testWidgets('approving criteria invokes reviewCriteria', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeAdminRepo = _FakeAdminRepository();
      final fakeSchRepo = _FakeScholarshipRepository()..scholarshipToReturn = sampleScholarship;

      await tester.pumpWidget(createSubject(
        adminRepo: fakeAdminRepo,
        scholarshipRepo: fakeSchRepo,
      ));
      await tester.pumpAndSettle();

      final approveBtn = find.text('Approve Criteria');
      expect(approveBtn, findsOneWidget);

      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(fakeAdminRepo.reviewCriteriaCalled, isTrue);
    });
  });
}
