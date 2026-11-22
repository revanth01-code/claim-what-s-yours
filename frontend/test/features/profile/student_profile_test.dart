import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/features/profile/domain/student_profile.dart';

void main() {
  group('StudentProfile Domain Model', () {
    test('parses from valid JSON with full fields', () {
      final json = {
        'id': 'prof-123',
        'user_id': 'user-456',
        'full_name': 'Aarav Sharma',
        'date_of_birth': '2004-05-15',
        'gender': 'male',
        'state': 'Telangana',
        'district': 'Hyderabad',
        'category': 'obc',
        'is_disabled': false,
        'education_level': 'undergraduate',
        'course': 'B.Tech',
        'stream': 'CSE',
        'institution_name': 'Osmania University',
        'academic_year': '2026-2027',
        'current_year_of_study': 2,
        'previous_exam_percentage': 88.5,
        'annual_family_income': 150000.0,
        'is_hosteller': true,
      };

      final profile = StudentProfile.fromJson(json);

      expect(profile.id, 'prof-123');
      expect(profile.userId, 'user-456');
      expect(profile.fullName, 'Aarav Sharma');
      expect(profile.dateOfBirth, DateTime.parse('2004-05-15'));
      expect(profile.state, 'Telangana');
      expect(profile.district, 'Hyderabad');
      expect(profile.category, 'obc');
      expect(profile.educationLevel, 'undergraduate');
      expect(profile.previousExamPercentage, 88.5);
      expect(profile.annualFamilyIncome, 150000.0);
      expect(profile.isHosteller, isTrue);
    });

    test('serializes to JSON accurately', () {
      final profile = StudentProfile(
        id: 'prof-1',
        userId: 'user-1',
        fullName: 'Priya Rao',
        dateOfBirth: DateTime(2005, 8, 20),
        state: 'Telangana',
        annualFamilyIncome: 200000.0,
      );

      final json = profile.toJson();
      expect(json['full_name'], 'Priya Rao');
      expect(json['date_of_birth'], '2005-08-20');
      expect(json['state'], 'Telangana');
      expect(json['annual_family_income'], 200000.0);
    });
  });

  group('ProfileCompletion Model', () {
    test('parses from backend response', () {
      final json = {
        'percentage': 80,
        'is_onboarding_completed': false,
        'sections': [
          {
            'name': 'Personal',
            'is_completed': true,
            'completed_fields': 5,
            'total_fields': 5,
            'missing_fields': [],
          },
          {
            'name': 'Academic',
            'is_completed': false,
            'completed_fields': 4,
            'total_fields': 5,
            'missing_fields': ['Previous Exam Percentage'],
          }
        ],
      };

      final completion = ProfileCompletion.fromJson(json);
      expect(completion.percentage, 80);
      expect(completion.isOnboardingCompleted, isFalse);
      expect(completion.sections.length, 2);
      expect(completion.sections.first.isCompleted, isTrue);
      expect(completion.sections[1].missingFields, contains('Previous Exam Percentage'));
    });
  });
}
