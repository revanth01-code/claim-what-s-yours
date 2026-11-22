import 'package:flutter_test/flutter_test.dart';
import 'package:claim_whats_yours/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions Initialization Tests', () {
    test(
      'hasValidOptions returns false when default environment has empty keys',
      () {
        // In default test environment without --dart-define, keys are empty or placeholder
        expect(DefaultFirebaseOptions.hasValidOptions, isFalse);
      },
    );

    test('web options contain default project id', () {
      expect(DefaultFirebaseOptions.web.projectId, 'claim-what-s-yours');
      expect(
        DefaultFirebaseOptions.web.authDomain,
        'claim-what-s-yours.firebaseapp.com',
      );
    });

    test(
      'android options contain default project id without fabricated app id',
      () {
        expect(DefaultFirebaseOptions.android.projectId, 'claim-what-s-yours');
        // Verify no placeholder 000000000000 appId
        expect(DefaultFirebaseOptions.android.appId, isEmpty);
      },
    );
  });
}
