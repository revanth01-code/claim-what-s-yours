import 'package:flutter_test/flutter_test.dart';
import 'package:claim_whats_yours/features/auth/domain/app_user.dart';

void main() {
  group('AppUser domain model', () {
    test('parses from valid JSON', () {
      final json = {
        'id': 'a81bc81b-dead-4e5d-abff-90865d1e13b1',
        'email': 'student@example.com',
        'email_verified': true,
        'display_name': 'Test Student',
        'role': 'student',
        'is_active': true,
      };

      final user = AppUser.fromJson(json);

      expect(user.id, 'a81bc81b-dead-4e5d-abff-90865d1e13b1');
      expect(user.email, 'student@example.com');
      expect(user.emailVerified, isTrue);
      expect(user.displayName, 'Test Student');
      expect(user.role, 'student');
      expect(user.isActive, isTrue);
    });

    test('serializes to JSON correctly', () {
      const user = AppUser(
        id: '123',
        email: 'test@cwy.org',
        emailVerified: false,
        displayName: 'User',
        role: 'student',
        isActive: true,
      );

      final json = user.toJson();

      expect(json['id'], '123');
      expect(json['email'], 'test@cwy.org');
      expect(json['email_verified'], isFalse);
      expect(json['display_name'], 'User');
      expect(json['role'], 'student');
      expect(json['is_active'], isTrue);
    });

    test('equality and hashCode contract', () {
      const user1 = AppUser(
        id: '123',
        email: 'test@cwy.org',
        emailVerified: true,
        displayName: 'User',
        role: 'student',
        isActive: true,
      );
      const user2 = AppUser(
        id: '123',
        email: 'test@cwy.org',
        emailVerified: true,
        displayName: 'User',
        role: 'student',
        isActive: true,
      );

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });
  });
}
