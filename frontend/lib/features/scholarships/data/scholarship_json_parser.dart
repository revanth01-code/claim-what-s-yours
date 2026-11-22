/// Pure functions that turn scholarship JSON into domain objects.
///
/// Rules:
/// - Missing or wrongly typed optional fields become null (or an empty list).
/// - Missing or wrongly typed required fields, and unparseable UUIDs or
///   datetimes, throw [ScholarshipParseException].
/// - Exception messages name the field only. They never include payload data.
library;

import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

/// Thrown when a scholarship payload violates the backend contract for a
/// required field. [message] names the field and never contains payload data.
class ScholarshipParseException implements Exception {
  const ScholarshipParseException(this.message);

  /// Safe, payload-free description of the failure.
  final String message;

  @override
  String toString() => 'ScholarshipParseException: $message';
}

typedef _Json = Map<String, dynamic>;

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Parses one `ScholarshipResponse` object.
///
/// Throws [ScholarshipParseException] when a required field is invalid.
Scholarship parseScholarship(Object? raw) {
  final json = _asObject(raw, 'scholarship');
  return Scholarship(
    id: _requiredUuid(json, 'id'),
    name: _requiredString(json, 'name'),
    slug: _requiredString(json, 'slug'),
    description: _optionalString(json, 'description'),
    administeringAuthority: _requiredString(json, 'administering_authority'),
    category: _requiredString(json, 'category'),
    benefits: _benefitsFrom(json['benefits']),
    applicationUrl: _optionalString(json, 'application_url'),
    isActive: _requiredBool(json, 'is_active'),
    createdAt: _requiredDateTime(json, 'created_at'),
    updatedAt: _requiredDateTime(json, 'updated_at'),
    eligibilityCriteria: _listOf(
      json,
      'eligibility_criteria',
      _parseEligibility,
    ),
    academicYears: _listOf(json, 'academic_years', _parseAcademicYear),
    sources: _listOf(json, 'sources', _parseSource),
  );
}

/// Parses the `GET /scholarships` envelope: `{"data": [...], "meta": {...}}`.
///
/// Throws [ScholarshipParseException] when the envelope, `data`, `meta`, or
/// any item is invalid.
ScholarshipPage parseScholarshipPage(Object? raw) {
  final json = _asObject(raw, 'scholarship list');
  final data = json['data'];
  if (data is! List) {
    throw const ScholarshipParseException(
      'Required field "data" is missing or invalid.',
    );
  }
  final items = data.map(parseScholarship).toList(growable: false);
  final meta = _asObject(json['meta'], 'meta');
  return ScholarshipPage(
    items: items,
    page: _requiredInt(meta, 'page'),
    pageSize: _requiredInt(meta, 'page_size'),
    total: _requiredInt(meta, 'total'),
    totalPages: _requiredInt(meta, 'total_pages'),
  );
}

EligibilityCriterion _parseEligibility(Object? raw) {
  final json = _asObject(raw, 'eligibility_criteria');
  return EligibilityCriterion(
    id: _requiredUuid(json, 'id'),
    academicYearId: _optionalUuid(json, 'academic_year_id'),
    minimumAcademicPercentage: _optionalString(
      json,
      'minimum_academic_percentage',
    ),
    maximumAcademicPercentage: _optionalString(
      json,
      'maximum_academic_percentage',
    ),
    minimumFamilyIncome: _optionalString(json, 'minimum_family_income'),
    maximumFamilyIncome: _optionalString(json, 'maximum_family_income'),
    educationLevels: _optionalStringList(json, 'education_levels'),
    courses: _optionalStringList(json, 'courses'),
    institutionRequirements: _optionalObject(json, 'institution_requirements'),
    categories: _optionalStringList(json, 'categories'),
    domicileState: _optionalString(json, 'domicile_state'),
    genderRestriction: _optionalString(json, 'gender_restriction'),
    disabilityRequired: _optionalBool(json, 'disability_required'),
    renewalOnly: _boolOrFalse(json, 'renewal_only'),
    otherConditions: _optionalObject(json, 'other_conditions'),
    sourceReference: _optionalString(json, 'source_reference'),
    isVerified: _boolOrFalse(json, 'is_verified'),
  );
}

AcademicYearAvailability _parseAcademicYear(Object? raw) {
  final json = _asObject(raw, 'academic_years');
  return AcademicYearAvailability(
    academicYear: _requiredString(json, 'academic_year'),
    startsOn: _optionalDate(json, 'starts_on'),
    endsOn: _optionalDate(json, 'ends_on'),
    isAvailable: _boolOrFalse(json, 'is_available'),
    openingDate: _optionalDate(json, 'opening_date'),
    closingDate: _optionalDate(json, 'closing_date'),
    nameOverride: _optionalString(json, 'name_override'),
    descriptionOverride: _optionalString(json, 'description_override'),
    benefitsOverride: _optionalBenefits(json['benefits_override']),
    applicationUrlOverride: _optionalString(json, 'application_url_override'),
  );
}

OfficialSource _parseSource(Object? raw) {
  final json = _asObject(raw, 'sources');
  return OfficialSource(
    id: _requiredUuid(json, 'id'),
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

_Json _asObject(Object? raw, String context) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  throw ScholarshipParseException('Expected an object for $context.');
}

List<T> _listOf<T>(_Json json, String key, T Function(Object? raw) parse) {
  final raw = json[key];
  if (raw is! List) return <T>[];
  return raw.map(parse).toList(growable: false);
}

String _requiredString(_Json json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw ScholarshipParseException(
    'Required field "$key" is missing or invalid.',
  );
}

String? _optionalString(_Json json, String key) {
  final value = json[key];
  return value is String ? value : null;
}

String _requiredUuid(_Json json, String key) {
  final value = json[key];
  if (value is String && _uuidPattern.hasMatch(value)) return value;
  throw ScholarshipParseException(
    'Required field "$key" is missing or invalid.',
  );
}

String? _optionalUuid(_Json json, String key) {
  final value = json[key];
  return value is String && _uuidPattern.hasMatch(value) ? value : null;
}

bool _requiredBool(_Json json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw ScholarshipParseException(
    'Required field "$key" is missing or invalid.',
  );
}

bool? _optionalBool(_Json json, String key) {
  final value = json[key];
  return value is bool ? value : null;
}

/// Non-boolean or missing values are treated as false (the conservative reading).
bool _boolOrFalse(_Json json, String key) => json[key] == true;

int _requiredInt(_Json json, String key) {
  final value = _intOrNull(json[key]);
  if (value != null) return value;
  throw ScholarshipParseException(
    'Required field "$key" is missing or invalid.',
  );
}

int? _intOrNull(Object? value) {
  if (value is int) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return null;
}

DateTime _requiredDateTime(_Json json, String key) {
  final value = json[key];
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed != null) return parsed;
  throw ScholarshipParseException(
    'Required field "$key" is missing or invalid.',
  );
}

DateTime? _optionalDate(_Json json, String key) {
  final value = json[key];
  return value is String ? DateTime.tryParse(value) : null;
}

List<String>? _optionalStringList(_Json json, String key) {
  final value = json[key];
  if (value is! List) return null;
  return value.whereType<String>().toList(growable: false);
}

Map<String, Object?>? _optionalObject(_Json json, String key) {
  final value = json[key];
  if (value is! Map) return null;
  return value.map((k, v) => MapEntry(k.toString(), v));
}

/// Benefits are untyped on the backend. A list yields one entry per map key
/// (or one keyless entry per non-map element). A map yields one entry per key.
/// Any other non-null value yields one keyless entry.
List<BenefitEntry> _benefitsFrom(Object? raw) {
  if (raw == null) return const <BenefitEntry>[];
  if (raw is Map) return _entriesOf(raw);
  if (raw is List) {
    final entries = <BenefitEntry>[];
    for (final element in raw) {
      if (element is Map) {
        entries.addAll(_entriesOf(element));
      } else {
        entries.add(BenefitEntry(key: '', value: element));
      }
    }
    return entries;
  }
  return <BenefitEntry>[BenefitEntry(key: '', value: raw)];
}

/// Like [_benefitsFrom], but null means "no override was sent".
List<BenefitEntry>? _optionalBenefits(Object? raw) {
  if (raw == null) return null;
  return _benefitsFrom(raw);
}

List<BenefitEntry> _entriesOf(Map<dynamic, dynamic> map) {
  return map.entries
      .map((e) => BenefitEntry(key: e.key.toString(), value: e.value))
      .toList(growable: false);
}
