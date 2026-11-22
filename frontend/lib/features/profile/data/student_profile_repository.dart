import '../domain/student_profile.dart';

/// Abstract contract for student profile operations.
abstract class StudentProfileRepository {
  /// Fetch the authenticated student's profile.
  Future<StudentProfile> getProfile();

  /// Create or update the authenticated student's profile.
  Future<StudentProfile> updateProfile(StudentProfile profile);

  /// Fetch profile completeness metrics.
  Future<ProfileCompletion> getProfileCompletion();
}
