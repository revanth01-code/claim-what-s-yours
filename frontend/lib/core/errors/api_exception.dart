import 'app_exception.dart';

/// Exceptions originating from HTTP and API interactions.
abstract class ApiException extends AppException {
  const ApiException(
    super.message, {
    this.statusCode,
    this.errorCode,
    super.cause,
  });

  final int? statusCode;
  final String? errorCode;
}

/// Network level connectivity failure or timeout.
class NetworkException extends ApiException {
  const NetworkException(
    super.message, {
    super.statusCode,
    super.errorCode,
    super.cause,
  });
}

/// HTTP 401 Unauthorized.
class UnauthorizedException extends ApiException {
  const UnauthorizedException(
    super.message, {
    super.statusCode = 401,
    super.errorCode = 'authentication_failed',
    super.cause,
  });
}

/// HTTP 403 Forbidden / Account disabled.
class ForbiddenException extends ApiException {
  const ForbiddenException(
    super.message, {
    super.statusCode = 403,
    super.errorCode = 'forbidden',
    super.cause,
  });
}

/// HTTP 404 Not Found.
class NotFoundException extends ApiException {
  const NotFoundException(
    super.message, {
    super.statusCode = 404,
    super.errorCode = 'not_found',
    super.cause,
  });
}

/// HTTP 422 Unprocessable Content / Validation failed.
class ApiValidationException extends ApiException {
  const ApiValidationException(
    super.message, {
    super.statusCode = 422,
    super.errorCode = 'validation_error',
    super.cause,
  });
}

/// HTTP 500/502/503/504 Server Error or Database Outage.
class ServerException extends ApiException {
  const ServerException(
    super.message, {
    super.statusCode,
    super.errorCode,
    super.cause,
  });
}

/// Unexpected response format or client-side mapping failure.
class BadResponseException extends ApiException {
  const BadResponseException(
    super.message, {
    super.statusCode,
    super.errorCode,
    super.cause,
  });
}
