import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claim_whats_yours/features/auth/domain/app_user.dart';
import 'package:claim_whats_yours/features/auth/domain/auth_service.dart';
import 'package:claim_whats_yours/features/auth/data/auth_backend_repository.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_state.dart';
import 'package:claim_whats_yours/core/errors/api_exception.dart';

class MockUser implements fb.User {
  MockUser({
    this.uid = 'mock-fb-uid',
    this.email = 'student@cwy.org',
    this.displayName = 'Mock Student',
  });

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements fb.UserCredential {
  MockUserCredential({this.user});

  @override
  final fb.User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthService implements AuthService {
  final _controller = StreamController<fb.User?>.broadcast();
  fb.User? _user;
  int signOutCalls = 0;

  @override
  Stream<fb.User?> authStateChanges() => _controller.stream;

  @override
  fb.User? get currentUser => _user;

  void emitUser(fb.User? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = MockUser(email: email);
    _user = user;
    return MockUserCredential(user: user);
  }

  @override
  Future<fb.UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final user = MockUser(email: email, displayName: displayName);
    _user = user;
    return MockUserCredential(user: user);
  }

  @override
  Future<fb.UserCredential> signInWithGoogle() async {
    final user = MockUser(email: 'google@cwy.org', displayName: 'Google User');
    _user = user;
    return MockUserCredential(user: user);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

class MockAuthBackendRepository implements AuthBackendRepository {
  MockAuthBackendRepository({this.userToReturn, this.errorToThrow});

  AppUser? userToReturn;
  Object? errorToThrow;
  int fetchCalls = 0;

  @override
  Future<AppUser> fetchCurrentUser() async {
    fetchCalls++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return userToReturn ??
        const AppUser(
          id: 'mock-id',
          email: 'test@cwy.org',
          emailVerified: true,
          displayName: 'Mock User',
          role: 'student',
          isActive: true,
        );
  }
}

void main() {
  group('AuthNotifier Comprehensive State Tests', () {
    late MockAuthService mockAuthService;
    late MockAuthBackendRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockAuthService = MockAuthService();
      mockRepo = MockAuthBackendRepository();
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          authBackendRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockAuthService.dispose();
    });

    test('initial state is initial on bootstrap', () async {
      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.initial);
    });

    test('signOut resets state to unauthenticated', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signOut();

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
      expect(mockAuthService.signOutCalls, 1);
    });

    test('session restoration via authStateChanges stream', () async {
      container.read(authNotifierProvider); // initialize
      mockAuthService.emitUser(
        MockUser(uid: 'u-123', email: 'restored@cwy.org'),
      );

      // Wait for async stream handling and backend sync
      await Future<void>.delayed(Duration.zero);
      await pumpEventQueue();

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.firebaseUid, 'u-123');
      expect(mockRepo.fetchCalls, 1);
    });

    test('successful email login transitions to authenticated', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithEmail(
        email: 'login@cwy.org',
        password: 'password123',
      );

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.email, 'login@cwy.org');
      expect(state.user?.role, 'student');
    });

    test('successful registration transitions to authenticated', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.registerWithEmail(
        email: 'reg@cwy.org',
        password: 'password123',
        displayName: 'Reg User',
      );

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.email, 'reg@cwy.org');
    });

    test('successful Google sign-in transitions to authenticated', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.email, 'google@cwy.org');
    });

    test(
      'backend 401 transitions to error and does not keep user authenticated',
      () async {
        mockRepo.errorToThrow = const UnauthorizedException('Invalid token');
        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signInWithEmail(
          email: 'login@cwy.org',
          password: 'password123',
        );

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.error);
        expect(state.isAuthenticated, isFalse);
        expect(state.errorMessage, contains('sign in again'));
      },
    );

    test(
      'backend 403 (disabled account) forces sign out and transitions to error',
      () async {
        mockRepo.errorToThrow = const ForbiddenException('Account disabled');
        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signInWithEmail(
          email: 'disabled@cwy.org',
          password: 'password123',
        );

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.error);
        expect(state.isAuthenticated, isFalse);
        expect(state.errorMessage, contains('disabled'));
        expect(mockAuthService.signOutCalls, 1);
      },
    );

    test(
      'backend 503 transitions to backendError and canRetry is true',
      () async {
        mockRepo.errorToThrow = const ServerException(
          'Server error',
          statusCode: 503,
        );
        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signInWithEmail(
          email: 'login@cwy.org',
          password: 'password123',
        );

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.backendError);
        expect(state.canRetry, isTrue);
        expect(state.isAuthenticated, isFalse);
        // User is NOT force signed out on transient 503
        expect(mockAuthService.signOutCalls, 0);
      },
    );

    test('backend retry succeeds after transient 503 failure', () async {
      mockRepo.errorToThrow = const ServerException(
        'Server error',
        statusCode: 503,
      );
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithEmail(
        email: 'login@cwy.org',
        password: 'password123',
      );

      expect(
        container.read(authNotifierProvider).status,
        AuthStatus.backendError,
      );

      // Now clear the error and retry
      mockRepo.errorToThrow = null;
      await notifier.retryBackendSync();

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
    });

    test(
      'logout during pending stream event prevents stale authenticated state',
      () async {
        container.read(authNotifierProvider); // start listener

        // Simulate stream emitting then immediate sign out before async completion
        mockAuthService.emitUser(
          MockUser(uid: 'u-logout', email: 'logout@cwy.org'),
        );
        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signOut();
        await pumpEventQueue();

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.unauthenticated);
        expect(state.isAuthenticated, isFalse);
      },
    );
  });
}
