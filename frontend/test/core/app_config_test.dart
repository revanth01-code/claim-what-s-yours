import 'package:claim_whats_yours/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'AppConfig returns default values when environment variables are unset',
    () {
      final config = AppConfig.fromEnvironment();

      expect(config.appName, "Claim What's Yours");
      // In flutter_test defaultTargetPlatform is android, giving emulator loopback
      expect(
        config.apiBaseUrl,
        anyOf('http://10.0.2.2:8000/api/v1', 'http://127.0.0.1:8000/api/v1'),
      );
      expect(config.isProduction, isFalse);
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.receiveTimeout, const Duration(seconds: 15));
    },
  );

  test('Custom AppConfig constructor preserves values', () {
    const config = AppConfig(
      appName: 'Custom App',
      apiBaseUrl: 'https://api.example.com',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 8),
      isProduction: true,
    );

    expect(config.appName, 'Custom App');
    expect(config.apiBaseUrl, 'https://api.example.com');
    expect(config.isProduction, isTrue);
    expect(config.connectTimeout, const Duration(seconds: 5));
    expect(config.receiveTimeout, const Duration(seconds: 8));
  });
}
