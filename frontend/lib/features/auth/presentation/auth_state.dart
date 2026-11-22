import 'package:flutter/foundation.dart';

import '../domain/app_user.dart';

/// Represents the high-level authentication status.
enum AuthStatus {
  /// Determining session on app start.
  initial,

  /// In the middle of an authentication or sync action.
  loading,

  /// Successfully signed in with Firebase and synced with FastAPI backend.
  authenticated,

  /// Signed out or unauthenticated.
  unauthenticated,

  /// Firebase authentication or hard account rejection (401 / 403 / disabled).
  /// User must sign in again.
  error,

  /// Firebase session is valid but backend is temporarily unavailable (503 /
  /// network error). User can retry without re-authenticating.
  backendError,
}

/// Authentication state model.
@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.firebaseUid,
    this.email,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final String? firebaseUid;
  final String? email;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.initial;

  /// True when the user has a valid Firebase session but backend sync failed
  /// temporarily — a retry action should be offered instead of forcing re-login.
  bool get canRetry => status == AuthStatus.backendError;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    String? firebaseUid,
    String? email,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
    );
  }

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.loading({String? email}) =>
      AuthState(status: AuthStatus.loading, email: email);

  factory AuthState.authenticated({
    required AppUser user,
    required String firebaseUid,
    String? email,
  }) => AuthState(
    status: AuthStatus.authenticated,
    user: user,
    firebaseUid: firebaseUid,
    email: email ?? user.email,
  );

  /// Hard auth failure — user must sign in again.
  factory AuthState.error({String? errorMessage}) =>
      AuthState(status: AuthStatus.error, errorMessage: errorMessage);

  /// Signed out cleanly with no error.
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  /// Firebase session valid but backend temporarily unavailable.
  /// Caller preserves [firebaseUid] and [email] so the UI can display context.
  factory AuthState.backendError({
    String? errorMessage,
    String? firebaseUid,
    String? email,
  }) => AuthState(
    status: AuthStatus.backendError,
    errorMessage: errorMessage,
    firebaseUid: firebaseUid,
    email: email,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          errorMessage == other.errorMessage &&
          firebaseUid == other.firebaseUid &&
          email == other.email;

  @override
  int get hashCode =>
      Object.hash(status, user, errorMessage, firebaseUid, email);
}
