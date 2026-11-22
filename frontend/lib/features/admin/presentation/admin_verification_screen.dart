import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/shared/widgets/app_error.dart';
import 'package:claim_whats_yours/shared/widgets/app_loading.dart';
import '../domain/admin_requests.dart';
import 'admin_providers.dart';
import 'admin_verification_notifier.dart';
import 'widgets/audit_history_sheet.dart';
import 'widgets/confirmation_dialog.dart';
import 'widgets/criteria_form_dialog.dart';
import 'widgets/criteria_review_card.dart';
import 'widgets/source_review_card.dart';

/// Screen for reviewing an individual scholarship's sources, criteria, and publication status.
class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({
    super.key,
    required this.scholarshipId,
  });

  final String scholarshipId;

  @override
  ConsumerState<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends ConsumerState<AdminVerificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(adminVerificationNotifierProvider.notifier).loadScholarship(widget.scholarshipId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(adminVerificationNotifierProvider);
    final controller = ref.read(adminVerificationNotifierProvider.notifier);

    // Listen for error or success notifications
    ref.listen<AdminVerificationState>(
      adminVerificationNotifierProvider,
      (prev, next) {
        if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (next.successMessage != null && next.successMessage != prev?.successMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Scholarship')),
        body: const Center(
          child: AppLoading(message: 'Loading scholarship verification details...'),
        ),
      );
    }

    final scholarship = state.scholarship;
    if (scholarship == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Scholarship')),
        body: Center(
          child: AppError(
            title: 'Scholarship Not Found',
            message: state.errorMessage ?? 'Could not find details for this scholarship.',
            onRetry: controller.reload,
          ),
        ),
      );
    }

    // Gate checks
    final hasVerifiedSource = scholarship.sources.any((s) => s.verificationStatus == 'verified');
    final hasCriteria = scholarship.eligibilityCriteria.isNotEmpty;
    final allCriteriaVerified = hasCriteria && scholarship.eligibilityCriteria.every((c) => c.isVerified);
    final hasAcademicYear = scholarship.academicYears.isNotEmpty;

    final isPublicationReady = hasVerifiedSource && allCriteriaVerified && hasAcademicYear;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.admin),
        ),
        title: Text(
          scholarship.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'View Audit Trail',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _openAuditLogs(context),
          ),
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: controller.reload,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                scholarship.category.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: scholarship.isActive
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                scholarship.isActive ? 'PUBLISHED' : 'PENDING PUBLICATION',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scholarship.isActive ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (state.isActionInProgress)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          scholarship.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Authority: ${scholarship.administeringAuthority}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (scholarship.applicationUrl?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Portal URL: ${scholarship.applicationUrl}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Publication Gate Checklist
                Card(
                  color: isPublicationReady
                      ? AppColors.success.withValues(alpha: 0.08)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isPublicationReady
                          ? AppColors.success.withValues(alpha: 0.4)
                          : colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isPublicationReady
                                  ? Icons.verified_rounded
                                  : Icons.fact_check_outlined,
                              color: isPublicationReady ? AppColors.success : colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Publication Requirements Gate',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (isPublicationReady && !scholarship.isActive)
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: AppColors.onPrimary,
                                ),
                                onPressed: state.isActionInProgress
                                    ? null
                                    : () => _confirmPublish(context, controller),
                                icon: const Icon(Icons.publish_rounded, size: 16),
                                label: const Text('Publish Scholarship'),
                              )
                            else if (scholarship.isActive)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                ),
                                onPressed: state.isActionInProgress
                                    ? null
                                    : () => _confirmUnpublish(context, controller),
                                icon: const Icon(Icons.unpublished_outlined, size: 16),
                                label: const Text('Unpublish'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _GateItem(
                              title: 'Official Source',
                              isMet: hasVerifiedSource,
                              description: hasVerifiedSource
                                  ? 'At least 1 verified source'
                                  : 'No verified source',
                            ),
                            _GateItem(
                              title: 'Eligibility Criteria',
                              isMet: allCriteriaVerified,
                              description: allCriteriaVerified
                                  ? 'All criteria verified'
                                  : (hasCriteria ? 'Some criteria pending' : 'No criteria added'),
                            ),
                            _GateItem(
                              title: 'Academic Year',
                              isMet: hasAcademicYear,
                              description: hasAcademicYear
                                  ? 'Academic year associated'
                                  : 'No academic year',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main content: Sources and Criteria
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildSourcesSection(context, controller, scholarship, state),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildCriteriaSection(context, controller, scholarship, state),
                      ),
                    ],
                  )
                else ...[
                  _buildSourcesSection(context, controller, scholarship, state),
                  const SizedBox(height: 24),
                  _buildCriteriaSection(context, controller, scholarship, state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourcesSection(
    BuildContext context,
    AdminVerificationNotifier controller,
    dynamic scholarship,
    AdminVerificationState state,
  ) {
    final theme = Theme.of(context);
    final sources = scholarship.sources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.link_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Official Sources (${sources.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sources.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No official sources associated with this scholarship.'),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sources.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final src = sources[index];
              return SourceReviewCard(
                source: src,
                isActionInProgress: state.isActionInProgress,
                onVerify: ({
                  required String authority,
                  required String documentReference,
                  required String notes,
                  required String title,
                }) {
                  controller.reviewSource(
                    sourceId: src.id,
                    status: 'verified',
                    notes: notes,
                    authority: authority,
                    title: title,
                    documentReference: documentReference,
                  );
                },
                onReject: (notes) {
                  controller.reviewSource(
                    sourceId: src.id,
                    status: 'rejected',
                    notes: notes,
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildCriteriaSection(
    BuildContext context,
    AdminVerificationNotifier controller,
    dynamic scholarship,
    AdminVerificationState state,
  ) {
    final theme = Theme.of(context);
    final criteria = scholarship.eligibilityCriteria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rule_rounded, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Eligibility Criteria (${criteria.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: state.isActionInProgress
                  ? null
                  : () => _openAddCriteriaDialog(context, controller),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Criteria'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (criteria.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.rule_folder_outlined, size: 36, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      'No eligibility criteria have been imported or added.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A scholarship cannot be published without reviewed criteria.',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: criteria.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = criteria[index];
              return CriteriaReviewCard(
                criterion: c,
                index: index + 1,
                isActionInProgress: state.isActionInProgress,
                onApprove: () {
                  controller.reviewCriteria(
                    criteriaId: c.id,
                    isVerified: true,
                    notes: 'Criteria verified by administrator.',
                  );
                },
                onReject: (notes) {
                  controller.reviewCriteria(
                    criteriaId: c.id,
                    isVerified: false,
                    notes: notes,
                  );
                },
                onEdit: () => _openEditCriteriaDialog(context, controller, c),
              );
            },
          ),
      ],
    );
  }

  void _openAddCriteriaDialog(
    BuildContext context,
    AdminVerificationNotifier controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => CriteriaFormDialog(
        onSubmit: ({
          List<String>? categories,
          List<String>? courses,
          bool? disabilityRequired,
          String? domicileState,
          List<String>? educationLevels,
          String? genderRestriction,
          double? maxIncome,
          double? maxPercentage,
          double? minIncome,
          double? minPercentage,
          String? notes,
          bool renewalOnly = false,
          String? sourceReference,
        }) {
          controller.createCriteria(
            AdminCriteriaCreateRequest(
              minimumAcademicPercentage: minPercentage,
              maximumAcademicPercentage: maxPercentage,
              minimumFamilyIncome: minIncome,
              maximumFamilyIncome: maxIncome,
              educationLevels: educationLevels,
              courses: courses,
              categories: categories,
              domicileState: domicileState,
              genderRestriction: genderRestriction,
              disabilityRequired: disabilityRequired,
              renewalOnly: renewalOnly,
              sourceReference: sourceReference,
              notes: notes,
            ),
          );
        },
      ),
    );
  }

  void _openEditCriteriaDialog(
    BuildContext context,
    AdminVerificationNotifier controller,
    dynamic criterion,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => CriteriaFormDialog(
        initialCriterion: criterion,
        onSubmit: ({
          List<String>? categories,
          List<String>? courses,
          bool? disabilityRequired,
          String? domicileState,
          List<String>? educationLevels,
          String? genderRestriction,
          double? maxIncome,
          double? maxPercentage,
          double? minIncome,
          double? minPercentage,
          String? notes,
          bool renewalOnly = false,
          String? sourceReference,
        }) {
          controller.updateCriteria(
            criterion.id,
            AdminCriteriaUpdateRequest(
              minimumAcademicPercentage: minPercentage,
              maximumAcademicPercentage: maxPercentage,
              minimumFamilyIncome: minIncome,
              maximumFamilyIncome: maxIncome,
              educationLevels: educationLevels,
              courses: courses,
              categories: categories,
              domicileState: domicileState,
              genderRestriction: genderRestriction,
              disabilityRequired: disabilityRequired,
              renewalOnly: renewalOnly,
              sourceReference: sourceReference,
              notes: notes,
            ),
          );
        },
      ),
    );
  }

  void _confirmPublish(BuildContext context, AdminVerificationNotifier controller) {
    final notesCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Publish Scholarship to Student Catalogue?',
        message:
            'This action will activate the scholarship and make it immediately discoverable and accessible to all students in the public catalogue.\n\nAll official source and eligibility criteria gates will be strictly validated by the backend before completion.',
        confirmLabel: 'Confirm & Publish',
        customContent: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(labelText: 'Publication Notes (optional)'),
          ),
        ),
        onConfirm: () => controller.publish(notes: notesCtrl.text.trim()),
      ),
    );
  }

  void _confirmUnpublish(BuildContext context, AdminVerificationNotifier controller) {
    final notesCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Unpublish Scholarship?',
        message:
            'This scholarship will be deactivated and removed from public student search results. It will return to the pending administrative verification queue.',
        isDestructive: true,
        confirmLabel: 'Deactivate Scholarship',
        customContent: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(labelText: 'Unpublish Reason / Notes *'),
          ),
        ),
        onConfirm: () => controller.unpublish(notes: notesCtrl.text.trim()),
      ),
    );
  }

  void _openAuditLogs(BuildContext context) {
    final auditLogsAsync = ref.read(adminAuditLogsProvider(widget.scholarshipId));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => auditLogsAsync.when(
        loading: () => const AuditHistorySheet(auditLogs: [], isLoading: true),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load audit history: $err'),
        ),
        data: (logs) => AuditHistorySheet(auditLogs: logs, isLoading: false),
      ),
    );
  }
}

class _GateItem extends StatelessWidget {
  const _GateItem({
    required this.title,
    required this.isMet,
    required this.description,
  });

  final String title;
  final bool isMet;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isMet ? AppColors.success : colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMet ? AppColors.success : colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
