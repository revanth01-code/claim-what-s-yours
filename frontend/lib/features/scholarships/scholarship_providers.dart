import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/scholarships/data/api_scholarship_repository.dart';
import 'package:claim_whats_yours/features/scholarships/data/scholarship_repository.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

/// Provides the scholarship repository backed by the shared [ApiClient].
final scholarshipRepositoryProvider = Provider<ScholarshipRepository>((ref) {
  return ApiScholarshipRepository(ref.watch(apiClientProvider));
});

/// Loads one scholarship by id. Disposed when no longer watched.
final scholarshipDetailProvider = FutureProvider.autoDispose
    .family<Scholarship, String>((ref, id) {
      return ref.watch(scholarshipRepositoryProvider).fetchById(id);
    });
