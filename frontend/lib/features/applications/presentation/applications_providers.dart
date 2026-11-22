import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/applications/data/application_repository.dart';
import 'package:claim_whats_yours/features/applications/domain/application_record.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApiApplicationRepository(ref.watch(apiClientProvider));
});

final myApplicationsProvider = FutureProvider.autoDispose<List<ApplicationRecordItem>>((ref) {
  return ref.watch(applicationRepositoryProvider).listMyApplications();
});
