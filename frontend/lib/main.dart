import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'firebase_options.dart';

// ---------------------------------------------------------------------------
// Firebase initialization state
// ---------------------------------------------------------------------------

/// Describes the outcome of the Firebase initialization attempt.
enum FirebaseInitStatus {
  /// Firebase initialized successfully — normal operation.
  ready,

  /// Required configuration values are missing (e.g. no --dart-define supplied
  /// for Web, or no google-services.json for Android).
  /// The app renders a configuration-error screen instead of starting normally.
  configurationError,

  /// Firebase configuration was present but initialization threw an unexpected
  /// exception.
  initializationFailure,
}

/// Result returned from [_initializeFirebase].
class FirebaseInitResult {
  const FirebaseInitResult({required this.status, this.message});
  final FirebaseInitStatus status;
  final String? message;
}

/// Attempts to initialize Firebase using [DefaultFirebaseOptions].
///
/// Strategy (choose one at build time):
///
/// **Option A — Explicit Dart options via `--dart-define` (preferred for CI/CD):**
/// Supply at least `FIREBASE_API_KEY_WEB` + `FIREBASE_APP_ID_WEB` for Web, or
/// `FIREBASE_API_KEY_ANDROID` + `FIREBASE_APP_ID_ANDROID` for Android.
///
/// **Option B — `google-services.json` / `GoogleService-Info.plist` (native):**
/// For Android, place `google-services.json` at `android/app/google-services.json`,
/// add the Google Services Gradle plugin, and leave the `--dart-define` flags
/// unset.  The plugin bakes the config into the app at build time and
/// `Firebase.initializeApp()` with no options will succeed.
///
/// Never fabricate app IDs — a placeholder ID causes a silent runtime failure.
Future<FirebaseInitResult> _initializeFirebase() async {
  try {
    final options = DefaultFirebaseOptions.currentPlatformOptions;

    if (options != null) {
      // Validate that the options contain real values before calling init.
      if (!DefaultFirebaseOptions.hasValidOptions) {
        return const FirebaseInitResult(
          status: FirebaseInitStatus.configurationError,
          message:
              'Firebase configuration is incomplete.\n\n'
              'Web: run with --dart-define=FIREBASE_API_KEY_WEB="<key>" '
              '--dart-define=FIREBASE_APP_ID_WEB="<appId>".\n\n'
              'Android: place google-services.json in android/app/ and add '
              'the Google Services Gradle plugin.',
        );
      }
      await Firebase.initializeApp(options: options);
    } else if (!kIsWeb) {
      // No explicit Dart options provided; fall back to native google-services
      // config (Option B).  This will throw if google-services.json is absent.
      await Firebase.initializeApp();
    } else {
      // Web with no options — cannot initialize.
      return const FirebaseInitResult(
        status: FirebaseInitStatus.configurationError,
        message:
            'Firebase Web configuration is missing.\n\n'
            'Run with --dart-define=FIREBASE_API_KEY_WEB="<key>" '
            '--dart-define=FIREBASE_APP_ID_WEB="<appId>".',
      );
    }

    return const FirebaseInitResult(status: FirebaseInitStatus.ready);
  } catch (e) {
    // Log the exception type only — never log credentials.
    debugPrint('[Firebase] Initialization failed: ${e.runtimeType}');
    return FirebaseInitResult(
      status: FirebaseInitStatus.initializationFailure,
      message:
          'Firebase failed to initialize (${e.runtimeType}). '
          'Check your Firebase configuration and restart the app.',
    );
  }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseResult = await _initializeFirebase();

  runApp(
    ProviderScope(
      child: firebaseResult.status == FirebaseInitStatus.ready
          ? const ClaimWhatsYoursApp()
          : _FirebaseErrorApp(result: firebaseResult),
    ),
  );
}

// ---------------------------------------------------------------------------
// Error screen shown when Firebase cannot initialize
// ---------------------------------------------------------------------------

class _FirebaseErrorApp extends StatelessWidget {
  const _FirebaseErrorApp({required this.result});

  final FirebaseInitResult result;

  @override
  Widget build(BuildContext context) {
    final isConfig = result.status == FirebaseInitStatus.configurationError;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConfig ? Icons.settings_outlined : Icons.error_outline,
                  size: 64,
                  color: isConfig ? Colors.orange : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  isConfig ? 'Configuration Required' : 'Initialization Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  result.message ?? 'An error occurred.',
                  textAlign: TextAlign.center,
                ),
                if (!isConfig) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      // Re-launch via hot restart is the correct recovery path
                      // in release mode.  In debug, the developer should fix
                      // the configuration and hot-restart.
                    },
                    child: const Text('Restart required'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
