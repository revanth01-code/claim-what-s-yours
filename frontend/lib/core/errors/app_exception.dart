/// Application-wide base exception hierarchy.
abstract class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Generic unexpected failure.
class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.cause});
}

/// Validation failure.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

/// Configuration failure.
class ConfigurationException extends AppException {
  const ConfigurationException(super.message, {super.cause});
}
