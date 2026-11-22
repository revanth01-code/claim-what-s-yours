import 'package:flutter/foundation.dart';

/// Central application configuration loaded from environment or defaults.
class AppConfig {
  const AppConfig({
    required this.appName,
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.isProduction,
  });

  final String appName;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool isProduction;

  /// Default configuration with compile-time overrides via `--dart-define`.
  ///
  /// Uses `--dart-define=CWY_API_BASE_URL=...` when provided.
  /// When unset:
  /// - Android target platform defaults to `http://10.0.2.2:8000/api/v1` (Android Emulator loopback)
  /// - Web / desktop / local test runner defaults to `http://127.0.0.1:8000/api/v1`
  factory AppConfig.fromEnvironment() {
    const appName = String.fromEnvironment(
      'CWY_APP_NAME',
      defaultValue: "Claim What's Yours",
    );

    const explicitBaseUrl = String.fromEnvironment('CWY_API_BASE_URL');
    final String defaultUrl;
    if (kIsWeb) {
      defaultUrl = 'http://127.0.0.1:8000/api/v1';
    } else {
      // In flutter_test on host, defaultTargetPlatform defaults to android unless overridden
      defaultUrl = defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8000/api/v1'
          : 'http://127.0.0.1:8000/api/v1';
    }

    final apiBaseUrl = explicitBaseUrl.isNotEmpty
        ? explicitBaseUrl
        : defaultUrl;

    const isProd = bool.fromEnvironment('CWY_PRODUCTION', defaultValue: false);
    const connectSeconds = int.fromEnvironment(
      'CWY_CONNECT_TIMEOUT_SECONDS',
      defaultValue: 10,
    );
    const receiveSeconds = int.fromEnvironment(
      'CWY_RECEIVE_TIMEOUT_SECONDS',
      defaultValue: 15,
    );

    return AppConfig(
      appName: appName,
      apiBaseUrl: apiBaseUrl,
      connectTimeout: Duration(seconds: connectSeconds),
      receiveTimeout: Duration(seconds: receiveSeconds),
      isProduction: isProd,
    );
  }
}
