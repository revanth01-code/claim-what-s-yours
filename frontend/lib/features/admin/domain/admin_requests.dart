library;

/// Request payloads for admin scholarship verification and criteria management.
/// Strictly matches backend schemas in `backend/app/schemas/admin.py`.

/// Payload for `POST /api/v1/admin/scholarships/{id}/sources/{source_id}/review`
class AdminSourceReviewRequest {
  const AdminSourceReviewRequest({
    required this.status,
    this.notes,
    this.authority,
    this.title,
    this.documentReference,
  });

  /// Must be 'verified' or 'rejected'.
  final String status;
  final String? notes;
  final String? authority;
  final String? title;
  final String? documentReference;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'status': status};
    if (notes != null && notes!.isNotEmpty) map['notes'] = notes;
    if (authority != null && authority!.isNotEmpty) map['authority'] = authority;
    if (title != null && title!.isNotEmpty) map['title'] = title;
    if (documentReference != null && documentReference!.isNotEmpty) {
      map['document_reference'] = documentReference;
    }
    return map;
  }
}

/// Payload for `POST /api/v1/admin/scholarships/{id}/criteria`
/// NOTE: `is_verified` MUST NOT be sent in creation per backend security rules.
class AdminCriteriaCreateRequest {
  const AdminCriteriaCreateRequest({
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
    this.notes,
  });

  final String? academicYearId;
  final double? minimumAcademicPercentage;
  final double? maximumAcademicPercentage;
  final double? minimumFamilyIncome;
  final double? maximumFamilyIncome;
  final List<String>? educationLevels;
  final List<String>? courses;
  final Map<String, dynamic>? institutionRequirements;
  final List<String>? categories;
  final String? domicileState;
  final String? genderRestriction;
  final bool? disabilityRequired;
  final bool renewalOnly;
  final Map<String, dynamic>? otherConditions;
  final String? sourceReference;
  final String? notes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'renewal_only': renewalOnly,
    };
    if (academicYearId != null) map['academic_year_id'] = academicYearId;
    if (minimumAcademicPercentage != null) {
      map['minimum_academic_percentage'] = minimumAcademicPercentage;
    }
    if (maximumAcademicPercentage != null) {
      map['maximum_academic_percentage'] = maximumAcademicPercentage;
    }
    if (minimumFamilyIncome != null) {
      map['minimum_family_income'] = minimumFamilyIncome;
    }
    if (maximumFamilyIncome != null) {
      map['maximum_family_income'] = maximumFamilyIncome;
    }
    if (educationLevels != null && educationLevels!.isNotEmpty) {
      map['education_levels'] = educationLevels;
    }
    if (courses != null && courses!.isNotEmpty) {
      map['courses'] = courses;
    }
    if (institutionRequirements != null) {
      map['institution_requirements'] = institutionRequirements;
    }
    if (categories != null && categories!.isNotEmpty) {
      map['categories'] = categories;
    }
    if (domicileState != null && domicileState!.isNotEmpty) {
      map['domicile_state'] = domicileState;
    }
    if (genderRestriction != null && genderRestriction!.isNotEmpty) {
      map['gender_restriction'] = genderRestriction;
    }
    if (disabilityRequired != null) {
      map['disability_required'] = disabilityRequired;
    }
    if (otherConditions != null) {
      map['other_conditions'] = otherConditions;
    }
    if (sourceReference != null && sourceReference!.isNotEmpty) {
      map['source_reference'] = sourceReference;
    }
    if (notes != null && notes!.isNotEmpty) {
      map['notes'] = notes;
    }
    return map;
  }
}

/// Payload for `PUT /api/v1/admin/scholarships/{id}/criteria/{criteria_id}`
/// Updating criteria automatically revokes verification on the backend.
class AdminCriteriaUpdateRequest {
  const AdminCriteriaUpdateRequest({
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
    this.notes,
  });

  final String? academicYearId;
  final double? minimumAcademicPercentage;
  final double? maximumAcademicPercentage;
  final double? minimumFamilyIncome;
  final double? maximumFamilyIncome;
  final List<String>? educationLevels;
  final List<String>? courses;
  final Map<String, dynamic>? institutionRequirements;
  final List<String>? categories;
  final String? domicileState;
  final String? genderRestriction;
  final bool? disabilityRequired;
  final bool renewalOnly;
  final Map<String, dynamic>? otherConditions;
  final String? sourceReference;
  final String? notes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'renewal_only': renewalOnly,
    };
    if (academicYearId != null) map['academic_year_id'] = academicYearId;
    if (minimumAcademicPercentage != null) {
      map['minimum_academic_percentage'] = minimumAcademicPercentage;
    }
    if (maximumAcademicPercentage != null) {
      map['maximum_academic_percentage'] = maximumAcademicPercentage;
    }
    if (minimumFamilyIncome != null) {
      map['minimum_family_income'] = minimumFamilyIncome;
    }
    if (maximumFamilyIncome != null) {
      map['maximum_family_income'] = maximumFamilyIncome;
    }
    if (educationLevels != null && educationLevels!.isNotEmpty) {
      map['education_levels'] = educationLevels;
    }
    if (courses != null && courses!.isNotEmpty) {
      map['courses'] = courses;
    }
    if (institutionRequirements != null) {
      map['institution_requirements'] = institutionRequirements;
    }
    if (categories != null && categories!.isNotEmpty) {
      map['categories'] = categories;
    }
    if (domicileState != null && domicileState!.isNotEmpty) {
      map['domicile_state'] = domicileState;
    }
    if (genderRestriction != null && genderRestriction!.isNotEmpty) {
      map['gender_restriction'] = genderRestriction;
    }
    if (disabilityRequired != null) {
      map['disability_required'] = disabilityRequired;
    }
    if (otherConditions != null) {
      map['other_conditions'] = otherConditions;
    }
    if (sourceReference != null && sourceReference!.isNotEmpty) {
      map['source_reference'] = sourceReference;
    }
    if (notes != null && notes!.isNotEmpty) {
      map['notes'] = notes;
    }
    return map;
  }
}

/// Payload for `POST /api/v1/admin/scholarships/{id}/criteria/{criteria_id}/review`
class AdminCriteriaReviewRequest {
  const AdminCriteriaReviewRequest({
    required this.isVerified,
    this.notes,
  });

  final bool isVerified;
  final String? notes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'is_verified': isVerified};
    if (notes != null && notes!.isNotEmpty) map['notes'] = notes;
    return map;
  }
}

/// Payload for `POST /api/v1/admin/scholarships/{id}/publish` and `unpublish`
class AdminPublishRequest {
  const AdminPublishRequest({this.notes});

  final String? notes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (notes != null && notes!.isNotEmpty) map['notes'] = notes;
    return map;
  }
}
