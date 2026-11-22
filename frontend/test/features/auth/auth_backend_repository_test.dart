import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:claim_whats_yours/core/config/app_config.dart';
import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/auth/data/auth_backend_repository.dart';
import 'package:dio/dio.dart';

import '../../core/api_client_test.dart';

void main() {
  const config = AppConfig(
    appName: 'Test App',
    apiBaseUrl: 'http://localhost:8000/api/v1',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
    isProduction: false,
  );

  group('AuthBackendRepository Tests', () {
    test('successfully fetches and deserializes AppUser', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpAdapter({
        '/auth/me': {
          'id': 'user-123',
          'email': 'student@cwy.org',
          'email_verified': true,
          'display_name': 'Test Student',
          'role': 'student',
          'is_active': true,
        },
      });

      final apiClient = ApiClient(
        config: config,
        tokenProvider: MockTokenProvider('token'),
        customDio: dio,
      );

      final repo = DefaultAuthBackendRepository(apiClient: apiClient);
      final user = await repo.fetchCurrentUser();

      expect(user.id, 'user-123');
      expect(user.email, 'student@cwy.org');
      expect(user.displayName, 'Test Student');
      expect(user.role, 'student');
      expect(user.isActive, isTrue);
    });
  });
}

class _MockHttpAdapter implements HttpClientAdapter {
  _MockHttpAdapter(this.responses);
  final Map<String, dynamic> responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (responses.containsKey(path)) {
      final data = responses[path];
      return ResponseBody.fromString(
        jsonEncode(data),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('{"error": "not found"}', 404);
  }

  @override
  void close({bool force = false}) {}
}
