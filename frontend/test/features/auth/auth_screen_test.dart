import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claim_whats_yours/features/auth/presentation/auth_screen.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_state.dart';
import 'package:claim_whats_yours/features/auth/domain/app_user.dart';

import 'auth_notifier_test.dart';

class TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState.unauthenticated();
  }
}

void main() {
  group('AuthScreen UI and Validation', () {
    testWidgets('renders login form by default and validates fields', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockAuth = MockAuthService();
      final mockRepo = MockAuthBackendRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
            authBackendRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(TestAuthNotifier.new),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      // Verify form elements exist
      expect(find.text('Sign In to Claim What\'s Yours'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // email, password
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Don\'t have an account? Register'), findsOneWidget);

      // Find the submit button with key or text
      final submitFinder = find.byKey(const Key('auth_submit_button'));
      expect(submitFinder, findsOneWidget);

      await tester.tap(submitFinder);
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      mockAuth.dispose();
    });

    testWidgets('toggles to registration mode with name and password confirm', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockAuth = MockAuthService();
      final mockRepo = MockAuthBackendRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
            authBackendRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(TestAuthNotifier.new),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      // Tap to toggle mode
      final toggleFinder = find.byKey(const Key('auth_toggle_mode_button'));
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pump();

      expect(find.text('Create Your Account'), findsOneWidget);
      // Now 4 fields: name, email, password, confirm password
      expect(find.byType(TextFormField), findsNWidgets(4));

      // Tap Register with empty fields
      final submitFinder = find.byKey(const Key('auth_submit_button'));
      await tester.tap(submitFinder);
      await tester.pump();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);

      mockAuth.dispose();
    });

    testWidgets('displays user profile card when authenticated', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockAuth = MockAuthService();
      final mockRepo = MockAuthBackendRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
            authBackendRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(
              () => _AuthenticatedTestAuthNotifier(),
            ),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      expect(find.text('My Account'), findsOneWidget);
      expect(find.text('Alice Student'), findsOneWidget);
      expect(find.text('alice@cwy.org'), findsOneWidget);
      expect(find.text('Role: STUDENT'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      mockAuth.dispose();
    });
  });
}

class _AuthenticatedTestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState.authenticated(
      user: const AppUser(
        id: 'alice-uuid',
        email: 'alice@cwy.org',
        emailVerified: true,
        displayName: 'Alice Student',
        role: 'student',
        isActive: true,
      ),
      firebaseUid: 'alice-fb-uid',
    );
  }
}
