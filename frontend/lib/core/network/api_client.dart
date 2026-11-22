import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import 'auth_token_provider.dart';
import '../../features/auth/data/firebase_auth_token_provider.dart';

/// Provider for application configuration.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

/// Provider for the authentication token provider.
///
/// Backed by [FirebaseAuthTokenProvider] which requests fresh tokens from Firebase SDK.
final authTokenProvider = Provider<AuthTokenProvider>((ref) {
  return FirebaseAuthTokenProvider();
});

/// Provider for the singleton [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenProvider = ref.watch(authTokenProvider);
  return ApiClient(config: config, tokenProvider: tokenProvider);
});

/// Reusable HTTP client built on Dio with bearer auth and uniform error handling.
///
/// ## 401 retry behaviour
/// When the server returns 401, the client attempts one forced token refresh
/// and retries the original request exactly once.  If the retry also returns
/// 401, an [UnauthorizedException] is thrown.  403 is never retried.
class ApiClient {
  ApiClient({required this.config, required this.tokenProvider, Dio? customDio})
    : _dio = customDio ?? Dio() {
    _configureDio();
  }

  final AppConfig config;
  final AuthTokenProvider tokenProvider;
  final Dio _dio;

  Dio get dio => _dio;

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenProvider.getBearerToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            // Ensure no stale Authorization header persists on unauthenticated requests.
            options.headers.remove('Authorization');
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // On 401, attempt one forced token refresh and retry the request.
          // This handles the common case of an expired ID token being cached
          // by the SDK between calls.
          if (error.response?.statusCode == 401) {
            final retried = await _retryWithFreshToken(error);
            if (retried != null) {
              return handler.resolve(retried);
            }
          }
          final mapped = mapDioError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: mapped,
              message: mapped.message,
            ),
          );
        },
      ),
    );
  }

  /// Performs a forced token refresh and retries [originalError]'s request once.
  /// Returns the successful [Response] or null if the retry also fails.
  Future<Response<dynamic>?> _retryWithFreshToken(
    DioException originalError,
  ) async {
    try {
      final freshToken = await tokenProvider.getBearerToken(forceRefresh: true);
      if (freshToken == null || freshToken.isEmpty) return null;

      final opts = Options(
        method: originalError.requestOptions.method,
        headers: {
          ...originalError.requestOptions.headers,
          'Authorization': 'Bearer $freshToken',
        },
        // Mark the retry so the interceptor does not loop indefinitely.
        extra: {'_isRetry': true},
      );

      // Do not retry if this is already a retry (prevents infinite loops).
      if (originalError.requestOptions.extra['_isRetry'] == true) return null;

      return await _dio.request<dynamic>(
        originalError.requestOptions.path,
        data: originalError.requestOptions.data,
        queryParameters: originalError.requestOptions.queryParameters,
        options: opts,
      );
    } catch (_) {
      return null;
    }
  }

  /// Maps a raw [DioException] to domain-specific [ApiException].
  static ApiException mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(
          'Network connection timed out or failed. Please check your internet connection.',
          cause: error,
        );
      case DioExceptionType.badResponse:
        final response = error.response;
        final statusCode = response?.statusCode;
        String message = 'Request failed with status $statusCode';
        String? errorCode;

        if (response?.data is Map<String, dynamic>) {
          final data = response!.data as Map<String, dynamic>;
          if (data['error'] is Map<String, dynamic>) {
            final errObj = data['error'] as Map<String, dynamic>;
            message = errObj['message']?.toString() ?? message;
            errorCode = errObj['code']?.toString();
          } else if (data['detail'] is String) {
            message = data['detail'] as String;
          }
        }

        if (statusCode == 401) {
          return UnauthorizedException(
            message,
            errorCode: errorCode ?? 'authentication_failed',
            cause: error,
          );
        } else if (statusCode == 403) {
          return ForbiddenException(
            message,
            errorCode: errorCode ?? 'forbidden',
            cause: error,
          );
        } else if (statusCode == 404) {
          return NotFoundException(
            message,
            errorCode: errorCode ?? 'not_found',
            cause: error,
          );
        } else if (statusCode == 422) {
          return ApiValidationException(
            message,
            errorCode: errorCode ?? 'validation_error',
            cause: error,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message,
            statusCode: statusCode,
            errorCode: errorCode ?? 'server_error',
            cause: error,
          );
        }
        return BadResponseException(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
          cause: error,
        );
      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled.');
      case DioExceptionType.unknown:
      default:
        return NetworkException(
          error.message ?? 'An unexpected network error occurred.',
          cause: error,
        );
    }
  }

  /// Perform a GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw mapDioError(e);
    }
  }

  /// Perform a POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw mapDioError(e);
    }
  }

  /// Perform a PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw mapDioError(e);
    }
  }

  /// Perform a PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw mapDioError(e);
    }
  }

  /// Perform a DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw mapDioError(e);
    }
  }
}
