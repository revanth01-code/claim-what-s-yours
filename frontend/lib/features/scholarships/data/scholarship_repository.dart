import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

/// Contract for reading the scholarship catalogue.
abstract interface class ScholarshipRepository {
  /// Fetches one page of scholarships for [query] from `GET /scholarships`.
  Future<ScholarshipPage> fetchPage(ScholarshipQuery query);

  /// Fetches one scholarship by id from `GET /scholarships/{id}`.
  Future<Scholarship> fetchById(String id);
}
