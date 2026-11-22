/// Application user representation received from FastAPI backend:
/// `GET /api/v1/auth/me`
///
/// The backend is authoritative for identity and application roles.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.displayName,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String? email;
  final bool emailVerified;
  final String? displayName;
  final String role;
  final bool isActive;

  /// Returns true if the user has administrator privileges as confirmed by backend.
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Returns true if the user is a standard student.
  bool get isStudent => role.toLowerCase() == 'student';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      displayName: json['display_name'] as String?,
      role: json['role'] as String? ?? 'student',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'email_verified': emailVerified,
      'display_name': displayName,
      'role': role,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          emailVerified == other.emailVerified &&
          displayName == other.displayName &&
          role == other.role &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      Object.hash(id, email, emailVerified, displayName, role, isActive);
}
