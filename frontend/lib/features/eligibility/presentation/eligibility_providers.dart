import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/eligibility/data/eligibility_repository.dart';
import 'package:claim_whats_yours/features/eligibility/domain/eligibility_models.dart';

final eligibilityRepositoryProvider = Provider<EligibilityRepository>((ref) {
  return ApiEligibilityRepository(ref.watch(apiClientProvider));
});

final studentBatchEligibilityProvider = FutureProvider.autoDispose<StudentBatchEligibility>((ref) {
  return ref.watch(eligibilityRepositoryProvider).getMyBatchEligibility();
});

final scholarshipEligibilityProvider = FutureProvider.autoDispose
    .family<EligibilityEvaluationResult, String>((ref, scholarshipId) {
  return ref.watch(eligibilityRepositoryProvider).getScholarshipEligibility(scholarshipId);
});
