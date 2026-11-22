import 'dart:async';

/// Abstract interface for providing an authentication bearer token.
///
/// Implementations should return the current user's ID token, or null when
/// the user is unauthenticated or the token cannot be obtained.
abstract interface class AuthTokenProvider {
  /// Asynchronously returns the current bearer token (e.g. Firebase ID token),
  /// or null if the user is unauthenticated.
  ///
  /// Pass [forceRefresh] = true to force the Firebase SDK to fetch a new token
  /// from the server even if the cached one has not expired yet.  Use this
  /// after receiving a 401 to ensure the retry carries a fresh credential.
  Future<String?> getBearerToken({bool forceRefresh = false});
}

/// A default token provider that always returns null (unauthenticated).
class AnonymousTokenProvider implements AuthTokenProvider {
  const AnonymousTokenProvider();

  @override
  Future<String?> getBearerToken({bool forceRefresh = false}) async => null;
}
