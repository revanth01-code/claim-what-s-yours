import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../scholarships/data/scholarship_json_parser.dart';
import '../../scholarships/domain/scholarship.dart';
import '../domain/admin_audit_log.dart';
import '../domain/admin_requests.dart';
import 'admin_json_parser.dart';
import 'admin_repository.dart';

/// Concrete implementation of [AdminRepository] communicating with FastAPI backend.
class ApiAdminRepository implements AdminRepository {
  ApiAdminRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ScholarshipPage> getPendingScholarships({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/admin/scholarships/pending',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      return parseScholarshipPage(response.data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  @override
  Future<OfficialSource> reviewSource(
    String scholarshipId,
    String sourceId,
    AdminSourceReviewRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/admin/scholarships/$scholarshipId/sources/$sourceId/review',
        data: request.toJson(),
      );
      return parseOfficialSource(response.data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  @override
  Future<EligibilityCriterion> createCriteria(
    String scholarshipId,
    AdminCriteriaCreateRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/admin/scholarships/$scholarshipId/criteria',
        data: request.toJson(),
      );
      return parseEligibilityCriterion(response.data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  @override
  Future<EligibilityCriterion> updateCriteria(
    String scholarshipId,
    String criteriaId,
    AdminCriteriaUpdateRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/admin/scholarships/$scholarshipId/criteria/$criteriaId',
        data: request.toJson(),
      );
      return parseEligibilityCriterion(response.data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  @override
  Future<EligibilityCriterion> reviewCriteria(
    String scholarshipId,
    String criteriaId,
    AdminCriteriaReviewRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/admin/scholarships/$scholarshipId/criteria/$criteriaId/review',
        data: request.toJson(),
      );
      return parseEligibilityCriterion(response.data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  @override
  Future<Scholarship> publishScholarship(
    String scholarshipId, {
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/admin/scholarships/$scholarshipId/publish',
        data: AdminPublishRequest(notes: notes).toJson(),
      );
      return parseScholarship(response.data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  @override
  Future<Scholarship> unpublishScholarship(
    String scholarshipId, {
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/admin/scholarships/$scholarshipId/unpublish',
        data: AdminPublishRequest(notes: notes).toJson(),
      );
      return parseScholarship(response.data);
    } on DioException catch (e) {
      throw _wrapDioError(e);
    }
  }

  @override
  Future<List<AdminAuditLog>> getAuditLogs(String scholarshipId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/admin/scholarships/$scholarshipId/audit-logs',
      );
      return parseAuditLogs(response.data);
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
