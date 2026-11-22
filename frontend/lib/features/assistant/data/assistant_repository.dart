import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/assistant/domain/ai_guidance.dart';

abstract interface class AssistantRepository {
  Future<AIGuidanceResult> askGuidance({
    required String query,
    String? scholarshipId,
    String language = 'en',
    bool includeProfileContext = true,
  });
}

class ApiAssistantRepository implements AssistantRepository {
  ApiAssistantRepository(this._client);

  final ApiClient _client;

  @override
  Future<AIGuidanceResult> askGuidance({
    required String query,
    String? scholarshipId,
    String language = 'en',
    bool includeProfileContext = true,
  }) async {
    final payload = <String, dynamic>{
      'query': query,
      'language': language,
      'include_profile_context': includeProfileContext,
    };
    if (scholarshipId != null) payload['scholarship_id'] = scholarshipId;

    final response = await _client.post<Map<String, dynamic>>(
      '/ai/guidance',
      data: payload,
    );
    return AIGuidanceResult.fromJson(response.data!);
  }
}
