/// Immutable domain models for the scholarship catalogue.
///
/// These models mirror the backend contract in `backend/app/schemas/scholarship.py`.
/// They are produced by `scholarship_json_parser.dart`; do not build them from
/// unvalidated JSON elsewhere.
///
/// Notes for UI authors:
/// - Decimal values (percentages, family income) are kept as the backend's
///   display strings. They are never converted to `num`.
/// - [Scholarship.category] and [EligibilityCriterion.categories] hold raw
///   backend strings so that unknown values never drop a record. Use
///   [ScholarshipCategory.fromWire] to map a known value.
/// - `verification_status` values are defined by the backend. Display them as-is.
/// - Benefits are untyped on the backend. They are exposed as raw
///   [BenefitEntry] values so the UI can render them without inventing meaning.
library;

/// Known scholarship category values accepted by `GET /scholarships?category=`.
enum ScholarshipCategory {
  general('general'),
  sc('sc'),
  st('st'),
  obc('obc'),
  ebc('ebc'),
  minority('minority'),
  economicallyWeaker('economically_weaker'),
  disability('disability'),
  merit('merit'),
  other('other');

  const ScholarshipCategory(this.wireValue);

  /// The exact string sent to and received from the backend.
  final String wireValue;

  /// Maps a raw backend string to a known category, or null when unknown.
  static ScholarshipCategory? fromWire(String raw) {
    for (final category in values) {
      if (category.wireValue == raw) return category;
    }
    return null;
  }
}

/// Sort fields accepted by `GET /scholarships?sort_by=`.
enum ScholarshipSortField {
  name('name'),
  createdAt('created_at'),
  updatedAt('updated_at'),
  category('category');

  const ScholarshipSortField(this.wireValue);

  /// The exact string sent to the backend.
  final String wireValue;
}

/// Sort direction accepted by `GET /scholarships?sort_order=`.
enum ScholarshipSortOrder {
  asc('asc'),
  desc('desc');

  const ScholarshipSortOrder(this.wireValue);

  /// The exact string sent to the backend.
  final String wireValue;
}

/// One benefit item. [key] is empty when the backend supplied a bare value
/// with no name. [value] keeps the raw JSON type (String, num, bool, List,
/// Map or null).
class BenefitEntry {
  const BenefitEntry({required this.key, this.value});

  final String key;
  final Object? value;
}

/// One eligibility rule attached to a scholarship.
class EligibilityCriterion {
  const EligibilityCriterion({
    required this.id,
    this.academicYearId,
    this.minimumAcademicPercentage,
    this.maximumAcademicPercentage,
    this.minimumFamilyIncome,
    this.maximumFamilyIncome,
    this.educationLevels,
    this.courses,
    this.institutionRequirements,
    this.categories,
    this.domicileState,
    this.genderRestriction,
    this.disabilityRequired,
    this.renewalOnly = false,
    this.otherConditions,
    this.sourceReference,
    this.isVerified = false,
  });

  final String id;
  final String? academicYearId;

  /// Decimal percentage as the backend's display string (not converted).
  final String? minimumAcademicPercentage;

  /// Decimal percentage as the backend's display string (not converted).
  final String? maximumAcademicPercentage;

  /// Decimal income as the backend's display string (not converted).
  final String? minimumFamilyIncome;

  /// Decimal income as the backend's display string (not converted).
  final String? maximumFamilyIncome;
  final List<String>? educationLevels;
  final List<String>? courses;
  final Map<String, Object?>? institutionRequirements;
  final List<String>? categories;
  final String? domicileState;
  final String? genderRestriction;
  final bool? disabilityRequired;
  final bool renewalOnly;
  final Map<String, Object?>? otherConditions;
  final String? sourceReference;
  final bool isVerified;
}

/// Availability and overrides for one academic year. The backend sends no id
/// for this item, so [academicYear] is its identity.
class AcademicYearAvailability {
  const AcademicYearAvailability({
    required this.academicYear,
    this.startsOn,
    this.endsOn,
    this.isAvailable = false,
    this.openingDate,
    this.closingDate,
    this.nameOverride,
    this.descriptionOverride,
    this.benefitsOverride,
    this.applicationUrlOverride,
  });

  final String academicYear;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final bool isAvailable;
  final DateTime? openingDate;
  final DateTime? closingDate;
  final String? nameOverride;
  final String? descriptionOverride;

  /// Null when the backend sent no override.
  final List<BenefitEntry>? benefitsOverride;
  final String? applicationUrlOverride;
}

/// An official source document that backs scholarship information.
class OfficialSource {
  const OfficialSource({
    required this.id,
    required this.sourceUrl,
    required this.authority,
    required this.sourceType,
    required this.verificationStatus,
    this.title,
    this.documentReference,
    this.lastVerifiedAt,
    this.verifiedBy,
  });

  final String id;
  final String sourceUrl;
  final String authority;
  final String sourceType;

  /// Backend-defined status. Display as-is.
  final String verificationStatus;
  final String? title;
  final String? documentReference;
  final DateTime? lastVerifiedAt;
  final String? verifiedBy;
}

/// A scholarship as returned by `GET /scholarships/{id}` and list items.
class Scholarship {
  const Scholarship({
    required this.id,
    required this.name,
    required this.slug,
    required this.administeringAuthority,
    required this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.benefits = const [],
    this.applicationUrl,
    this.eligibilityCriteria = const [],
    this.academicYears = const [],
    this.sources = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String administeringAuthority;

  /// Raw backend category string. Use [ScholarshipCategory.fromWire] to map it.
  final String category;

  /// Empty when the backend sent no benefits.
  final List<BenefitEntry> benefits;
  final String? applicationUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<EligibilityCriterion> eligibilityCriteria;
  final List<AcademicYearAvailability> academicYears;
  final List<OfficialSource> sources;

  /// True when any source's [OfficialSource.verificationStatus] equals
  /// `verified`, compared case-insensitively. Other backend-defined status
  /// values are not treated as verified.
  bool get hasVerifiedSource => sources.any(
    (source) => source.verificationStatus.toLowerCase() == 'verified',
  );

  /// The mapped [ScholarshipCategory], or null when the backend value is unknown.
  ScholarshipCategory? get categoryValue =>
      ScholarshipCategory.fromWire(category);
}

/// One page of scholarships plus pagination metadata from `meta`.
class ScholarshipPage {
  const ScholarshipPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final List<Scholarship> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
}

/// Parameters for `GET /scholarships`.
///
/// Null or empty optional values are omitted from the request by the
/// repository. Use [copyWith] with the `clear*` flags to remove a filter.
class ScholarshipQuery {
  const ScholarshipQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.category,
    this.sortBy,
    this.sortOrder,
    this.academicYear,
    this.educationLevel,
  }) : assert(page >= 1),
       assert(pageSize >= 1 && pageSize <= 100),
       assert(search == null || search.length <= 200),
       assert(academicYear == null || academicYear.length <= 20),
       assert(educationLevel == null || educationLevel.length <= 100);

  final int page;
  final int pageSize;
  final String? search;
  final ScholarshipCategory? category;
  final ScholarshipSortField? sortBy;
  final ScholarshipSortOrder? sortOrder;
  final String? academicYear;
  final String? educationLevel;

  ScholarshipQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    ScholarshipCategory? category,
    ScholarshipSortField? sortBy,
    ScholarshipSortOrder? sortOrder,
    String? academicYear,
    String? educationLevel,
    bool clearSearch = false,
    bool clearCategory = false,
    bool clearSortBy = false,
    bool clearSortOrder = false,
    bool clearAcademicYear = false,
    bool clearEducationLevel = false,
  }) {
    return ScholarshipQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: clearSearch ? null : (search ?? this.search),
      category: clearCategory ? null : (category ?? this.category),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      sortOrder: clearSortOrder ? null : (sortOrder ?? this.sortOrder),
      academicYear: clearAcademicYear
          ? null
          : (academicYear ?? this.academicYear),
      educationLevel: clearEducationLevel
          ? null
          : (educationLevel ?? this.educationLevel),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScholarshipQuery &&
            other.page == page &&
            other.pageSize == pageSize &&
            other.search == search &&
            other.category == category &&
            other.sortBy == sortBy &&
            other.sortOrder == sortOrder &&
            other.academicYear == academicYear &&
            other.educationLevel == educationLevel;
  }

  @override
  int get hashCode => Object.hash(
    page,
    pageSize,
    search,
    category,
    sortBy,
    sortOrder,
    academicYear,
    educationLevel,
  );
}
