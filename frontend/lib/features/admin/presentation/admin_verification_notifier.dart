import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claim_whats_yours/core/errors/api_exception.dart';
import 'package:claim_whats_yours/features/scholarships/scholarship_providers.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import '../domain/admin_requests.dart';
import 'admin_providers.dart';

/// State of a specific scholarship under admin review.
class AdminVerificationState {
  const AdminVerificationState({
    this.scholarship,
    this.isLoading = false,
    this.isActionInProgress = false,
    this.errorMessage,
    this.successMessage,
  });

  final Scholarship? scholarship;
  final bool isLoading;
  final bool isActionInProgress;
  final String? errorMessage;
  final String? successMessage;

  AdminVerificationState copyWith({
    Scholarship? scholarship,
    bool? isLoading,
    bool? isActionInProgress,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return AdminVerificationState(
      scholarship: scholarship ?? this.scholarship,
      isLoading: isLoading ?? this.isLoading,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Controller managing review operations for a single scholarship.
class AdminVerificationNotifier extends Notifier<AdminVerificationState> {
  String? _scholarshipId;

  @override
  AdminVerificationState build() {
    return const AdminVerificationState(isLoading: true);
  }

  /// Loads scholarship by ID.
  Future<void> loadScholarship(String id) async {
    _scholarshipId = id;
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      // First check if pending queue already has it
      final pendingPage = ref.read(adminPendingNotifierProvider).asData?.value;
      Scholarship? found;
      if (pendingPage != null) {
        for (final item in pendingPage.items) {
          if (item.id == id) {
            found = item;
            break;
          }
        }
      }

      if (found != null) {
        state = state.copyWith(scholarship: found, isLoading: false);
      } else {
        final fetched = await ref.read(scholarshipRepositoryProvider).fetchById(id);
        state = state.copyWith(scholarship: fetched, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractMessage(e),
      );
    }
  }

  /// Reloads scholarship from backend.
  Future<void> reload() async {
    if (_scholarshipId != null) {
      await loadScholarship(_scholarshipId!);
    }
  }

  /// Reviews (verifies or rejects) a source.
  Future<bool> reviewSource({
    required String sourceId,
    required String status,
    String? notes,
    String? authority,
    String? title,
    String? documentReference,
  }) async {
    final id = _scholarshipId;
    if (id == null) return false;

    state = state.copyWith(isActionInProgress: true, clearMessages: true);
    try {
      final repository = ref.read(adminRepositoryProvider);
      final updatedSource = await repository.reviewSource(
        id,
        sourceId,
        AdminSourceReviewRequest(
          status: status,
          notes: notes,
          authority: authority,
          title: title,
          documentReference: documentReference,
        ),
      );

      final current = state.scholarship;
      if (current != null) {
        final newSources = current.sources.map((s) {
          return s.id == sourceId ? updatedSource : s;
        }).toList();

        final isNowActive = (status == 'rejected' &&
                !newSources.any((s) => s.verificationStatus == 'verified'))
            ? false
            : current.isActive;

        final updatedScholarship = Scholarship(
          id: current.id,
          name: current.name,
          slug: current.slug,
          description: current.description,
          administeringAuthority: current.administeringAuthority,
          category: current.category,
          isActive: isNowActive,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          benefits: current.benefits,
          applicationUrl: current.applicationUrl,
          eligibilityCriteria: current.eligibilityCriteria,
          academicYears: current.academicYears,
          sources: newSources,
        );

        state = state.copyWith(
          scholarship: updatedScholarship,
          isActionInProgress: false,
          successMessage: 'Source $status successfully.',
        );
        ref.read(adminPendingNotifierProvider.notifier).updateScholarship(updatedScholarship);
      } else {
        state = state.copyWith(isActionInProgress: false);
      }
      ref.invalidate(adminAuditLogsProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: _extractMessage(e),
      );
      return false;
    }
  }

  /// Adds a new eligibility criterion.
  Future<bool> createCriteria(AdminCriteriaCreateRequest request) async {
    final id = _scholarshipId;
    if (id == null) return false;

    state = state.copyWith(isActionInProgress: true, clearMessages: true);
    try {
      final repository = ref.read(adminRepositoryProvider);
      final newCriterion = await repository.createCriteria(id, request);
      final current = state.scholarship;
      if (current != null) {
        final updatedCriteria = [...current.eligibilityCriteria, newCriterion];
        final updatedScholarship = Scholarship(
          id: current.id,
          name: current.name,
          slug: current.slug,
          description: current.description,
          administeringAuthority: current.administeringAuthority,
          category: current.category,
          isActive: current.isActive,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          benefits: current.benefits,
          applicationUrl: current.applicationUrl,
          eligibilityCriteria: updatedCriteria,
          academicYears: current.academicYears,
          sources: current.sources,
        );
        state = state.copyWith(
          scholarship: updatedScholarship,
          isActionInProgress: false,
          successMessage: 'Eligibility criteria created. Review required before publication.',
        );
        ref.read(adminPendingNotifierProvider.notifier).updateScholarship(updatedScholarship);
      } else {
        state = state.copyWith(isActionInProgress: false);
      }
      ref.invalidate(adminAuditLogsProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: _extractMessage(e),
      );
      return false;
    }
  }

  /// Updates existing eligibility criteria (automatically revokes verification).
  Future<bool> updateCriteria(
    String criteriaId,
    AdminCriteriaUpdateRequest request,
  ) async {
    final id = _scholarshipId;
    if (id == null) return false;

    state = state.copyWith(isActionInProgress: true, clearMessages: true);
    try {
      final repository = ref.read(adminRepositoryProvider);
      final updatedCriterion = await repository.updateCriteria(
        id,
        criteriaId,
        request,
      );
      final current = state.scholarship;
      if (current != null) {
        final updatedCriteria = current.eligibilityCriteria.map((c) {
          return c.id == criteriaId ? updatedCriterion : c;
        }).toList();

        final updatedScholarship = Scholarship(
          id: current.id,
          name: current.name,
          slug: current.slug,
          description: current.description,
          administeringAuthority: current.administeringAuthority,
          category: current.category,
          isActive: current.isActive,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          benefits: current.benefits,
          applicationUrl: current.applicationUrl,
          eligibilityCriteria: updatedCriteria,
          academicYears: current.academicYears,
          sources: current.sources,
        );
        state = state.copyWith(
          scholarship: updatedScholarship,
          isActionInProgress: false,
          successMessage: 'Criteria updated. Verification was reset to pending review.',
        );
        ref.read(adminPendingNotifierProvider.notifier).updateScholarship(updatedScholarship);
      } else {
        state = state.copyWith(isActionInProgress: false);
      }
      ref.invalidate(adminAuditLogsProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: _extractMessage(e),
      );
      return false;
    }
  }

  /// Approves or rejects a criterion.
  Future<bool> reviewCriteria({
    required String criteriaId,
    required bool isVerified,
    String? notes,
  }) async {
    final id = _scholarshipId;
    if (id == null) return false;

    state = state.copyWith(isActionInProgress: true, clearMessages: true);
    try {
      final repository = ref.read(adminRepositoryProvider);
      final reviewedCriterion = await repository.reviewCriteria(
        id,
        criteriaId,
        AdminCriteriaReviewRequest(isVerified: isVerified, notes: notes),
      );
      final current = state.scholarship;
      if (current != null) {
        final updatedCriteria = current.eligibilityCriteria.map((c) {
          return c.id == criteriaId ? reviewedCriterion : c;
        }).toList();

        final updatedScholarship = Scholarship(
          id: current.id,
          name: current.name,
          slug: current.slug,
          description: current.description,
          administeringAuthority: current.administeringAuthority,
          category: current.category,
          isActive: current.isActive,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          benefits: current.benefits,
          applicationUrl: current.applicationUrl,
          eligibilityCriteria: updatedCriteria,
          academicYears: current.academicYears,
          sources: current.sources,
        );
        state = state.copyWith(
          scholarship: updatedScholarship,
          isActionInProgress: false,
          successMessage: isVerified ? 'Criteria approved.' : 'Criteria marked unverified.',
        );
        ref.read(adminPendingNotifierProvider.notifier).updateScholarship(updatedScholarship);
      } else {
        state = state.copyWith(isActionInProgress: false);
      }
      ref.invalidate(adminAuditLogsProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: _extractMessage(e),
      );
      return false;
    }
  }

  /// Publishes scholarship once all gates pass.
  Future<bool> publish({String? notes}) async {
    final id = _scholarshipId;
    if (id == null) return false;

    state = state.copyWith(isActionInProgress: true, clearMessages: true);
    try {
      final repository = ref.read(adminRepositoryProvider);
      final published = await repository.publishScholarship(id, notes: notes);
      state = state.copyWith(
        scholarship: published,
        isActionInProgress: false,
        successMessage: 'Scholarship published successfully to student catalogue.',
      );
      ref.read(adminPendingNotifierProvider.notifier).updateScholarship(published);
      ref.invalidate(adminAuditLogsProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: _extractMessage(e),
      );
      return false;
    }
  }

  /// Unpublishes (deactivates) scholarship.
  Future<bool> unpublish({String? notes}) async {
    final id = _scholarshipId;
    if (id == null) return false;

    state = state.copyWith(isActionInProgress: true, clearMessages: true);
    try {
      final repository = ref.read(adminRepositoryProvider);
      final unpublished = await repository.unpublishScholarship(id, notes: notes);
      state = state.copyWith(
        scholarship: unpublished,
        isActionInProgress: false,
        successMessage: 'Scholarship unpublished and moved back to pending queue.',
      );
      ref.read(adminPendingNotifierProvider.notifier).updateScholarship(unpublished);
      ref.invalidate(adminAuditLogsProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: _extractMessage(e),
      );
      return false;
    }
  }

  String _extractMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
