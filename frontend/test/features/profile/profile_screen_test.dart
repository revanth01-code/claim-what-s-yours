import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/features/auth/domain/app_user.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_state.dart';
import 'package:claim_whats_yours/features/profile/data/student_profile_repository.dart';
import 'package:claim_whats_yours/features/profile/domain/student_profile.dart';
import 'package:claim_whats_yours/features/onboarding/presentation/onboarding_screen.dart';
import 'package:claim_whats_yours/features/profile/presentation/profile_providers.dart';
import 'package:claim_whats_yours/features/profile/presentation/profile_screen.dart';

class _FakeStudentProfileRepository implements StudentProfileRepository {
  StudentProfile profile = const StudentProfile(
    id: 'prof-1',
    userId: 'user-1',
    fullName: 'Test Student',
    state: 'Telangana',
    district: 'Hyderabad',
    category: 'obc',
    educationLevel: 'undergraduate',
    course: 'B.Tech',
    institutionName: 'JNTUH',
    annualFamilyIncome: 150000.0,
  );

  ProfileCompletion completion = const ProfileCompletion(
    percentage: 75,
    isOnboardingCompleted: false,
    sections: [
      SectionCompletion(
        name: 'Personal',
        isCompleted: true,
        completedFields: 5,
        totalFields: 5,
        missingFields: [],
      ),
      SectionCompletion(
        name: 'Academic',
        isCompleted: false,
        completedFields: 4,
        totalFields: 5,
        missingFields: ['Previous Exam Percentage'],
      ),
    ],
  );

  bool updateCalled = false;

  @override
  Future<StudentProfile> getProfile() async => profile;

  @override
  Future<ProfileCompletion> getProfileCompletion() async => completion;

  @override
  Future<StudentProfile> updateProfile(StudentProfile p) async {
    updateCalled = true;
    profile = p;
    return profile;
  }
}

class _FakeAuthNotifier extends Notifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const studentUser = AppUser(
    id: 'user-1',
    email: 'student@cwy.org',
    emailVerified: true,
    displayName: 'Test Student',
    role: 'student',
    isActive: true,
  );

  group('ProfileScreen', () {
    testWidgets('renders student profile details and completion card', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = _FakeStudentProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentProfileRepositoryProvider.overrideWithValue(fakeRepo),
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                AuthState.authenticated(user: studentUser, firebaseUid: 'uid-1'),
              ),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Profile'), findsAtLeastNWidgets(1));
      expect(find.text('Test Student'), findsAtLeastNWidgets(1));
      expect(find.text('Profile Completeness: 75%'), findsOneWidget);
      expect(find.text('Hyderabad, Telangana'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
    });
  });

  group('OnboardingScreen', () {
    testWidgets('renders multi-step wizard and advances on save', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = _FakeStudentProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentProfileRepositoryProvider.overrideWithValue(fakeRepo),
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                AuthState.authenticated(user: studentUser, firebaseUid: 'uid-1'),
              ),
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete Your Profile'), findsOneWidget);
      expect(find.text('Step 1: Personal Details'), findsOneWidget);
      expect(find.text('Save & Continue'), findsOneWidget);

      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      expect(fakeRepo.updateCalled, isTrue);
      expect(find.text('Step 2: Academic Profile'), findsOneWidget);
    });
  });
}
