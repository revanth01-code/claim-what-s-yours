import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../../../core/network/auth_token_provider.dart';

/// Concrete [AuthTokenProvider] backed by the Firebase Authentication SDK.
///
/// * Returns null when no user is signed in.
/// * On network failure or token refresh error returns null so no stale or
///   corrupt token is attached to outgoing requests.
/// * Never logs token values.
class FirebaseAuthTokenProvider implements AuthTokenProvider {
  FirebaseAuthTokenProvider({fb.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _firebaseAuth;

  @override
  Future<String?> getBearerToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      // Log the error type only — never the token value.
      debugPrint(
        '[FirebaseAuthTokenProvider] Token retrieval error: ${e.runtimeType}',
      );
      return null;
    }
  }
}
