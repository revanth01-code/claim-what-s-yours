import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/app/router/app_router.dart';
import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/features/admin/data/admin_repository.dart';
import 'package:claim_whats_yours/features/admin/domain/admin_audit_log.dart';
import 'package:claim_whats_yours/features/admin/domain/admin_requests.dart';
import 'package:claim_whats_yours/features/admin/presentation/admin_providers.dart';
import 'package:claim_whats_yours/features/auth/domain/app_user.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_state.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

class _FakeAdminRepository implements AdminRepository {
  @override
  Future<ScholarshipPage> getPendingScholarships({int page = 1, int pageSize = 20, String? search}) async {
    return const ScholarshipPage(items: [], page: 1, pageSize: 20, total: 0, totalPages: 1);
  }

  @override
  Future<List<AdminAuditLog>> getAuditLogs(String scholarshipId) async => [];

  @override
  Future<EligibilityCriterion> createCriteria(String scholarshipId, AdminCriteriaCreateRequest request) => throw UnimplementedError();


  @override
  Future<Scholarship> publishScholarship(String scholarshipId, {String? notes}) => throw UnimplementedError();

  @override
  Future<EligibilityCriterion> reviewCriteria(String scholarshipId, String criteriaId, AdminCriteriaReviewRequest request) => throw UnimplementedError();

  @override
  Future<OfficialSource> reviewSource(String scholarshipId, String sourceId, AdminSourceReviewRequest request) => throw UnimplementedError();

  @override
  Future<Scholarship> unpublishScholarship(String scholarshipId, {String? notes}) => throw UnimplementedError();

  @override
  Future<EligibilityCriterion> updateCriteria(String scholarshipId, String criteriaId, AdminCriteriaUpdateRequest request) => throw UnimplementedError();
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

  const studentUser = AppUser(
    id: 'student-1',
    email: 'student@cwy.org',
    emailVerified: true,
    displayName: 'Student User',
    role: 'student',
    isActive: true,
  );

  group('Admin Route Guarding and Protection', () {
    testWidgets('unauthenticated user navigating to /admin is redirected to /auth', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(AuthState.unauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RoutePaths.admin);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, equals(RoutePaths.auth));
      expect(
        router.routeInformationProvider.value.uri.queryParameters['from'],
        equals(RoutePaths.admin),
      );
    });

    testWidgets('student navigating to /admin is redirected to home (/)', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthState.authenticated(
                user: studentUser,
                firebaseUid: 'firebase-student',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RoutePaths.admin);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, equals(RoutePaths.home));
    });

    testWidgets('student navigating to /admin/verify/:id is redirected to home (/)', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthState.authenticated(
                user: studentUser,
                firebaseUid: 'firebase-student',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/admin/verify/sch-123');
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, equals(RoutePaths.home));
    });

    testWidgets('admin user can navigate to /admin', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(_FakeAdminRepository()),
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthState.authenticated(
                user: adminUser,
                firebaseUid: 'firebase-admin',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RoutePaths.admin);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, equals(RoutePaths.admin));
    });
  });
}
