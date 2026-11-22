import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/profile/domain/student_profile.dart';
import 'package:claim_whats_yours/features/profile/presentation/profile_providers.dart';
import 'package:claim_whats_yours/shared/widgets/app_empty_state.dart';
import 'package:claim_whats_yours/shared/widgets/app_loading.dart';
import 'package:claim_whats_yours/shared/widgets/responsive_content_container.dart';

/// Interactive, production-quality multi-step onboarding wizard for students.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;

  // Form Keys
  final _personalFormKey = GlobalKey<FormState>();
  final _academicFormKey = GlobalKey<FormState>();
  final _financialFormKey = GlobalKey<FormState>();

  // Personal Controllers
  late TextEditingController _fullNameCtrl;
  DateTime? _selectedDob;
  String? _selectedGender;
  late TextEditingController _stateCtrl;
  late TextEditingController _districtCtrl;
  String? _selectedCategory;
  bool _isDisabled = false;
  late TextEditingController _disabilityTypeCtrl;
  late TextEditingController _disabilityPercentageCtrl;
  late TextEditingController _phoneCtrl;

  // Academic Controllers
  String? _selectedEducationLevel;
  late TextEditingController _courseCtrl;
  late TextEditingController _streamCtrl;
  late TextEditingController _institutionNameCtrl;
  late TextEditingController _boardOrUniversityCtrl;
  String? _selectedAcademicYear;
  int? _selectedYearOfStudy;
  late TextEditingController _previousExamPercentageCtrl;

  // Financial & Additional Controllers
  late TextEditingController _familyIncomeCtrl;
  bool _isHosteller = false;

  bool _initializedFromProfile = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _disabilityTypeCtrl = TextEditingController();
    _disabilityPercentageCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();

    _courseCtrl = TextEditingController();
    _streamCtrl = TextEditingController();
    _institutionNameCtrl = TextEditingController();
    _boardOrUniversityCtrl = TextEditingController();
    _previousExamPercentageCtrl = TextEditingController();

    _familyIncomeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _stateCtrl.dispose();
    _districtCtrl.dispose();
    _disabilityTypeCtrl.dispose();
    _disabilityPercentageCtrl.dispose();
    _phoneCtrl.dispose();

    _courseCtrl.dispose();
    _streamCtrl.dispose();
    _institutionNameCtrl.dispose();
    _boardOrUniversityCtrl.dispose();
    _previousExamPercentageCtrl.dispose();

    _familyIncomeCtrl.dispose();
    super.dispose();
  }

  void _populateFromProfile(StudentProfile profile) {
    if (_initializedFromProfile) return;
    _initializedFromProfile = true;

    _fullNameCtrl.text = profile.fullName ?? '';
    _selectedDob = profile.dateOfBirth;
    _selectedGender = profile.gender;
    _stateCtrl.text = profile.state ?? 'Telangana';
    _districtCtrl.text = profile.district ?? '';
    _selectedCategory = profile.category;
    _isDisabled = profile.isDisabled ?? false;
    _disabilityTypeCtrl.text = profile.disabilityType ?? '';
    if (profile.disabilityPercentage != null) {
      _disabilityPercentageCtrl.text = profile.disabilityPercentage.toString();
    }
    _phoneCtrl.text = profile.phoneNumber ?? '';

    _selectedEducationLevel = profile.educationLevel ?? 'undergraduate';
    _courseCtrl.text = profile.course ?? '';
    _streamCtrl.text = profile.stream ?? '';
    _institutionNameCtrl.text = profile.institutionName ?? '';
    _boardOrUniversityCtrl.text = profile.boardOrUniversity ?? '';
    _selectedAcademicYear = profile.academicYear ?? '2026-2027';
    _selectedYearOfStudy = profile.currentYearOfStudy ?? 1;
    if (profile.previousExamPercentage != null) {
      _previousExamPercentageCtrl.text = profile.previousExamPercentage.toString();
    }

    if (profile.annualFamilyIncome != null) {
      _familyIncomeCtrl.text = profile.annualFamilyIncome!.toStringAsFixed(0);
    }
    _isHosteller = profile.isHosteller ?? false;
  }

  StudentProfile _collectProfile(String id, String userId) {
    return StudentProfile(
      id: id,
      userId: userId,
      fullName: _fullNameCtrl.text.trim().isEmpty ? null : _fullNameCtrl.text.trim(),
      dateOfBirth: _selectedDob,
      gender: _selectedGender,
      state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      district: _districtCtrl.text.trim().isEmpty ? null : _districtCtrl.text.trim(),
      category: _selectedCategory,
      isDisabled: _isDisabled,
      disabilityType: _isDisabled ? _disabilityTypeCtrl.text.trim() : null,
      disabilityPercentage: _isDisabled ? double.tryParse(_disabilityPercentageCtrl.text.trim()) : null,
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      educationLevel: _selectedEducationLevel,
      course: _courseCtrl.text.trim().isEmpty ? null : _courseCtrl.text.trim(),
      stream: _streamCtrl.text.trim().isEmpty ? null : _streamCtrl.text.trim(),
      institutionName: _institutionNameCtrl.text.trim().isEmpty ? null : _institutionNameCtrl.text.trim(),
      boardOrUniversity: _boardOrUniversityCtrl.text.trim().isEmpty ? null : _boardOrUniversityCtrl.text.trim(),
      academicYear: _selectedAcademicYear,
      currentYearOfStudy: _selectedYearOfStudy,
      previousExamPercentage: double.tryParse(_previousExamPercentageCtrl.text.trim()),
      annualFamilyIncome: double.tryParse(_familyIncomeCtrl.text.trim()),
      isHosteller: _isHosteller,
    );
  }

  Future<void> _handleNext(StudentProfile profile) async {
    if (_currentStep == 0) {
      if (!_personalFormKey.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (!_academicFormKey.currentState!.validate()) return;
    } else if (_currentStep == 2) {
      if (!_financialFormKey.currentState!.validate()) return;
    }

    // Save partial progress to backend
    final updated = _collectProfile(profile.id, profile.userId);
    final success = await ref.read(studentProfileNotifierProvider.notifier).saveProfile(updated);

    if (!success) return;

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Step 3 was Review & Confirm -> Onboarding completed, navigate to Home
      if (mounted) {
        context.go(RoutePaths.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Onboarding')),
        body: ResponsiveContentContainer(
          child: AppEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign In Required',
            message: 'Please sign in to complete your student profile and discover eligible scholarships.',
            actionLabel: 'Sign In',
            onAction: () => context.push(RoutePaths.auth),
          ),
        ),
      );
    }

    final profileState = ref.watch(studentProfileNotifierProvider);

    if (profileState.isLoading) {
      return const Scaffold(
        body: Center(child: AppLoading(message: 'Loading your student profile...')),
      );
    }

    final profile = profileState.profile;
    if (profile != null) {
      _populateFromProfile(profile);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile Setup'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(RoutePaths.home),
            icon: const Icon(Icons.close),
            label: const Text('Skip for now'),
          ),
        ],
      ),
      body: ResponsiveContentContainer(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Text(
                'Complete Your Profile',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Accurate personal, academic and financial details ensure you receive matched scholarship recommendations and automated eligibility checks.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Stepper progress indicator
              _buildProgressHeader(theme),
              const SizedBox(height: 24),

              // Step Content Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentStep == 0) _buildPersonalStep(theme),
                      if (_currentStep == 1) _buildAcademicStep(theme),
                      if (_currentStep == 2) _buildFinancialStep(theme),
                      if (_currentStep == 3) _buildReviewStep(theme, profile ?? const StudentProfile(id: '', userId: '')),

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Navigation buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep > 0)
                            OutlinedButton.icon(
                              onPressed: profileState.isSaving
                                  ? null
                                  : () => setState(() => _currentStep--),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back'),
                            )
                          else
                            const SizedBox.shrink(),
                          FilledButton.icon(
                            onPressed: profileState.isSaving
                                ? null
                                : () => _handleNext(profile ?? const StudentProfile(id: '', userId: '')),
                            icon: profileState.isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(_currentStep == 3 ? Icons.check_circle_outline : Icons.arrow_forward),
                            label: Text(
                              _currentStep == 3 ? 'Finish & Explore Scholarships' : 'Save & Continue',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme) {
    final steps = ['Personal', 'Academic', 'Financial', 'Review'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepBefore = index ~/ 2;
          final isPast = stepBefore < _currentStep;
          return Expanded(
            child: Container(
              height: 3,
              color: isPast ? AppColors.primary : theme.colorScheme.outlineVariant,
            ),
          );
        }
        final stepIndex = index ~/ 2;
        final isActive = stepIndex == _currentStep;
        final isCompleted = stepIndex < _currentStep;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isCompleted
                  ? AppColors.primary
                  : (isActive ? AppColors.primaryContainer : theme.colorScheme.surfaceContainerHighest),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                  : Text(
                      '${stepIndex + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              steps[stepIndex],
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPersonalStep(ThemeData theme) {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Personal Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              hintText: 'Enter your full official name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required.' : null,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDob ?? DateTime(2005, 1, 1),
                firstDate: DateTime(1970),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDob = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth *',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _selectedDob == null
                    ? 'Select your date of birth'
                    : '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.wc_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _selectedGender = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Domicile State *',
                    hintText: 'e.g., Telangana',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'State is required.' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'District *',
                    hintText: 'e.g., Hyderabad',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'District is required.' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Community / Category *',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'sc', child: Text('Scheduled Caste (SC)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'st', child: Text('Scheduled Tribe (ST)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'obc', child: Text('Other Backward Classes (OBC)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'ebc', child: Text('Economically Backward Classes (EBC)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'minority', child: Text('Minority', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'general', child: Text('General', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _selectedCategory = v),
            validator: (v) => v == null ? 'Please select your category.' : null,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Person with Benchmark Disability (PwD)?'),
            value: _isDisabled,
            onChanged: (v) => setState(() => _isDisabled = v ?? false),
          ),
          if (_isDisabled) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _disabilityTypeCtrl,
              decoration: const InputDecoration(labelText: 'Disability Type / Nature'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _disabilityPercentageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Disability Percentage (%)',
                hintText: 'e.g. 40',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAcademicStep(ThemeData theme) {
    return Form(
      key: _academicFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Academic Profile',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedEducationLevel,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Current Education Level *',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'secondary', child: Text('Secondary (Class 9-10)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'higher_secondary', child: Text('Higher Secondary (Intermediate / 10+2)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'undergraduate', child: Text('Undergraduate (Degree / B.Tech / MBBS)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'postgraduate', child: Text('Postgraduate (Masters)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'doctorate', child: Text('Doctorate / Ph.D', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _selectedEducationLevel = v),
            validator: (v) => v == null ? 'Please select education level.' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _courseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course / Degree *',
                    hintText: 'e.g. B.Tech',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Course is required.' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _streamCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Stream / Specialization',
                    hintText: 'e.g. Computer Science',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _institutionNameCtrl,
            decoration: const InputDecoration(
              labelText: 'College / Institution Name *',
              prefixIcon: Icon(Icons.account_balance_outlined),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Institution name is required.' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYearOfStudy,
                  decoration: const InputDecoration(labelText: 'Current Year of Study'),
                  items: List.generate(5, (index) => DropdownMenuItem(value: index + 1, child: Text('Year ${index + 1}'))),
                  onChanged: (v) => setState(() => _selectedYearOfStudy = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _previousExamPercentageCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Prior Exam % / CGPA *',
                    hintText: 'e.g. 85.0',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Score is required.';
                    final num = double.tryParse(v);
                    if (num == null || num < 0 || num > 100) return 'Valid 0-100% required.';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialStep(ThemeData theme) {
    return Form(
      key: _financialFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Income & Living Status',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Government scholarship eligibility strictly relies on total household income guidelines. Never provide sensitive financial credentials.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _familyIncomeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Annual Family Income (in INR ₹) *',
              hintText: 'e.g. 150000',
              prefixIcon: Icon(Icons.currency_rupee_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Income is required.';
              final num = double.tryParse(v);
              if (num == null || num < 0) return 'Please enter a valid positive number.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Are you staying in an accredited hostel?'),
            subtitle: const Text('Many state post-matric schemes provide enhanced allowances for hostellers.'),
            value: _isHosteller,
            onChanged: (v) => setState(() => _isHosteller = v),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(ThemeData theme, StudentProfile profile) {
    final name = _fullNameCtrl.text.trim();
    final state = _stateCtrl.text.trim();
    final district = _districtCtrl.text.trim();
    final course = _courseCtrl.text.trim();
    final college = _institutionNameCtrl.text.trim();
    final income = _familyIncomeCtrl.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Text(
              'Step 4: Review Your Profile',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Please confirm your information. You can update any of these details at any time from your profile screen.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        _ReviewItem(label: 'Full Name', value: name.isEmpty ? 'Not set' : name),
        _ReviewItem(label: 'Location', value: '$district, $state'),
        _ReviewItem(label: 'Category', value: _selectedCategory?.toUpperCase() ?? 'Not specified'),
        _ReviewItem(label: 'Education Level', value: _selectedEducationLevel ?? 'Not set'),
        _ReviewItem(label: 'Course & College', value: '$course at $college'),
        _ReviewItem(label: 'Prior Score', value: '${_previousExamPercentageCtrl.text.trim()}%'),
        _ReviewItem(label: 'Annual Income', value: '₹$income / annum'),
        _ReviewItem(label: 'Living Status', value: _isHosteller ? 'Hosteller' : 'Day Scholar'),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
