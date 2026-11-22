import 'package:flutter/foundation.dart';

@immutable
class ConditionEvaluation {
  const ConditionEvaluation({
    required this.field,
    required this.criterion,
    required this.reason,
    this.studentValue,
    this.passed,
  });

  final String field;
  final String criterion;
  final String reason;
  final dynamic studentValue;
  final bool? passed;

  factory ConditionEvaluation.fromJson(Map<String, dynamic> json) {
    return ConditionEvaluation(
      field: json['field'] as String? ?? '',
      criterion: json['criterion'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      studentValue: json['student_value'],
      passed: json['passed'] as bool?,
    );
  }
}

@immutable
class EligibilityEvaluationResult {
  const EligibilityEvaluationResult({
    required this.scholarshipId,
    required this.scholarshipName,
    required this.status,
    required this.summary,
    this.matchedConditions = const [],
    this.unmetConditions = const [],
    this.missingFields = const [],
    this.detailedEvaluations = const [],
    this.isCriteriaVerified = false,
  });

  final String scholarshipId;
  final String scholarshipName;
  final String status; // 'eligible', 'ineligible', 'needs_more_information', 'uncertain'
  final String summary;
  final List<String> matchedConditions;
  final List<String> unmetConditions;
  final List<String> missingFields;
  final List<ConditionEvaluation> detailedEvaluations;
  final bool isCriteriaVerified;

  bool get isEligible => status == 'eligible';
  bool get isNeedsInfo => status == 'needs_more_information';
  bool get isIneligible => status == 'ineligible';
  bool get isUncertain => status == 'uncertain';

  factory EligibilityEvaluationResult.fromJson(Map<String, dynamic> json) {
    return EligibilityEvaluationResult(
      scholarshipId: json['scholarship_id'] as String? ?? '',
      scholarshipName: json['scholarship_name'] as String? ?? '',
      status: json['status'] as String? ?? 'uncertain',
      summary: json['summary'] as String? ?? '',
      matchedConditions: (json['matched_conditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unmetConditions: (json['unmet_conditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      missingFields: (json['missing_fields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      detailedEvaluations: (json['detailed_evaluations'] as List<dynamic>?)
              ?.map((e) => ConditionEvaluation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isCriteriaVerified: json['is_criteria_verified'] as bool? ?? false,
    );
  }
}

@immutable
class StudentBatchEligibility {
  const StudentBatchEligibility({
    required this.evaluations,
    required this.totalEvaluated,
    required this.eligibleCount,
    required this.needsInfoCount,
    required this.ineligibleCount,
    required this.uncertainCount,
  });

  final List<EligibilityEvaluationResult> evaluations;
  final int totalEvaluated;
  final int eligibleCount;
  final int needsInfoCount;
  final int ineligibleCount;
  final int uncertainCount;

  factory StudentBatchEligibility.fromJson(Map<String, dynamic> json) {
    final list = (json['evaluations'] as List<dynamic>?)
            ?.map((e) => EligibilityEvaluationResult.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return StudentBatchEligibility(
      evaluations: list,
      totalEvaluated: json['total_evaluated'] as int? ?? 0,
      eligibleCount: json['eligible_count'] as int? ?? 0,
      needsInfoCount: json['needs_info_count'] as int? ?? 0,
      ineligibleCount: json['ineligible_count'] as int? ?? 0,
      uncertainCount: json['uncertain_count'] as int? ?? 0,
    );
  }
}
