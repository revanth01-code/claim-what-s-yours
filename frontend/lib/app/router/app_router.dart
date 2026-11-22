import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_verification_screen.dart';
import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/scholarships/presentation/scholarship_detail_screen.dart';
import '../../features/scholarships/presentation/scholarships_screen.dart';
import '../../shared/widgets/app_error.dart';
import 'route_names.dart';

/// Routes that require the user to be authenticated.
const _protectedRoutes = {RoutePaths.profile, RoutePaths.assistant};

/// A [ChangeNotifier] that re-evaluates GoRouter redirect whenever
/// [AuthState] changes.  GoRouter holds a reference to this and calls
/// [GoRouter.refresh] automatically.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(this._ref) {
    // Listen to auth state changes and notify GoRouter to re-run redirect.
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Riverpod provider exposing the configured [GoRouter].
final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthStateListenable(ref);

  final router = GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: false,
    refreshListenable: listenable,

    /// Auth-aware redirect logic.
    ///
    /// Rules:
    /// * While auth state is still resolving (initial / loading), do not
    ///   redirect — wait for the definitive state.
    /// * Unauthenticated users navigating to a protected route are sent to
    ///   /auth.  The [from] query parameter preserves the intended destination
    ///   so a deep link can be restored after sign-in (future enhancement).
    /// * An authenticated user navigating to /auth is sent to home.
    /// * No redirect loop — if the computed redirect target equals the current
    ///   location, return null.
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      // Still resolving — do not redirect yet.
      if (authState.isLoading) return null;

      final isAuthenticated = authState.isAuthenticated;
      final isProtected = _protectedRoutes.contains(location);
      final isAuthRoute = location == RoutePaths.auth;
      final isAdminRoute = location.startsWith(RoutePaths.admin);

      // Admin route protection: must be authenticated and have admin role.
      if (isAdminRoute) {
        if (!isAuthenticated) {
          return '${RoutePaths.auth}?from=${Uri.encodeComponent(location)}';
        }
        final isAdmin = authState.user?.isAdmin ?? false;
        if (!isAdmin) {
          // Students and non-admins are strictly forbidden from admin screens.
          return RoutePaths.home;
        }
        return null;
      }

      if (!isAuthenticated && isProtected) {
        // Redirect unauthenticated users away from protected routes.
        return '${RoutePaths.auth}?from=${Uri.encodeComponent(location)}';
      }

      if (isAuthenticated && isAuthRoute) {
        // Authenticated users do not need to see the sign-in screen.
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          return Uri.decodeComponent(from);
        }
        return RoutePaths.home;
      }

      return null; // No redirect.
    },

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: AppError(
        title: '404 - Page Not Found',
        message: 'The requested route "${state.uri.path}" could not be found.',
        onRetry: () => context.go(RoutePaths.home),
        retryLabel: 'Go to Home',
      ),
    ),

    routes: [
      // Public routes
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.scholarships,
        name: RouteNames.scholarships,
        builder: (context, state) => const ScholarshipsScreen(),
      ),
      GoRoute(
        path: RoutePaths.scholarshipDetail,
        name: RouteNames.scholarshipDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Scholarship')),
              body: const AppError(
                title: 'Could not open scholarship',
                message: 'We could not find that scholarship.',
              ),
            );
          }
          return ScholarshipDetailScreen(scholarshipId: id);
        },
      ),
      GoRoute(
        path: RoutePaths.auth,
        name: RouteNames.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Protected routes — also guarded by redirect above.
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.assistant,
        name: RouteNames.assistant,
        builder: (context, state) => const AssistantScreen(),
      ),

      // Admin routes — guarded by admin role check in redirect above.
      GoRoute(
        path: RoutePaths.admin,
        name: RouteNames.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminVerification,
        name: RouteNames.adminVerification,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Admin Verification')),
              body: const AppError(
                title: 'Invalid scholarship ID',
                message: 'No scholarship ID provided for verification.',
              ),
            );
          }
          return AdminVerificationScreen(scholarshipId: id);
        },
      ),
    ],
  );

  ref.onDispose(listenable.dispose);
  return router;
});
