import '../../scholarships/domain/scholarship.dart';
import '../domain/admin_audit_log.dart';
import '../domain/admin_requests.dart';

/// Abstract contract for administrator scholarship verification and publication workflows.
abstract class AdminRepository {
  /// Fetches inactive / pending scholarships awaiting review or publication.
  Future<ScholarshipPage> getPendingScholarships({int page = 1, int pageSize = 20});

  /// Reviews (verifies or rejects) a scholarship source and updates metadata.
  Future<OfficialSource> reviewSource(
    String scholarshipId,
    String sourceId,
    AdminSourceReviewRequest request,
  );

  /// Adds new eligibility criteria to a scholarship.
  Future<EligibilityCriterion> createCriteria(
    String scholarshipId,
    AdminCriteriaCreateRequest request,
  );

  /// Updates existing eligibility criteria for a scholarship (revoking verification).
  Future<EligibilityCriterion> updateCriteria(
    String scholarshipId,
    String criteriaId,
    AdminCriteriaUpdateRequest request,
  );

  /// Reviews (approves or un-verifies) specific eligibility criteria.
  Future<EligibilityCriterion> reviewCriteria(
    String scholarshipId,
    String criteriaId,
    AdminCriteriaReviewRequest request,
  );

  /// Publishes a verified scholarship after all publication gates pass.
  Future<Scholarship> publishScholarship(
    String scholarshipId, {
    String? notes,
  });

  /// Unpublishes (deactivates) an active scholarship.
  Future<Scholarship> unpublishScholarship(
    String scholarshipId, {
    String? notes,
  });

  /// Retrieves chronological verification audit history for a scholarship.
  Future<List<AdminAuditLog>> getAuditLogs(String scholarshipId);
}
