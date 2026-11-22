import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import '../data/admin_repository.dart';
import '../data/api_admin_repository.dart';
import '../domain/admin_audit_log.dart';
import 'admin_pending_notifier.dart';
import 'admin_verification_notifier.dart';

/// Provider for the singleton AdminRepository.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiAdminRepository(apiClient);
});

/// Provider for the pending scholarship queue.
final adminPendingNotifierProvider =
    AsyncNotifierProvider<AdminPendingNotifier, ScholarshipPage>(
  AdminPendingNotifier.new,
);

/// Provider for chronological audit logs for a specific scholarship.
final adminAuditLogsProvider =
    FutureProvider.family<List<AdminAuditLog>, String>((ref, scholarshipId) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getAuditLogs(scholarshipId);
});

/// Provider for the active scholarship verification session.
final adminVerificationNotifierProvider = NotifierProvider.autoDispose<
    AdminVerificationNotifier, AdminVerificationState>(
  AdminVerificationNotifier.new,
);
