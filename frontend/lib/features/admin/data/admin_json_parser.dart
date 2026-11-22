import '../../scholarships/domain/scholarship.dart';
import '../domain/admin_audit_log.dart';

/// Pure parsing functions for admin endpoint responses.
class AdminParseException implements Exception {
  const AdminParseException(this.message);
  final String message;
  @override
  String toString() => 'AdminParseException: $message';
}

typedef _Json = Map<String, dynamic>;

_Json _asObject(Object? raw, String context) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  throw AdminParseException('Expected an object for $context.');
}

String _requiredString(_Json json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw AdminParseException('Required field "$key" is missing or not a string.');
}

String? _optionalString(_Json json, String key) {
  final value = json[key];
  return value is String ? value : null;
}

DateTime? _optionalDate(_Json json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

bool _boolOrFalse(_Json json, String key) {
  final value = json[key];
  return value is bool ? value : false;
}

/// Parses a single `OfficialSourceResponse` returned by `/sources/{source_id}/review`.
OfficialSource parseOfficialSource(Object? raw) {
  final json = _asObject(raw, 'official source');
  return OfficialSource(
    id: _requiredString(json, 'id'),
    sourceUrl: _requiredString(json, 'source_url'),
    authority: _requiredString(json, 'authority'),
    sourceType: _requiredString(json, 'source_type'),
    verificationStatus: _requiredString(json, 'verification_status'),
    title: _optionalString(json, 'title'),
    documentReference: _optionalString(json, 'document_reference'),
    lastVerifiedAt: _optionalDate(json, 'last_verified_at'),
    verifiedBy: _optionalString(json, 'verified_by'),
  );
}

/// Parses a single `EligibilityCriteriaResponse` returned by `/criteria/...`.
EligibilityCriterion parseEligibilityCriterion(Object? raw) {
  final json = _asObject(raw, 'eligibility criterion');
  return EligibilityCriterion(
    id: _requiredString(json, 'id'),
    academicYearId: _optionalString(json, 'academic_year_id'),
    minimumAcademicPercentage: _optionalString(json, 'minimum_academic_percentage'),
    maximumAcademicPercentage: _optionalString(json, 'maximum_academic_percentage'),
    minimumFamilyIncome: _optionalString(json, 'minimum_family_income'),
    maximumFamilyIncome: _optionalString(json, 'maximum_family_income'),
    educationLevels: (json['education_levels'] as List?)?.map((e) => e.toString()).toList(),
    courses: (json['courses'] as List?)?.map((e) => e.toString()).toList(),
    institutionRequirements: json['institution_requirements'] is Map
        ? Map<String, Object?>.from(json['institution_requirements'] as Map)
        : null,
    categories: (json['categories'] as List?)?.map((e) => e.toString()).toList(),
    domicileState: _optionalString(json, 'domicile_state'),
    genderRestriction: _optionalString(json, 'gender_restriction'),
    disabilityRequired: json['disability_required'] as bool?,
    renewalOnly: _boolOrFalse(json, 'renewal_only'),
    otherConditions: json['other_conditions'] is Map
        ? Map<String, Object?>.from(json['other_conditions'] as Map)
        : null,
    sourceReference: _optionalString(json, 'source_reference'),
    isVerified: _boolOrFalse(json, 'is_verified'),
  );
}

/// Parses list of audit logs from `GET /api/v1/admin/scholarships/{id}/audit-logs`.
List<AdminAuditLog> parseAuditLogs(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((item) {
    if (item is Map) {
      return AdminAuditLog.fromJson(Map<String, dynamic>.from(item));
    }
    throw const AdminParseException('Expected audit log item to be an object.');
  }).toList(growable: false);
}
