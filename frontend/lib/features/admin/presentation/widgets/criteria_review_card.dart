import 'package:flutter/material.dart';

import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'confirmation_dialog.dart';

/// Card displaying details of an individual eligibility criterion with review & edit actions.
class CriteriaReviewCard extends StatelessWidget {
  const CriteriaReviewCard({
    super.key,
    required this.criterion,
    required this.index,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.isActionInProgress,
  });

  final EligibilityCriterion criterion;
  final int index;
  final VoidCallback onApprove;
  final void Function(String notes) onReject;
  final VoidCallback onEdit;
  final bool isActionInProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isVerified = criterion.isVerified;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Criterion #$index',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isVerified
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 13,
                        color: isVerified ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'VERIFIED' : 'PENDING REVIEW',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isVerified ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit Criteria (resets verification)',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: isActionInProgress ? null : onEdit,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Criteria fields grid
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                if (criterion.minimumAcademicPercentage != null)
                  _CriterionItem(
                    label: 'Min Academic %',
                    value: '${criterion.minimumAcademicPercentage}%',
                  ),
                if (criterion.maximumAcademicPercentage != null)
                  _CriterionItem(
                    label: 'Max Academic %',
                    value: '${criterion.maximumAcademicPercentage}%',
                  ),
                if (criterion.maximumFamilyIncome != null)
                  _CriterionItem(
                    label: 'Max Family Income',
                    value: '₹${criterion.maximumFamilyIncome}',
                  ),
                if (criterion.minimumFamilyIncome != null)
                  _CriterionItem(
                    label: 'Min Family Income',
                    value: '₹${criterion.minimumFamilyIncome}',
                  ),
                if (criterion.domicileState?.isNotEmpty == true)
                  _CriterionItem(
                    label: 'Domicile State',
                    value: criterion.domicileState!,
                  ),
                if (criterion.genderRestriction?.isNotEmpty == true)
                  _CriterionItem(
                    label: 'Gender Restriction',
                    value: criterion.genderRestriction!.toUpperCase(),
                  ),
                if (criterion.disabilityRequired != null)
                  _CriterionItem(
                    label: 'Disability Required',
                    value: criterion.disabilityRequired! ? 'Yes' : 'No',
                  ),
                if (criterion.renewalOnly)
                  const _CriterionItem(
                    label: 'Renewal Only',
                    value: 'Yes',
                  ),
              ],
            ),

            if (criterion.educationLevels?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Education Levels: ${criterion.educationLevels!.join(", ")}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (criterion.courses?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                'Courses: ${criterion.courses!.join(", ")}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (criterion.categories?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                'Categories: ${criterion.categories!.join(", ").toUpperCase()}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (criterion.sourceReference?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                'Official Reference: ${criterion.sourceReference}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const Divider(height: 20),

            // Approval / Rejection buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isVerified)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: isActionInProgress
                        ? null
                        : () => _showRevokeDialog(context),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Un-verify'),
                  )
                else
                  FilledButton.icon(
                    onPressed: isActionInProgress ? null : onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve Criteria'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRevokeDialog(BuildContext context) {
    final notesCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Revoke Criteria Verification?',
        message:
            'Are you sure you want to un-verify this criterion? The scholarship cannot be published or remain verified until all criteria are approved.',
        isDestructive: true,
        confirmLabel: 'Un-verify Criterion',
        customContent: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason for Revocation',
            ),
          ),
        ),
        onConfirm: () => onReject(notesCtrl.text.trim()),
      ),
    );
  }
}

class _CriterionItem extends StatelessWidget {
  const _CriterionItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
