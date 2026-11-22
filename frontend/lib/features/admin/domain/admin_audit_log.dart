import 'package:flutter/foundation.dart';

/// Represents a single verification or publication audit log record.
/// Mirrors `VerificationAuditLogResponse` in `backend/app/schemas/admin.py`.
@immutable
class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.adminUserId,
    required this.action,
    required this.targetType,
    required this.createdAt,
    this.scholarshipId,
    this.targetId,
    this.notes,
    this.details,
  });

  final String id;
  final String? scholarshipId;
  final String adminUserId;
  final String action;
  final String targetType;
  final String? targetId;
  final String? notes;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  /// User-friendly label for the action.
  String get actionDisplay {
    switch (action) {
      case 'source_verify':
        return 'Source Verified';
      case 'source_reject':
        return 'Source Rejected';
      case 'source_update':
        return 'Source Updated';
      case 'criteria_create':
        return 'Criteria Created';
      case 'criteria_update':
        return 'Criteria Updated';
      case 'criteria_approve':
        return 'Criteria Approved';
      case 'criteria_reject':
        return 'Criteria Rejected';
      case 'scholarship_publish':
        return 'Scholarship Published';
      case 'scholarship_unpublish':
        return 'Scholarship Unpublished';
      case 'admin_promote':
        return 'Admin Promoted';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: json['id'] as String,
      scholarshipId: json['scholarship_id'] as String?,
      adminUserId: json['admin_user_id'] as String,
      action: json['action'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String?,
      notes: json['notes'] as String?,
      details: json['details'] is Map ? Map<String, dynamic>.from(json['details'] as Map) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAuditLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          action == other.action &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, action, createdAt);
}
