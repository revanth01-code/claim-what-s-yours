import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

/// Contract for reading the scholarship catalogue.
abstract interface class ScholarshipRepository {
  /// Fetches one page of scholarships for [query] from `GET /scholarships`.
  Future<ScholarshipPage> fetchPage(ScholarshipQuery query);

  /// Fetches one scholarship by id from `GET /scholarships/{id}`.
  Future<Scholarship> fetchById(String id);

  /// Fetches all scholarships saved by the authenticated student from `GET /scholarships/saved`.
  Future<List<Scholarship>> fetchSaved();

  /// Saves a scholarship for the authenticated student.
  Future<bool> saveScholarship(String id);

  /// Removes a saved scholarship for the authenticated student.
  Future<bool> unsaveScholarship(String id);

  /// Checks if a scholarship is currently saved.
  Future<bool> isSaved(String id);
}
