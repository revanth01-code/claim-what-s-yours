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

/// Full interactive profile screen displaying personal, academic, and financial details,
/// along with edit modal dialogs, profile completion, and role switching.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: ResponsiveContentContainer(
          child: AppEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign In Required',
            message: 'Please sign in to view and manage your student profile and eligibility attributes.',
            actionLabel: 'Sign In',
            onAction: () => context.push(RoutePaths.auth),
          ),
        ),
      );
    }

    final user = authState.user!;
    final profileState = ref.watch(studentProfileNotifierProvider);
    final completionAsync = ref.watch(studentProfileCompletionProvider);

    if (profileState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: const Center(child: AppLoading(message: 'Loading student profile...')),
      );
    }

    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(studentProfileNotifierProvider.notifier).loadProfile();
              ref.invalidate(studentProfileCompletionProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ResponsiveContentContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Identity Header Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          (profile?.fullName?.isNotEmpty == true
                                  ? profile!.fullName![0]
                                  : (user.displayName?.isNotEmpty == true
                                      ? user.displayName![0]
                                      : 'S'))
                              .toUpperCase(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName ?? user.displayName ?? 'Student User',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? 'No email provided',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: user.isAdmin
                                        ? AppColors.primaryContainer
                                        : AppColors.secondaryContainer.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: user.isAdmin
                                          ? AppColors.onPrimaryContainer
                                          : AppColors.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (profile?.state != null) ...[
                                  Text(
                                    '${profile!.district ?? ''}, ${profile.state}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push(RoutePaths.onboarding),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Completion Card
              completionAsync.when(
                data: (completion) => _buildCompletionCard(context, completion),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Profile Details Grid / Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildPersonalCard(context, profile)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildAcademicAndFinancialCard(context, profile)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildPersonalCard(context, profile),
                      const SizedBox(height: 16),
                      _buildAcademicAndFinancialCard(context, profile),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Admin Portal Switcher (Visible only if backend confirms admin role)
              if (user.isAdmin) ...[
                Card(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Administrator Portal',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You possess verified administrator privileges to review sources, criteria, and publication queues.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: () => context.go(RoutePaths.admin),
                          child: const Text('Open Portal'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Sign Out Button
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard(BuildContext context, ProfileCompletion completion) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = completion.percentage == 100;

    return Card(
      elevation: 0,
      color: isDone
          ? AppColors.success.withValues(alpha: 0.08)
          : colorScheme.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone
              ? AppColors.success.withValues(alpha: 0.3)
              : colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDone ? Icons.verified_rounded : Icons.pie_chart_outline_rounded,
                  color: isDone ? AppColors.success : AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Profile Completeness: ${completion.percentage}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDone ? AppColors.success : AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (!isDone)
                  TextButton.icon(
                    onPressed: () => context.push(RoutePaths.onboarding),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Complete Now'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completion.percentage / 100.0,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
            if (!isDone) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: completion.sections.expand((sec) {
                  return sec.missingFields.map((f) => Chip(
                        label: Text('Missing $f'),
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 11),
                      ));
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalCard(BuildContext context, StudentProfile? profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_pin_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Personal Information',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailItem(label: 'Full Name', value: profile?.fullName ?? 'Not provided'),
            _DetailItem(
              label: 'Date of Birth',
              value: profile?.dateOfBirth != null
                  ? '${profile!.dateOfBirth!.day.toString().padLeft(2, '0')}/${profile.dateOfBirth!.month.toString().padLeft(2, '0')}/${profile.dateOfBirth!.year}'
                  : 'Not provided',
            ),
            _DetailItem(label: 'Gender', value: profile?.gender?.toUpperCase() ?? 'Not provided'),
            _DetailItem(label: 'State', value: profile?.state ?? 'Not provided'),
            _DetailItem(label: 'District', value: profile?.district ?? 'Not provided'),
            _DetailItem(label: 'Category', value: profile?.category?.toUpperCase() ?? 'Not provided'),
            _DetailItem(
              label: 'Disability Status',
              value: profile?.isDisabled == true
                  ? 'Yes (${profile?.disabilityType ?? "Benchmark"})'
                  : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicAndFinancialCard(BuildContext context, StudentProfile? profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_outlined, color: AppColors.secondary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Academic & Financial',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailItem(label: 'Education Level', value: profile?.educationLevel ?? 'Not provided'),
            _DetailItem(label: 'Course / Degree', value: profile?.course ?? 'Not provided'),
            _DetailItem(label: 'Institution', value: profile?.institutionName ?? 'Not provided'),
            _DetailItem(label: 'Academic Year', value: profile?.academicYear ?? '2026-2027'),
            _DetailItem(
              label: 'Prior Exam Score',
              value: profile?.previousExamPercentage != null
                  ? '${profile!.previousExamPercentage}%'
                  : 'Not provided',
            ),
            _DetailItem(
              label: 'Annual Family Income',
              value: profile?.annualFamilyIncome != null
                  ? '₹${profile!.annualFamilyIncome!.toStringAsFixed(0)}'
                  : 'Not provided',
            ),
            _DetailItem(
              label: 'Hostel Status',
              value: profile?.isHosteller == true ? 'Hosteller' : 'Day Scholar',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
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
