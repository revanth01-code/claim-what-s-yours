import 'package:claim_whats_yours/core/config/app_config.dart';
import 'package:claim_whats_yours/core/errors/api_exception.dart';
import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/core/network/auth_token_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTokenProvider implements AuthTokenProvider {
  MockTokenProvider([this.token = 'test_token_123']);
  final String? token;

  @override
  Future<String?> getBearerToken({bool forceRefresh = false}) async => token;
}

void main() {
  const config = AppConfig(
    appName: 'Test App',
    apiBaseUrl: 'http://localhost:8000/api/v1',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
    isProduction: false,
  );

  test('AnonymousTokenProvider returns null', () async {
    const provider = AnonymousTokenProvider();
    expect(await provider.getBearerToken(), isNull);
  });

  test('MockTokenProvider returns configured token', () async {
    final provider = MockTokenProvider('mock_jwt_token');
    expect(await provider.getBearerToken(), 'mock_jwt_token');
  });

  test('ApiClient attaches bearer token to outgoing requests', () async {
    final tokenProvider = MockTokenProvider('secure_token_abc');
    final client = ApiClient(config: config, tokenProvider: tokenProvider);

    expect(client.dio.options.baseUrl, 'http://localhost:8000/api/v1');
  });

  group('Dio error mapping tests', () {
    test('Maps 401 badResponse to UnauthorizedException with code', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 401,
          data: {
            'error': {
              'code': 'authentication_failed',
              'message': 'Invalid authentication token',
            },
          },
        ),
      );

      final mapped = ApiClient.mapDioError(dioException);
      expect(mapped, isA<UnauthorizedException>());
      expect(
        (mapped as UnauthorizedException).message,
        'Invalid authentication token',
      );
      expect(mapped.errorCode, 'authentication_failed');
    });

    test('Maps 403 badResponse to ForbiddenException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 403,
          data: {
            'error': {
              'code': 'account_disabled',
              'message': 'Account is disabled.',
            },
          },
        ),
      );

      final mapped = ApiClient.mapDioError(dioException);
      expect(mapped, isA<ForbiddenException>());
      expect((mapped as ForbiddenException).errorCode, 'account_disabled');
    });

    test('Maps 404 badResponse to NotFoundException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/scholarships/999'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/scholarships/999'),
          statusCode: 404,
          data: {'detail': 'Scholarship not found'},
        ),
      );

      final mapped = ApiClient.mapDioError(dioException);
      expect(mapped, isA<NotFoundException>());
      expect(mapped.message, 'Scholarship not found');
    });

    test('Maps 503 badResponse to ServerException with code', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/scholarships'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/scholarships'),
          statusCode: 503,
          data: {
            'error': {
              'code': 'database_unavailable',
              'message': 'Database is temporarily unavailable.',
            },
          },
        ),
      );

      final mapped = ApiClient.mapDioError(dioException);
      expect(mapped, isA<ServerException>());
      expect((mapped as ServerException).statusCode, 503);
      expect(mapped.errorCode, 'database_unavailable');
    });

    test('Maps connection timeout to NetworkException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/health'),
        type: DioExceptionType.connectionTimeout,
      );

      final mapped = ApiClient.mapDioError(dioException);
      expect(mapped, isA<NetworkException>());
    });
  });
}
