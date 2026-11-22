import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:claim_whats_yours/features/auth/domain/auth_error_mapper.dart';

void main() {
  group('mapFirebaseAuthException', () {
    test('maps invalid credentials to clear message', () {
      final exc = fb.FirebaseAuthException(code: 'user-not-found');
      expect(
        mapFirebaseAuthException(exc),
        'Invalid email or password. Please try again.',
      );

      final exc2 = fb.FirebaseAuthException(code: 'wrong-password');
      expect(
        mapFirebaseAuthException(exc2),
        'Invalid email or password. Please try again.',
      );
    });

    test('maps email already in use', () {
      final exc = fb.FirebaseAuthException(code: 'email-already-in-use');
      expect(
        mapFirebaseAuthException(exc),
        'An account already exists with this email address.',
      );
    });

    test('maps weak password', () {
      final exc = fb.FirebaseAuthException(code: 'weak-password');
      expect(
        mapFirebaseAuthException(exc),
        'The password provided is too weak. Please use at least 6 characters.',
      );
    });

    test('maps popup cancelled', () {
      final exc = fb.FirebaseAuthException(code: 'popup-closed-by-user');
      expect(mapFirebaseAuthException(exc), 'Sign in was cancelled.');
    });
  });
}
