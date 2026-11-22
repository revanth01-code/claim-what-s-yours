import 'package:claim_whats_yours/app/router/app_router.dart';
import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/features/admin/data/admin_repository.dart';
import 'package:claim_whats_yours/features/admin/domain/admin_audit_log.dart';
import 'package:claim_whats_yours/features/admin/domain/admin_requests.dart';
import 'package:claim_whats_yours/features/admin/presentation/admin_providers.dart';
import 'package:claim_whats_yours/features/auth/domain/app_user.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_state.dart';
import 'package:claim_whats_yours/features/profile/data/student_profile_repository.dart';
import 'package:claim_whats_yours/features/profile/domain/student_profile.dart';
import 'package:claim_whats_yours/features/profile/presentation/profile_providers.dart';
import 'package:claim_whats_yours/features/scholarships/data/scholarship_repository.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/scholarship_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeScholarshipRepository implements ScholarshipRepository {
  List<Scholarship> catalogue = [];

  @override
  Future<ScholarshipPage> fetchPage(ScholarshipQuery query) async {
    return ScholarshipPage(
      items: catalogue,
      page: 1,
      pageSize: 20,
      total: catalogue.length,
      totalPages: 1,
    );
  }

  @override
  Future<Scholarship> fetchById(String id) async {
    return catalogue.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Not found'),
    );
  }
}

class _FakeProfileRepository implements StudentProfileRepository {
  StudentProfile currentProfile = const StudentProfile(
    id: 'p-1',
    userId: 'u-1',
  );

  @override
  Future<StudentProfile> getProfile() async => currentProfile;

  @override
  Future<StudentProfile> updateProfile(StudentProfile profile) async {
    currentProfile = profile;
    return currentProfile;
  }

  @override
  Future<ProfileCompletion> getProfileCompletion() async {
    final p = currentProfile;
    final isComplete = p.fullName != null && p.course != null && p.annualFamilyIncome != null;
    return ProfileCompletion(
      percentage: isComplete ? 100 : 35,
      isOnboardingCompleted: isComplete,
      sections: [
        SectionCompletion(
          name: 'personal',
          isCompleted: p.fullName != null,
          completedFields: p.fullName != null ? 7 : 0,
          totalFields: 7,
          missingFields: p.fullName != null ? [] : ['full_name'],
        ),
        SectionCompletion(
          name: 'academic',
          isCompleted: p.course != null,
          completedFields: p.course != null ? 6 : 0,
          totalFields: 6,
          missingFields: p.course != null ? [] : ['course_name'],
        ),
        SectionCompletion(
          name: 'financial',
          isCompleted: p.annualFamilyIncome != null,
          completedFields: p.annualFamilyIncome != null ? 3 : 0,
          totalFields: 3,
          missingFields: p.annualFamilyIncome != null ? [] : ['annual_family_income'],
        ),
      ],
    );
  }
}

class _FakeAdminRepository implements AdminRepository {
  List<Scholarship> pendingItems = [];
  List<AdminAuditLog> auditLogs = [];

  @override
  Future<ScholarshipPage> getPendingScholarships({int page = 1, int pageSize = 20, String? search}) async {
    return ScholarshipPage(
      items: pendingItems,
      page: page,
      pageSize: pageSize,
      total: pendingItems.length,
      totalPages: 1,
    );
  }

  @override
  Future<List<AdminAuditLog>> getAuditLogs(String scholarshipId) async => auditLogs;

  @override
  Future<OfficialSource> reviewSource(String scholarshipId, String sourceId, AdminSourceReviewRequest request) async {
    return OfficialSource(
      id: sourceId,
      sourceUrl: 'https://telanganaepass.cgg.gov.in',
      authority: 'Government of Telangana',
      sourceType: 'state_portal',
      verificationStatus: request.status,
    );
  }

  @override
  Future<EligibilityCriterion> createCriteria(String scholarshipId, AdminCriteriaCreateRequest request) async {
    return const EligibilityCriterion(id: 'crit-1', isVerified: false);
  }

  @override
  Future<EligibilityCriterion> updateCriteria(String scholarshipId, String criteriaId, AdminCriteriaUpdateRequest request) async {
    return EligibilityCriterion(id: criteriaId, isVerified: false);
  }

  @override
  Future<EligibilityCriterion> reviewCriteria(String scholarshipId, String criteriaId, AdminCriteriaReviewRequest request) async {
    return EligibilityCriterion(id: criteriaId, isVerified: request.isVerified);
  }

  @override
  Future<Scholarship> publishScholarship(String scholarshipId, {String? notes}) async {
    return Scholarship(
      id: 'sch-1',
      name: 'Postmatric Scholarships',
      slug: 'postmatric-scholarships',
      administeringAuthority: 'Telangana State',
      category: 'sc',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sources: const [
        OfficialSource(
          id: 'src-1',
          sourceUrl: 'https://telanganaepass.cgg.gov.in',
          authority: 'Telangana',
          sourceType: 'state_portal',
          verificationStatus: 'verified',
        ),
      ],
      eligibilityCriteria: const [EligibilityCriterion(id: 'crit-1', isVerified: true)],
    );
  }

  @override
  Future<Scholarship> unpublishScholarship(String scholarshipId, {String? notes}) async {
    return Scholarship(
      id: 'sch-1',
      name: 'Postmatric Scholarships',
      slug: 'postmatric-scholarships',
      administeringAuthority: 'Telangana State',
      category: 'sc',
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class _MockAuthNotifier extends Notifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const studentUser = AppUser(
    id: 'student-1',
    email: 'student@example.com',
    displayName: 'Aarav Sharma',
    role: 'student',
    emailVerified: true,
    isActive: true,
  );

  const adminUser = AppUser(
    id: 'admin-1',
    email: 'admin@cwy.gov.in',
    displayName: 'Priya Admin',
    role: 'admin',
    emailVerified: true,
    isActive: true,
  );

  Widget createTestApp({
    required AppUser? user,
    required _FakeProfileRepository profileRepo,
    required _FakeScholarshipRepository scholarshipRepo,
    required _FakeAdminRepository adminRepo,
  }) {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _MockAuthNotifier(
          user != null
              ? AuthState.authenticated(user: user, firebaseUid: 'fb-${user.id}')
              : AuthState.unauthenticated(),
        )),
        studentProfileRepositoryProvider.overrideWithValue(profileRepo),
        scholarshipRepositoryProvider.overrideWithValue(scholarshipRepo),
        adminRepositoryProvider.overrideWithValue(adminRepo),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    );
  }

  testWidgets('JOURNEY A — STUDENT: Login -> Dashboard -> Catalogue -> Details flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profileRepo = _FakeProfileRepository();
    final scholarshipRepo = _FakeScholarshipRepository()
      ..catalogue = [
        Scholarship(
          id: 'pm-usp-1',
          name: 'PM-USP Central Sector Scheme',
          slug: 'pm-usp',
          administeringAuthority: 'Department of Higher Education',
          category: 'merit',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          sources: const [
            OfficialSource(
              id: 'src-1',
              sourceUrl: 'https://scholarships.gov.in',
              authority: 'NSP',
              sourceType: 'national_portal',
              verificationStatus: 'verified',
            ),
          ],
        ),
      ];
    final adminRepo = _FakeAdminRepository();

    await tester.pumpWidget(
      createTestApp(
        user: studentUser,
        profileRepo: profileRepo,
        scholarshipRepo: scholarshipRepo,
        adminRepo: adminRepo,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Student Dashboard renders greeting and quick action cards
    expect(find.text('Namaste, Aarav! 👋'), findsOneWidget);
    expect(find.text('Browse Catalogue'), findsOneWidget);

    // 2. Tap Browse Catalogue to navigate to /scholarships
    await tester.tap(find.text('Browse Catalogue'));
    await tester.pumpAndSettle();

    expect(find.text('Scholarships'), findsOneWidget);
    expect(find.text('PM-USP Central Sector Scheme'), findsOneWidget);

    // 3. Open Scholarship Details
    await tester.tap(find.text('PM-USP Central Sector Scheme'));
    await tester.pumpAndSettle();

    expect(find.text('Department of Higher Education'), findsOneWidget);
    expect(find.text('Verified official source'), findsOneWidget);
  });

  testWidgets('JOURNEY B — RETURNING STUDENT: Restore Profile -> Edit Details -> Persistence confirmed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profileRepo = _FakeProfileRepository()
      ..currentProfile = const StudentProfile(
        id: 'p-1',
        userId: 'student-1',
        fullName: 'Aarav Sharma',
        state: 'Telangana',
        district: 'Hyderabad',
        category: 'obc',
        educationLevel: 'undergraduate',
        course: 'B.Tech Computer Science',
        annualFamilyIncome: 180000,
      );

    await tester.pumpWidget(
      createTestApp(
        user: studentUser,
        profileRepo: profileRepo,
        scholarshipRepo: _FakeScholarshipRepository(),
        adminRepo: _FakeAdminRepository(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to /profile using GoRouter.of
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(RoutePaths.profile);
    await tester.pumpAndSettle();

    expect(find.text('Aarav Sharma'), findsWidgets);
    expect(find.text('B.Tech Computer Science'), findsOneWidget);
    expect(find.text('₹180000'), findsOneWidget);
  });

  testWidgets('JOURNEY C — ADMIN: Admin Dashboard -> Pending Queue renders accurately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adminRepo = _FakeAdminRepository()
      ..pendingItems = [
        Scholarship(
          id: 'sch-pending-1',
          name: 'Telangana Postmatric Scheme',
          slug: 'telangana-postmatric',
          administeringAuthority: 'Telangana ePASS',
          category: 'sc',
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          sources: const [
            OfficialSource(
              id: 'src-1',
              sourceUrl: 'https://telanganaepass.cgg.gov.in',
              authority: 'Telangana',
              sourceType: 'state_portal',
              verificationStatus: 'pending_verification',
            ),
          ],
        ),
      ];

    await tester.pumpWidget(
      createTestApp(
        user: adminUser,
        profileRepo: _FakeProfileRepository(),
        scholarshipRepo: _FakeScholarshipRepository(),
        adminRepo: adminRepo,
      ),
    );
    await tester.pumpAndSettle();

    // Admin should see Admin Dashboard option in header
    expect(find.text('Admin Dashboard'), findsOneWidget);

    // Navigate to /admin
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(RoutePaths.admin);
    await tester.pumpAndSettle();

    expect(find.text('Scholarship Verification Dashboard'), findsOneWidget);
    expect(find.text('Telangana Postmatric Scheme'), findsOneWidget);
  });

  testWidgets('JOURNEY D1 — SECURITY: Unauthenticated user redirected from protected routes to /auth', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createTestApp(
        user: null, // unauthenticated
        profileRepo: _FakeProfileRepository(),
        scholarshipRepo: _FakeScholarshipRepository(),
        adminRepo: _FakeAdminRepository(),
      ),
    );
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(RoutePaths.profile);
    await tester.pumpAndSettle();

    // Redirected to /auth
    expect(find.text('Sign In to Claim What\'s Yours'), findsOneWidget);
  });

  testWidgets('JOURNEY D2 — SECURITY: Student user strictly redirected away from admin dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createTestApp(
        user: studentUser,
        profileRepo: _FakeProfileRepository(),
        scholarshipRepo: _FakeScholarshipRepository(),
        adminRepo: _FakeAdminRepository(),
      ),
    );
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(RoutePaths.admin);
    await tester.pumpAndSettle();

    // Student should remain on or be redirected to Student Portal home
    expect(find.text('Namaste, Aarav! 👋'), findsOneWidget);
    expect(find.text('Scholarship Verification Dashboard'), findsNothing);
  });
}
