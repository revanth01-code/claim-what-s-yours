import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/features/admin/data/admin_json_parser.dart';
import 'package:claim_whats_yours/features/admin/domain/admin_requests.dart';

void main() {
  group('AdminJsonParser', () {
    test('parses OfficialSource response', () {
      final map = {
        'id': 'src-1',
        'source_url': 'https://scholarships.gov.in',
        'title': 'NSP Official',
        'authority': 'Govt',
        'source_type': 'official_portal',
        'verification_status': 'verified',
        'document_reference': 'DOC-123',
        'notes': 'Verified from portal',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };

      final source = parseOfficialSource(map);
      expect(source.id, 'src-1');
      expect(source.title, 'NSP Official');
      expect(source.verificationStatus, 'verified');
      expect(source.sourceUrl, 'https://scholarships.gov.in');
    });

    test('parses EligibilityCriterion response', () {
      final map = {
        'id': 'crit-1',
        'minimum_academic_percentage': '75.5',
        'maximum_academic_percentage': '100.0',
        'minimum_family_income': '0',
        'maximum_family_income': '250000',
        'education_levels': ['undergraduate'],
        'courses': ['B.Tech'],
        'categories': ['SC', 'ST'],
        'domicile_state': 'Karnataka',
        'gender_restriction': 'none',
        'disability_required': false,
        'renewal_only': false,
        'is_verified': true,
        'source_reference': 'Guidelines PDF p.4',
        'notes': 'Verified',
      };

      final criterion = parseEligibilityCriterion(map);
      expect(criterion.id, 'crit-1');
      expect(criterion.minimumAcademicPercentage, '75.5');
      expect(criterion.isVerified, isTrue);
      expect(criterion.domicileState, 'Karnataka');
    });

    test('parses list of AdminAuditLogs', () {
      final list = [
        {
          'id': 'log-1',
          'action': 'source_reviewed',
          'target_type': 'official_source',
          'admin_user_id': 'admin-uuid',
          'scholarship_id': 'sch-1',
          'target_id': 'src-1',
          'notes': 'Verified document',
          'created_at': '2026-01-02T10:00:00Z',
        }
      ];

      final logs = parseAuditLogs(list);
      expect(logs.length, 1);
      expect(logs.first.id, 'log-1');
      expect(logs.first.action, 'source_reviewed');
      expect(logs.first.targetType, 'official_source');
      expect(logs.first.notes, 'Verified document');
    });
  });

  group('Admin Request DTO Security Contract', () {
    test('AdminCriteriaCreateRequest toJson never contains is_verified', () {
      const createReq = AdminCriteriaCreateRequest(
        minimumAcademicPercentage: 80.0,
        maximumFamilyIncome: 500000.0,
        domicileState: 'Maharashtra',
        notes: 'Strict backend gate testing',
      );

      final json = createReq.toJson();
      expect(json.containsKey('is_verified'), isFalse,
          reason: 'Security requirement: criteria cannot be verified via create endpoint');
      expect(json['minimum_academic_percentage'], 80.0);
      expect(json['maximum_family_income'], 500000.0);
      expect(json['domicile_state'], 'Maharashtra');
    });

    test('AdminCriteriaUpdateRequest toJson never contains is_verified', () {
      const updateReq = AdminCriteriaUpdateRequest(
        minimumAcademicPercentage: 85.0,
        notes: 'Updating criteria percentage',
      );

      final json = updateReq.toJson();
      expect(json.containsKey('is_verified'), isFalse,
          reason: 'Security requirement: criteria cannot be verified via update endpoint');
      expect(json['minimum_academic_percentage'], 85.0);
    });

    test('AdminSourceReviewRequest formats correctly', () {
      const reviewReq = AdminSourceReviewRequest(
        status: 'verified',
        notes: 'Official portal link matches guidelines',
        authority: 'Ministry of Education',
        title: 'National Portal',
        documentReference: 'REF-999',
      );

      final json = reviewReq.toJson();
      expect(json['status'], 'verified');
      expect(json['notes'], 'Official portal link matches guidelines');
      expect(json['authority'], 'Ministry of Education');
      expect(json['title'], 'National Portal');
      expect(json['document_reference'], 'REF-999');
    });

    test('AdminCriteriaReviewRequest formats correctly', () {
      const reviewReq = AdminCriteriaReviewRequest(
        isVerified: true,
        notes: 'Approved criterion',
      );

      final json = reviewReq.toJson();
      expect(json['is_verified'], isTrue);
      expect(json['notes'], 'Approved criterion');
    });
  });
}
