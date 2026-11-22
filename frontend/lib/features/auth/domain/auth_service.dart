import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Abstract interface for authentication service.
/// Decouples authentication logic from UI and enables 100% testability with mocks.
abstract interface class AuthService {
  /// Stream of authentication state changes.
  Stream<fb.User?> authStateChanges();

  /// Current Firebase user if any.
  fb.User? get currentUser;

  /// Sign in with email and password.
  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Register with email and password, setting optional display name.
  Future<fb.UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign in with Google provider.
  Future<fb.UserCredential> signInWithGoogle();

  /// Sign out.
  Future<void> signOut();
}
