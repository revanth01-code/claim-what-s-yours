import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

/// Maps raw Firebase Authentication exceptions to clear, user-friendly messages.
///
/// Never exposes raw SDK error strings or internal codes to the user.
/// Logs only the exception type (never the token, password, or key).
String mapFirebaseAuthException(Object error) {
  if (error is fb.FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password provided is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        // User dismissed the Google sign-in popup — not an error.
        return 'Sign in was cancelled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This action requires a recent sign-in. Please sign in again.';
      case 'expired-action-code':
        return 'This link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'This link is invalid. Please request a new one.';
      default:
        // Do NOT use error.message — it can contain project IDs or internal
        // SDK details.  Return a safe generic message instead.
        debugPrint(
          '[AuthErrorMapper] Unhandled FirebaseAuthException code: ${error.code}',
        );
        return 'Authentication failed. Please try again.';
    }
  }
  // Non-Firebase exception: log the type only.
  debugPrint(
    '[AuthErrorMapper] Unexpected auth exception: ${error.runtimeType}',
  );
  return 'An unexpected error occurred. Please try again.';
}
