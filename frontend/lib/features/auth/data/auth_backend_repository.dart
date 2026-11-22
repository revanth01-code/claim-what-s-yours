import '../../../core/network/api_client.dart';
import '../domain/app_user.dart';

/// Abstract contract for backend auth communication.
abstract interface class AuthBackendRepository {
  /// Fetches the currently authenticated application user from `GET /api/v1/auth/me`.
  Future<AppUser> fetchCurrentUser();
}

/// Concrete implementation of [AuthBackendRepository] using [ApiClient].
class DefaultAuthBackendRepository implements AuthBackendRepository {
  DefaultAuthBackendRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<AppUser> fetchCurrentUser() async {
    final response = await apiClient.get<Map<String, dynamic>>('/auth/me');
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from backend /auth/me');
    }
    return AppUser.fromJson(data);
  }
}
