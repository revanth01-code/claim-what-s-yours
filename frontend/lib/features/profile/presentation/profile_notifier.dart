import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claim_whats_yours/core/errors/api_exception.dart';
import '../domain/student_profile.dart';
import 'profile_providers.dart';

/// State of the student profile view/edit workflow.
@immutable
class StudentProfileState {
  const StudentProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final StudentProfile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  StudentProfileState copyWith({
    StudentProfile? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return StudentProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Controller managing loading and updating student profile.
class StudentProfileNotifier extends Notifier<StudentProfileState> {
  @override
  StudentProfileState build() {
    Future.microtask(() => loadProfile());
    return const StudentProfileState(isLoading: true);
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final repo = ref.read(studentProfileRepositoryProvider);
      final profile = await repo.getProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to load profile.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<bool> saveProfile(StudentProfile updated) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final repo = ref.read(studentProfileRepositoryProvider);
      final saved = await repo.updateProfile(updated);
      state = state.copyWith(
        profile: saved,
        isSaving: false,
        successMessage: 'Profile saved successfully.',
      );
      // Invalidate completion provider so dashboard and badges refresh
      ref.invalidate(studentProfileCompletionProvider);
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to save profile.';
      state = state.copyWith(isSaving: false, errorMessage: msg);
      return false;
    }
  }
}
