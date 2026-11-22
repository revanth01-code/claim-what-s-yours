import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:claim_whats_yours/features/auth/data/firebase_auth_token_provider.dart';

class MockTokenUser implements fb.User {
  MockTokenUser({
    this.tokenToReturn = 'valid_token_xyz',
    this.shouldThrow = false,
  });

  final String tokenToReturn;
  final bool shouldThrow;
  bool lastForceRefresh = false;

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    lastForceRefresh = forceRefresh;
    if (shouldThrow) {
      throw fb.FirebaseAuthException(
        code: 'network-error',
        message: 'Network failed',
      );
    }
    return tokenToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTokenFirebaseAuth implements fb.FirebaseAuth {
  MockTokenFirebaseAuth({this.currentUser});

  @override
  fb.User? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FirebaseAuthTokenProvider Tests', () {
    test('returns null when currentUser is null', () async {
      final mockFb = MockTokenFirebaseAuth(currentUser: null);
      final provider = FirebaseAuthTokenProvider(firebaseAuth: mockFb);

      final token = await provider.getBearerToken();
      expect(token, isNull);
    });

    test('returns bearer token from currentUser', () async {
      final mockUser = MockTokenUser(tokenToReturn: 'jwt_abc_123');
      final mockFb = MockTokenFirebaseAuth(currentUser: mockUser);
      final provider = FirebaseAuthTokenProvider(firebaseAuth: mockFb);

      final token = await provider.getBearerToken();
      expect(token, 'jwt_abc_123');
      expect(mockUser.lastForceRefresh, isFalse);
    });

    test('passes forceRefresh parameter when requested', () async {
      final mockUser = MockTokenUser(tokenToReturn: 'refreshed_jwt');
      final mockFb = MockTokenFirebaseAuth(currentUser: mockUser);
      final provider = FirebaseAuthTokenProvider(firebaseAuth: mockFb);

      final token = await provider.getBearerToken(forceRefresh: true);
      expect(token, 'refreshed_jwt');
      expect(mockUser.lastForceRefresh, isTrue);
    });

    test('returns null when getIdToken throws', () async {
      final mockUser = MockTokenUser(shouldThrow: true);
      final mockFb = MockTokenFirebaseAuth(currentUser: mockUser);
      final provider = FirebaseAuthTokenProvider(firebaseAuth: mockFb);

      final token = await provider.getBearerToken();
      expect(token, isNull);
    });
  });
}
