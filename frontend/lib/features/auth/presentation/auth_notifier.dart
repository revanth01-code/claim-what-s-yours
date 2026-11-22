import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_backend_repository.dart';
import '../data/firebase_auth_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_error_mapper.dart';
import '../domain/auth_service.dart';
import 'auth_state.dart';

/// Provider for the AuthService abstraction.
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

/// Provider for the AuthBackendRepository.
final authBackendRepositoryProvider = Provider<AuthBackendRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DefaultAuthBackendRepository(apiClient: apiClient);
});

/// Notifier provider managing authentication state in Riverpod 3+.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Manages auth lifecycle: Firebase sign-in → backend JIT /auth/me → sync.
///
/// ## Concurrency design
/// A monotonically-increasing [_syncGeneration] counter is incremented at the
/// start of every backend sync attempt.  Before writing state, each async
/// operation checks whether its captured generation matches the current value.
/// If another sync has started in the meantime, the stale response is silently
/// discarded.  This prevents:
///   - User A's delayed response overwriting User B's authenticated state.
///   - A delayed stream event authenticating a user who has already logged out.
///   - Two overlapping _syncWithBackend calls racing to set state.
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  late final AuthBackendRepository _backendRepository;
  StreamSubscription<fb.User?>? _authSubscription;

  /// Monotonic counter; incremented every time a backend sync begins.
  /// Any in-flight sync that holds a stale generation is silently dropped.
  int _syncGeneration = 0;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    _backendRepository = ref.watch(authBackendRepositoryProvider);

    _syncGeneration = 0;
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges().listen((fbUser) {
      if (fbUser != null) {
        // Only ignore if actively loading from an explicit in-flight action,
        // but if we are still at initial, stream should drive the restore.
        if (state.status == AuthStatus.loading) return;
        _syncWithBackend(fbUser);
      } else {
        // Firebase signed out — invalidate any in-flight sync and clear state.
        _syncGeneration++;
        state = AuthState.unauthenticated();
      }
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return AuthState.initial();
  }

  // ---------------------------------------------------------------------------
  // Internal backend sync
  // ---------------------------------------------------------------------------

  /// Calls `GET /api/v1/auth/me` and updates state.
  ///
  /// Errors are categorised:
  /// * 401 — invalid token or account not found → hard [AuthStatus.error],
  ///          caller must re-authenticate.
  /// * 403 — account disabled → hard [AuthStatus.error]; also signs out from
  ///          Firebase so the disabled session cannot be reused.
  /// * 503 / network — temporary infrastructure issue → [AuthStatus.backendError]
  ///          so the user can retry without re-authenticating.
  Future<void> _syncWithBackend(fb.User fbUser) async {
    final int generation = ++_syncGeneration;
    state = AuthState.loading(email: fbUser.email);

    AppUser? backendUser;
    String? errorMessage;
    AuthStatus resultStatus = AuthStatus.unauthenticated;
    bool forceSignOut = false;

    try {
      backendUser = await _backendRepository.fetchCurrentUser();
      resultStatus = AuthStatus.authenticated;
    } on UnauthorizedException {
      // 401 — token rejected or user not provisioned → hard failure.
      resultStatus = AuthStatus.error;
      errorMessage =
          'Your session could not be verified. Please sign in again.';
    } on ForbiddenException {
      // 403 — account disabled or access revoked → hard failure + Firebase
      //        sign-out so the user cannot re-use the session.
      resultStatus = AuthStatus.error;
      errorMessage = 'Your account has been disabled. Please contact support.';
      forceSignOut = true;
    } on ServerException catch (e) {
      // 5xx — backend/database temporarily unavailable → soft failure, retry.
      resultStatus = AuthStatus.backendError;
      errorMessage =
          'The server is temporarily unavailable (${e.statusCode}). '
          'Please try again in a moment.';
    } on NetworkException {
      // Network outage → soft failure, retry.
      resultStatus = AuthStatus.backendError;
      errorMessage = 'Could not reach the server. Please check your connection and try again.';
    } catch (e) {
      // Unexpected error → soft failure so we do not force unnecessary re-login.
      resultStatus = AuthStatus.backendError;
      errorMessage = 'An unexpected error occurred. Please try again.';
      debugPrint('[AuthNotifier] Unexpected sync error: ${e.runtimeType}');
    }

    // Discard if a newer sync has superseded this one.
    if (_syncGeneration != generation) return;

    if (forceSignOut) {
      _syncGeneration++; // prevent the sign-out stream event from re-syncing
      try {
        await _authService.signOut();
      } catch (_) {}
    }

    if (resultStatus == AuthStatus.authenticated && backendUser != null) {
      state = AuthState.authenticated(
        user: backendUser,
        firebaseUid: fbUser.uid,
        email: fbUser.email,
      );
    } else if (resultStatus == AuthStatus.backendError) {
      state = AuthState.backendError(
        errorMessage: errorMessage,
        firebaseUid: fbUser.uid,
        email: fbUser.email,
      );
    } else {
      state = AuthState.error(errorMessage: errorMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Retry backend sync using the current Firebase session.
  /// Only meaningful when [state.canRetry] is true.
  Future<void> retryBackendSync() async {
    final current = _authService.currentUser;
    if (current != null) {
      await _syncWithBackend(current);
    } else {
      _syncGeneration++;
      state = AuthState.unauthenticated();
    }
  }

  /// Sign in with Email and Password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _syncGeneration++; // cancel any pending stream-triggered sync
    state = AuthState.loading(email: email);
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _syncWithBackend(user);
      } else {
        _syncGeneration++;
        state = AuthState.error(
          errorMessage: 'Sign in succeeded but user data was unavailable.',
        );
      }
    } catch (e) {
      _syncGeneration++;
      state = AuthState.error(errorMessage: mapFirebaseAuthException(e));
    }
  }

  /// Register with Email, Password, and optional Display Name.
  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _syncGeneration++;
    state = AuthState.loading(email: email);
    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      final user = credential.user;
      if (user != null) {
        await _syncWithBackend(user);
      } else {
        _syncGeneration++;
        state = AuthState.error(
          errorMessage: 'Registration succeeded but user data was unavailable.',
        );
      }
    } catch (e) {
      _syncGeneration++;
      state = AuthState.error(errorMessage: mapFirebaseAuthException(e));
    }
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    _syncGeneration++;
    state = AuthState.loading();
    try {
      final credential = await _authService.signInWithGoogle();
      final user = credential.user;
      if (user != null) {
        await _syncWithBackend(user);
      } else {
        _syncGeneration++;
        state = AuthState.error(
          errorMessage:
              'Google sign-in succeeded but user data was unavailable.',
        );
      }
    } catch (e) {
      _syncGeneration++;
      state = AuthState.error(errorMessage: mapFirebaseAuthException(e));
    }
  }

  /// Sign out from Firebase and Google, clearing all application state.
  Future<void> signOut() async {
    // Invalidate any in-flight sync before signing out.
    _syncGeneration++;
    state = AuthState.loading();
    try {
      await _authService.signOut();
      // Stream will fire null → unauthenticated; set it synchronously as well
      // to avoid a brief window where state is loading after signOut returns.
      state = AuthState.unauthenticated();
    } catch (e) {
      // Even if sign-out throws, clear local state to avoid a stuck session.
      state = AuthState.unauthenticated();
      debugPrint('[AuthNotifier] Sign-out error: ${e.runtimeType}');
    }
  }
}
