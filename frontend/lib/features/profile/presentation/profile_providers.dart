import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claim_whats_yours/core/network/api_client.dart';
import '../data/api_student_profile_repository.dart';
import '../data/student_profile_repository.dart';
import '../domain/student_profile.dart';
import 'profile_notifier.dart';

/// Provider exposing the [StudentProfileRepository] implementation.
final studentProfileRepositoryProvider = Provider<StudentProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiStudentProfileRepository(apiClient);
});

/// State notifier provider managing the student's profile and saving state.
final studentProfileNotifierProvider =
    NotifierProvider.autoDispose<StudentProfileNotifier, StudentProfileState>(
  StudentProfileNotifier.new,
);

/// Provider exposing completion status of the student's profile.
final studentProfileCompletionProvider =
    FutureProvider.autoDispose<ProfileCompletion>((ref) async {
  final repository = ref.watch(studentProfileRepositoryProvider);
  return repository.getProfileCompletion();
});
