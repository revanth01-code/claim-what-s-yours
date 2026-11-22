import 'package:claim_whats_yours/app/router/app_router.dart';
import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/features/auth/domain/app_user.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUnauthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.unauthenticated();
}

class _FakeAuthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.authenticated(
    user: const AppUser(
      id: 'u-1',
      email: 'test@cwy.org',
      emailVerified: true,
      displayName: 'Test',
      role: 'student',
      isActive: true,
    ),
    firebaseUid: 'fb-1',
  );
}

void main() {
  group('Router Authentication-Aware Redirect Tests', () {
    testWidgets('Public route (home) is accessible without authentication', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              _FakeUnauthenticatedAuthNotifier.new,
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Claim What's Yours"), findsWidgets);
    });

    testWidgets(
      'Unauthenticated user visiting /profile is redirected to /auth',
      (tester) async {
        late BuildContext capturedContext;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                _FakeUnauthenticatedAuthNotifier.new,
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                final router = ref.watch(appRouterProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(capturedContext);
        final router = container.read(appRouterProvider);
        router.go(RoutePaths.profile);
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);
        expect(
          router.routeInformationProvider.value.uri.queryParameters['from'],
          RoutePaths.profile,
        );
      },
    );

    testWidgets(
      'Unauthenticated user visiting /assistant is redirected to /auth',
      (tester) async {
        late BuildContext capturedContext;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                _FakeUnauthenticatedAuthNotifier.new,
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                final router = ref.watch(appRouterProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(capturedContext);
        final router = container.read(appRouterProvider);
        router.go(RoutePaths.assistant);
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, RoutePaths.auth);
        expect(
          router.routeInformationProvider.value.uri.queryParameters['from'],
          RoutePaths.assistant,
        );
      },
    );

    testWidgets(
      'Authenticated user can access /profile directly without redirection',
      (tester) async {
        late BuildContext capturedContext;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                _FakeAuthenticatedAuthNotifier.new,
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                final router = ref.watch(appRouterProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(capturedContext);
        final router = container.read(appRouterProvider);
        router.go(RoutePaths.profile);
        await tester.pumpAndSettle();

        expect(
          router.routeInformationProvider.value.uri.path,
          RoutePaths.profile,
        );
      },
    );

    testWidgets('Authenticated user visiting /auth is redirected to /', (
      tester,
    ) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              _FakeAuthenticatedAuthNotifier.new,
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedContext = context;
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(capturedContext);
      final router = container.read(appRouterProvider);
      router.go(RoutePaths.auth);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, RoutePaths.home);
    });
  });
}
