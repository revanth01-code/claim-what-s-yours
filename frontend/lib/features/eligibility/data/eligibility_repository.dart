import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/eligibility/domain/eligibility_models.dart';

abstract interface class EligibilityRepository {
  Future<StudentBatchEligibility> getMyBatchEligibility();
  Future<EligibilityEvaluationResult> getScholarshipEligibility(String scholarshipId);
}

class ApiEligibilityRepository implements EligibilityRepository {
  ApiEligibilityRepository(this._client);

  final ApiClient _client;

  @override
  Future<StudentBatchEligibility> getMyBatchEligibility() async {
    final response = await _client.get<Map<String, dynamic>>('/eligibility/me');
    return StudentBatchEligibility.fromJson(response.data!);
  }

  @override
  Future<EligibilityEvaluationResult> getScholarshipEligibility(String scholarshipId) async {
    final response = await _client.get<Map<String, dynamic>>('/eligibility/me/$scholarshipId');
    return EligibilityEvaluationResult.fromJson(response.data!);
  }
}
