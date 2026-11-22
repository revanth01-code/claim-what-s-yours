import 'package:dio/dio.dart';

import 'package:claim_whats_yours/core/errors/api_exception.dart';
import 'package:claim_whats_yours/core/network/api_client.dart';
import '../domain/student_profile.dart';
import 'student_profile_repository.dart';

/// Concrete Dio-based implementation of [StudentProfileRepository].
class ApiStudentProfileRepository implements StudentProfileRepository {
  ApiStudentProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<StudentProfile> getProfile() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/students/me/profile');
      final data = response.data;
      if (data == null) {
        throw const ServerException('Malformed response: expected profile object.');
      }
      return StudentProfile.fromJson(data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  @override
  Future<StudentProfile> updateProfile(StudentProfile profile) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/students/me/profile',
        data: profile.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException('Malformed response: expected updated profile object.');
      }
      return StudentProfile.fromJson(data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  @override
  Future<ProfileCompletion> getProfileCompletion() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/students/me/profile/completion');
      final data = response.data;
      if (data == null) {
        return ProfileCompletion.empty();
      }
      return ProfileCompletion.fromJson(data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  Exception _wrapDioError(DioException e) {
    if (e.error is ApiException) {
      return e.error as ApiException;
    }
    return ApiClient.mapDioError(e);
  }
}
