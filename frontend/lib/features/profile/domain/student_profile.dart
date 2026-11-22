import 'package:flutter/foundation.dart';

/// Representation of student profile data returned by `GET /api/v1/students/me/profile`.
@immutable
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.state,
    this.district,
    this.category,
    this.isDisabled,
    this.disabilityType,
    this.disabilityPercentage,
    this.phoneNumber,
    this.educationLevel,
    this.course,
    this.stream,
    this.institutionName,
    this.institutionState,
    this.institutionDistrict,
    this.boardOrUniversity,
    this.academicYear,
    this.currentYearOfStudy,
    this.previousExamPercentage,
    this.annualFamilyIncome,
    this.incomeBracket,
    this.isHosteller,
    this.additionalAttributes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;

  // Personal
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? state;
  final String? district;
  final String? category;
  final bool? isDisabled;
  final String? disabilityType;
  final double? disabilityPercentage;
  final String? phoneNumber;

  // Academic
  final String? educationLevel;
  final String? course;
  final String? stream;
  final String? institutionName;
  final String? institutionState;
  final String? institutionDistrict;
  final String? boardOrUniversity;
  final String? academicYear;
  final int? currentYearOfStudy;
  final double? previousExamPercentage;

  // Financial
  final double? annualFamilyIncome;
  final String? incomeBracket;

  // Additional
  final bool? isHosteller;
  final Map<String, dynamic>? additionalAttributes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? state,
    String? district,
    String? category,
    bool? isDisabled,
    String? disabilityType,
    double? disabilityPercentage,
    String? phoneNumber,
    String? educationLevel,
    String? course,
    String? stream,
    String? institutionName,
    String? institutionState,
    String? institutionDistrict,
    String? boardOrUniversity,
    String? academicYear,
    int? currentYearOfStudy,
    double? previousExamPercentage,
    double? annualFamilyIncome,
    String? incomeBracket,
    bool? isHosteller,
    Map<String, dynamic>? additionalAttributes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      state: state ?? this.state,
      district: district ?? this.district,
      category: category ?? this.category,
      isDisabled: isDisabled ?? this.isDisabled,
      disabilityType: disabilityType ?? this.disabilityType,
      disabilityPercentage: disabilityPercentage ?? this.disabilityPercentage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      educationLevel: educationLevel ?? this.educationLevel,
      course: course ?? this.course,
      stream: stream ?? this.stream,
      institutionName: institutionName ?? this.institutionName,
      institutionState: institutionState ?? this.institutionState,
      institutionDistrict: institutionDistrict ?? this.institutionDistrict,
      boardOrUniversity: boardOrUniversity ?? this.boardOrUniversity,
      academicYear: academicYear ?? this.academicYear,
      currentYearOfStudy: currentYearOfStudy ?? this.currentYearOfStudy,
      previousExamPercentage: previousExamPercentage ?? this.previousExamPercentage,
      annualFamilyIncome: annualFamilyIncome ?? this.annualFamilyIncome,
      incomeBracket: incomeBracket ?? this.incomeBracket,
      isHosteller: isHosteller ?? this.isHosteller,
      additionalAttributes: additionalAttributes ?? this.additionalAttributes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return StudentProfile(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String?,
      dateOfBirth: parseDate(json['date_of_birth']),
      gender: json['gender'] as String?,
      state: json['state'] as String?,
      district: json['district'] as String?,
      category: json['category'] as String?,
      isDisabled: json['is_disabled'] as bool?,
      disabilityType: json['disability_type'] as String?,
      disabilityPercentage: parseDouble(json['disability_percentage']),
      phoneNumber: json['phone_number'] as String?,
      educationLevel: json['education_level'] as String?,
      course: json['course'] as String?,
      stream: json['stream'] as String?,
      institutionName: json['institution_name'] as String?,
      institutionState: json['institution_state'] as String?,
      institutionDistrict: json['institution_district'] as String?,
      boardOrUniversity: json['board_or_university'] as String?,
      academicYear: json['academic_year'] as String?,
      currentYearOfStudy: parseInt(json['current_year_of_study']),
      previousExamPercentage: parseDouble(json['previous_exam_percentage']),
      annualFamilyIncome: parseDouble(json['annual_family_income']),
      incomeBracket: json['income_bracket'] as String?,
      isHosteller: json['is_hosteller'] as bool?,
      additionalAttributes: json['additional_attributes'] is Map
          ? Map<String, dynamic>.from(json['additional_attributes'] as Map)
          : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (fullName != null) map['full_name'] = fullName;
    if (dateOfBirth != null) {
      map['date_of_birth'] =
          '${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}';
    }
    if (gender != null) map['gender'] = gender;
    if (state != null) map['state'] = state;
    if (district != null) map['district'] = district;
    if (category != null) map['category'] = category;
    if (isDisabled != null) map['is_disabled'] = isDisabled;
    if (disabilityType != null) map['disability_type'] = disabilityType;
    if (disabilityPercentage != null) {
      map['disability_percentage'] = disabilityPercentage;
    }
    if (phoneNumber != null) map['phone_number'] = phoneNumber;

    if (educationLevel != null) map['education_level'] = educationLevel;
    if (course != null) map['course'] = course;
    if (stream != null) map['stream'] = stream;
    if (institutionName != null) map['institution_name'] = institutionName;
    if (institutionState != null) map['institution_state'] = institutionState;
    if (institutionDistrict != null) {
      map['institution_district'] = institutionDistrict;
    }
    if (boardOrUniversity != null) map['board_or_university'] = boardOrUniversity;
    if (academicYear != null) map['academic_year'] = academicYear;
    if (currentYearOfStudy != null) {
      map['current_year_of_study'] = currentYearOfStudy;
    }
    if (previousExamPercentage != null) {
      map['previous_exam_percentage'] = previousExamPercentage;
    }

    if (annualFamilyIncome != null) {
      map['annual_family_income'] = annualFamilyIncome;
    }
    if (incomeBracket != null) map['income_bracket'] = incomeBracket;
    if (isHosteller != null) map['is_hosteller'] = isHosteller;
    if (additionalAttributes != null) {
      map['additional_attributes'] = additionalAttributes;
    }

    return map;
  }
}

/// Represents completion progress per section.
@immutable
class SectionCompletion {
  const SectionCompletion({
    required this.name,
    required this.isCompleted,
    required this.completedFields,
    required this.totalFields,
    required this.missingFields,
  });

  final String name;
  final bool isCompleted;
  final int completedFields;
  final int totalFields;
  final List<String> missingFields;

  factory SectionCompletion.fromJson(Map<String, dynamic> json) {
    return SectionCompletion(
      name: json['name'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      completedFields: json['completed_fields'] as int? ?? 0,
      totalFields: json['total_fields'] as int? ?? 0,
      missingFields: (json['missing_fields'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Overall completion response from backend.
@immutable
class ProfileCompletion {
  const ProfileCompletion({
    required this.percentage,
    required this.isOnboardingCompleted,
    required this.sections,
  });

  final int percentage;
  final bool isOnboardingCompleted;
  final List<SectionCompletion> sections;

  factory ProfileCompletion.empty() {
    return const ProfileCompletion(
      percentage: 0,
      isOnboardingCompleted: false,
      sections: [],
    );
  }

  factory ProfileCompletion.fromJson(Map<String, dynamic> json) {
    return ProfileCompletion(
      percentage: json['percentage'] as int? ?? 0,
      isOnboardingCompleted: json['is_onboarding_completed'] as bool? ?? false,
      sections: (json['sections'] as List?)
              ?.map((item) =>
                  SectionCompletion.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }
}
