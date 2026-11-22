import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/applications/domain/application_record.dart';

abstract interface class ApplicationRepository {
  Future<List<ApplicationRecordItem>> listMyApplications();
  Future<ApplicationRecordItem> createApplication({
    required String scholarshipId,
    required String portalName,
    required String applicationReferenceNumber,
    String status = 'submitted',
    String academicYear = '2026-2027',
    double? appliedAmount,
    String? notes,
  });
  Future<ApplicationRecordItem> updateApplicationStatus({
    required String applicationId,
    required String status,
    double? disbursedAmount,
    String? notes,
  });
}

class ApiApplicationRepository implements ApplicationRepository {
  ApiApplicationRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<ApplicationRecordItem>> listMyApplications() async {
    final response = await _client.get<List<dynamic>>('/applications/me');
    final list = response.data ?? [];
    return list.map((e) => ApplicationRecordItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ApplicationRecordItem> createApplication({
    required String scholarshipId,
    required String portalName,
    required String applicationReferenceNumber,
    String status = 'submitted',
    String academicYear = '2026-2027',
    double? appliedAmount,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'scholarship_id': scholarshipId,
      'portal_name': portalName,
      'application_reference_number': applicationReferenceNumber,
      'status': status,
      'academic_year': academicYear,
    };
    if (appliedAmount != null) payload['applied_amount'] = appliedAmount;
    if (notes != null) payload['notes'] = notes;

    final response = await _client.post<Map<String, dynamic>>(
      '/applications/me',
      data: payload,
    );
    return ApplicationRecordItem.fromJson(response.data!);
  }

  @override
  Future<ApplicationRecordItem> updateApplicationStatus({
    required String applicationId,
    required String status,
    double? disbursedAmount,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
    };
    if (disbursedAmount != null) payload['disbursed_amount'] = disbursedAmount;
    if (notes != null) payload['notes'] = notes;

    final response = await _client.patch<Map<String, dynamic>>(
      '/applications/me/$applicationId',
      data: payload,
    );
    return ApplicationRecordItem.fromJson(response.data!);
  }
}
