import 'package:flutter/foundation.dart';

@immutable
class ApplicationTimelineItem {
  const ApplicationTimelineItem({
    required this.status,
    required this.timestamp,
    this.note,
  });

  final String status;
  final DateTime timestamp;
  final String? note;

  factory ApplicationTimelineItem.fromJson(Map<String, dynamic> json) {
    return ApplicationTimelineItem(
      status: json['status'] as String? ?? 'submitted',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
    );
  }
}

@immutable
class ApplicationRecordItem {
  const ApplicationRecordItem({
    required this.id,
    required this.userId,
    required this.scholarshipId,
    required this.scholarshipName,
    required this.portalName,
    required this.applicationReferenceNumber,
    required this.status,
    required this.academicYear,
    this.appliedAmount,
    this.disbursedAmount,
    this.notes,
    this.submittedAt,
    this.timeline = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String scholarshipId;
  final String scholarshipName;
  final String portalName;
  final String applicationReferenceNumber;
  final String status; // 'interested', 'preparing', 'draft', 'submitted', 'under_review', 'approved', 'disbursed', 'rejected', 'withdrawn'
  final String academicYear;
  final double? appliedAmount;
  final double? disbursedAmount;
  final String? notes;
  final DateTime? submittedAt;
  final List<ApplicationTimelineItem> timeline;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ApplicationRecordItem.fromJson(Map<String, dynamic> json) {
    return ApplicationRecordItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      scholarshipId: json['scholarship_id'] as String? ?? '',
      scholarshipName: json['scholarship_name'] as String? ?? 'Scholarship',
      portalName: json['portal_name'] as String? ?? '',
      applicationReferenceNumber: json['application_reference_number'] as String? ?? '',
      status: json['status'] as String? ?? 'submitted',
      academicYear: json['academic_year'] as String? ?? '2026-2027',
      appliedAmount: (json['applied_amount'] as num?)?.toDouble(),
      disbursedAmount: (json['disbursed_amount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at'] as String) : null,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => ApplicationTimelineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
