import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/features/scholarships/data/scholarship_json_parser.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

const String _scholarshipId = '3fa85f64-5717-4562-b3fc-2c963f66afa6';
const String _criterionId = '7b1f6c2e-3a4d-4e5f-8a9b-0c1d2e3f4a5b';
const String _academicYearId = '1d2e3f40-aaaa-4bbb-8ccc-123456789abc';
const String _sourceId = '9e107d9d-372b-4bd0-9d4b-8f6e2a1c5b7d';

/// A full `ScholarshipResponse`-shaped map. Built fresh on each call so tests
/// can mutate it freely.
Map<String, dynamic> _scholarshipJson() {
  return <String, dynamic>{
    'id': _scholarshipId,
    'name': 'National Merit Scholarship',
    'slug': 'national-merit-scholarship',
    'description': 'Supports students from reserved categories.',
    'administering_authority': 'Ministry of Education',
    'category': 'sc',
    'benefits': <Map<String, dynamic>>[
      {'annual_amount': '50000'},
      {'hostel_allowance': 'yes'},
    ],
    'application_url': 'https://example.gov/apply',
    'is_active': true,
    'created_at': '2025-06-01T10:00:00Z',
    'updated_at': '2025-07-15T08:30:00+05:30',
    'eligibility_criteria': <Map<String, dynamic>>[
      {
        'id': _criterionId,
        'academic_year_id': _academicYearId,
        'minimum_academic_percentage': '60.00',
        'maximum_academic_percentage': null,
        'minimum_family_income': '250000.00',
        'maximum_family_income': null,
        'education_levels': <String>['undergraduate'],
        'courses': <String>['engineering'],
        'categories': <String>['sc'],
        'domicile_state': 'Karnataka',
        'gender_restriction': null,
        'disability_required': false,
        'renewal_only': false,
        'is_verified': true,
        'source_reference': 'GO-2025-114',
      },
    ],
    'academic_years': <Map<String, dynamic>>[
      {
        'academic_year': '2025-26',
        'starts_on': '2025-07-01',
        'ends_on': '2026-06-30',
        'is_available': true,
        'opening_date': '2025-06-01',
        'closing_date': '2025-09-30',
        'name_override': null,
        'benefits_override': null,
        'application_url_override': null,
      },
    ],
    'sources': <Map<String, dynamic>>[
      {
        'id': _sourceId,
        'source_url': 'https://example.gov/gazette/114',
        'authority': 'Ministry of Education',
        'source_type': 'gazette',
        'verification_status': 'verified',
        'title': 'Government Order 114',
        'document_reference': 'GO-2025-114',
        'last_verified_at': '2025-07-10T00:00:00Z',
        'verified_by': 'Verification Desk',
      },
    ],
  };
}

Map<String, dynamic> _sourceJson(String verificationStatus) {
  return <String, dynamic>{
    'id': _sourceId,
    'source_url': 'https://example.gov/gazette/114',
    'authority': 'Ministry of Education',
    'source_type': 'gazette',
    'verification_status': verificationStatus,
  };
}

void main() {
  group('parseScholarship', () {
    test('parses every field of a full valid payload', () {
      final scholarship = parseScholarship(_scholarshipJson());

      expect(scholarship.id, _scholarshipId);
      expect(scholarship.name, 'National Merit Scholarship');
      expect(scholarship.slug, 'national-merit-scholarship');
      expect(
        scholarship.description,
        'Supports students from reserved categories.',
      );
      expect(scholarship.administeringAuthority, 'Ministry of Education');
      expect(scholarship.category, 'sc');
      expect(scholarship.categoryValue, ScholarshipCategory.sc);
      expect(scholarship.applicationUrl, 'https://example.gov/apply');
      expect(scholarship.isActive, isTrue);
      expect(scholarship.createdAt, DateTime.utc(2025, 6, 1, 10));
      // 08:30 at +05:30 is 03:00 UTC.
      expect(scholarship.updatedAt.toUtc(), DateTime.utc(2025, 7, 15, 3));

      expect(scholarship.benefits.map((b) => b.key), [
        'annual_amount',
        'hostel_allowance',
      ]);
      expect(scholarship.benefits.first.value, '50000');

      expect(scholarship.eligibilityCriteria, hasLength(1));
      final criterion = scholarship.eligibilityCriteria.single;
      expect(criterion.id, _criterionId);
      expect(criterion.academicYearId, _academicYearId);
      expect(criterion.minimumAcademicPercentage, '60.00');
      expect(criterion.minimumFamilyIncome, '250000.00');
      expect(criterion.maximumAcademicPercentage, isNull);
      expect(criterion.educationLevels, ['undergraduate']);
      expect(criterion.categories, ['sc']);
      expect(criterion.domicileState, 'Karnataka');
      expect(criterion.disabilityRequired, isFalse);
      expect(criterion.renewalOnly, isFalse);
      expect(criterion.isVerified, isTrue);
      expect(criterion.sourceReference, 'GO-2025-114');

      expect(scholarship.academicYears, hasLength(1));
      final year = scholarship.academicYears.single;
      expect(year.academicYear, '2025-26');
      expect(year.startsOn, DateTime(2025, 7, 1));
      expect(year.endsOn, DateTime(2026, 6, 30));
      expect(year.isAvailable, isTrue);
      expect(year.closingDate, DateTime(2025, 9, 30));
      expect(year.benefitsOverride, isNull);

      expect(scholarship.sources, hasLength(1));
      final source = scholarship.sources.single;
      expect(source.id, _sourceId);
      expect(source.sourceUrl, 'https://example.gov/gazette/114');
      expect(source.sourceType, 'gazette');
      expect(source.verificationStatus, 'verified');
      expect(source.title, 'Government Order 114');
      expect(source.lastVerifiedAt?.toUtc(), DateTime.utc(2025, 7, 10));
      expect(source.verifiedBy, 'Verification Desk');
      expect(scholarship.hasVerifiedSource, isTrue);
    });

    test('missing optional fields become null or empty without throwing', () {
      final json = _scholarshipJson()
        ..remove('description')
        ..remove('application_url')
        ..remove('benefits')
        ..remove('eligibility_criteria')
        ..remove('academic_years')
        ..remove('sources');

      final scholarship = parseScholarship(json);

      expect(scholarship.description, isNull);
      expect(scholarship.applicationUrl, isNull);
      expect(scholarship.benefits, isEmpty);
      expect(scholarship.eligibilityCriteria, isEmpty);
      expect(scholarship.academicYears, isEmpty);
      expect(scholarship.sources, isEmpty);
      expect(scholarship.hasVerifiedSource, isFalse);
    });

    test('wrongly typed optional fields become null', () {
      final json = _scholarshipJson()
        ..['description'] = 42
        ..['application_url'] = ['https://example.gov/apply']
        ..['academic_years'] = 'not-a-list';

      final scholarship = parseScholarship(json);

      expect(scholarship.description, isNull);
      expect(scholarship.applicationUrl, isNull);
      expect(scholarship.academicYears, isEmpty);
      expect(scholarship.name, 'National Merit Scholarship');
    });

    test(
      'missing required name throws ScholarshipParseException naming the field',
      () {
        final json = _scholarshipJson()..remove('name');

        expect(
          () => parseScholarship(json),
          throwsA(
            isA<ScholarshipParseException>().having(
              (e) => e.message,
              'message',
              contains('"name"'),
            ),
          ),
        );
      },
    );

    test('invalid UUID for id throws ScholarshipParseException', () {
      final json = _scholarshipJson()..['id'] = 'not-a-uuid';

      expect(
        () => parseScholarship(json),
        throwsA(
          isA<ScholarshipParseException>().having(
            (e) => e.message,
            'message',
            contains('"id"'),
          ),
        ),
      );
    });

    test('unknown category string is preserved as raw and maps to null', () {
      final json = _scholarshipJson()..['category'] = 'tribal_special';

      final scholarship = parseScholarship(json);

      expect(scholarship.category, 'tribal_special');
      expect(scholarship.categoryValue, isNull);
    });

    test('hasVerifiedSource is true only when a source is verified, case-insensitively', () {
      Scholarship withStatuses(List<String> statuses) {
        final json = _scholarshipJson()
          ..['sources'] = [for (final s in statuses) _sourceJson(s)];
        return parseScholarship(json);
      }

      expect(withStatuses(['VERIFIED']).hasVerifiedSource, isTrue);
      expect(withStatuses(['Verified']).hasVerifiedSource, isTrue);
      expect(withStatuses(['pending', 'verified']).hasVerifiedSource, isTrue);
      expect(withStatuses(['pending']).hasVerifiedSource, isFalse);
      expect(withStatuses(['unverified']).hasVerifiedSource, isFalse);
      expect(withStatuses(['not_verified']).hasVerifiedSource, isFalse);
      expect(withStatuses([]).hasVerifiedSource, isFalse);
    });

    test('non-object input throws ScholarshipParseException', () {
      expect(
        () => parseScholarship(<Object?>[1, 2]),
        throwsA(isA<ScholarshipParseException>()),
      );
    });
  });

  group('parseScholarshipPage', () {
    test(
      'parses the list envelope with page, pageSize, total and totalPages',
      () {
        final envelope = <String, dynamic>{
          'data': [_scholarshipJson()],
          'meta': <String, dynamic>{
            'page': 2,
            'page_size': 20,
            'total': 41,
            'total_pages': 3,
          },
        };

        final page = parseScholarshipPage(envelope);

        expect(page.items, hasLength(1));
        expect(page.items.single.name, 'National Merit Scholarship');
        expect(page.page, 2);
        expect(page.pageSize, 20);
        expect(page.total, 41);
        expect(page.totalPages, 3);
      },
    );

    test('envelope missing meta throws ScholarshipParseException', () {
      final envelope = <String, dynamic>{
        'data': [_scholarshipJson()],
      };

      expect(
        () => parseScholarshipPage(envelope),
        throwsA(isA<ScholarshipParseException>()),
      );
    });

    test(
      'envelope whose data is not a list throws ScholarshipParseException',
      () {
        final envelope = <String, dynamic>{
          'data': 'oops',
          'meta': <String, dynamic>{
            'page': 1,
            'page_size': 20,
            'total': 0,
            'total_pages': 0,
          },
        };

        expect(
          () => parseScholarshipPage(envelope),
          throwsA(isA<ScholarshipParseException>()),
        );
      },
    );
  });
}
