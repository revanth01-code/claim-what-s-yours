/// Central route name constants.
abstract final class RouteNames {
  static const String home = 'home';
  static const String scholarships = 'scholarships';
  static const String scholarshipDetail = 'scholarship-detail';
  static const String profile = 'profile';
  static const String assistant = 'assistant';
  static const String auth = 'auth';
  static const String onboarding = 'onboarding';
  static const String admin = 'admin';
  static const String adminVerification = 'admin-verification';
}

/// Central route path constants.
abstract final class RoutePaths {
  static const String home = '/';
  static const String scholarships = '/scholarships';
  static const String scholarshipDetail = '/scholarships/:id';
  static const String profile = '/profile';
  static const String assistant = '/assistant';
  static const String auth = '/auth';
  static const String onboarding = '/onboarding';
  static const String admin = '/admin';
  static const String adminVerification = '/admin/verify/:id';
}
