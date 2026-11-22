import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Values can be supplied at build time or run time via `--dart-define`:
/// - `FIREBASE_API_KEY_WEB` / `FIREBASE_API_KEY_ANDROID`
/// - `FIREBASE_APP_ID_WEB` / `FIREBASE_APP_ID_ANDROID`
/// - `FIREBASE_MESSAGING_SENDER_ID`
/// - `FIREBASE_PROJECT_ID` (defaults to 'claim-what-s-yours')
/// - `FIREBASE_AUTH_DOMAIN`
/// - `FIREBASE_STORAGE_BUCKET`
///
/// Or generated directly using `flutterfire configure`.
class DefaultFirebaseOptions {
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'claim-what-s-yours',
  );

  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'claim-what-s-yours.firebaseapp.com',
  );

  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'claim-what-s-yours.appspot.com',
  );

  /// Validates whether the active platform options have real, non-empty,
  /// non-placeholder credentials.
  static bool get hasValidOptions {
    final opts = currentPlatformOptions;
    if (opts == null) return false;
    if (opts.apiKey.isEmpty || opts.appId.isEmpty) return false;
    // Reject known placeholder IDs
    if (opts.appId.contains('000000000000')) return false;
    return true;
  }

  static FirebaseOptions? get currentPlatformOptions {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return null;
    }
  }

  static FirebaseOptions get web => const FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY_WEB', defaultValue: ''),
    appId: String.fromEnvironment('FIREBASE_APP_ID_WEB', defaultValue: ''),
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain,
    storageBucket: storageBucket,
  );

  static FirebaseOptions get android => const FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_API_KEY_ANDROID',
      defaultValue: '',
    ),
    appId: String.fromEnvironment('FIREBASE_APP_ID_ANDROID', defaultValue: ''),
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}
