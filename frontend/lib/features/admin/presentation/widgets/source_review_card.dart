import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'confirmation_dialog.dart';

/// Card displaying details and actions for a single official scholarship source.
class SourceReviewCard extends StatelessWidget {
  const SourceReviewCard({
    super.key,
    required this.source,
    required this.onVerify,
    required this.onReject,
    required this.isActionInProgress,
  });

  final OfficialSource source;
  final void Function({
    required String notes,
    required String authority,
    required String title,
    required String documentReference,
  }) onVerify;
  final void Function(String notes) onReject;
  final bool isActionInProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isVerified = source.verificationStatus == 'verified';
    final isRejected = source.verificationStatus == 'rejected';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isVerified) {
      statusColor = AppColors.success;
      statusLabel = 'VERIFIED';
      statusIcon = Icons.check_circle_rounded;
    } else if (isRejected) {
      statusColor = AppColors.error;
      statusLabel = 'REJECTED';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = AppColors.warning;
      statusLabel = 'PENDING VERIFICATION';
      statusIcon = Icons.pending_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (source.verifiedBy != null)
                  Text(
                    'By: ${source.verifiedBy}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Authority and Title
            Text(
              source.title?.isNotEmpty == true ? source.title! : source.authority,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Issuing Authority: ${source.authority}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (source.documentReference?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(
                'Doc Ref: ${source.documentReference}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Source URL
            InkWell(
              onTap: () async {
                final uri = Uri.tryParse(source.sourceUrl);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        source.sourceUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRejected) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: isActionInProgress
                        ? null
                        : () => _showRejectDialog(context),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: 10),
                ],
                if (!isRejected) ...[
                  FilledButton.icon(
                    onPressed: isActionInProgress
                        ? null
                        : () => _showVerifyDialog(context),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(isVerified ? 'Edit Verification' : 'Verify Source'),
                  ),
                ] else ...[
                  Text(
                    'Rejected sources cannot be re-verified.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifyDialog(BuildContext context) {
    final authorityCtrl = TextEditingController(text: source.authority);
    final titleCtrl = TextEditingController(text: source.title ?? '');
    final docRefCtrl = TextEditingController(text: source.documentReference ?? '');
    final notesCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Official Source'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm the source authority and official reference before approving.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorityCtrl,
                decoration: const InputDecoration(labelText: 'Issuing Authority *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Official Document Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: docRefCtrl,
                decoration: const InputDecoration(labelText: 'Document Reference / Gazette No.'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Verification Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onVerify(
                authority: authorityCtrl.text.trim(),
                title: titleCtrl.text.trim(),
                documentReference: docRefCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
            },
            child: const Text('Confirm Verification'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final notesCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Reject Official Source?',
        message:
            'Are you sure you want to reject this source? Per backend state-machine rules, rejected sources cannot be re-verified.\n\nIf this scholarship is currently active and this is its only verified source, it will be automatically unpublished.',
        isDestructive: true,
        confirmLabel: 'Reject Source',
        customContent: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason / Notes *',
              hintText: 'e.g. Broken portal link or unofficial scheme notification',
            ),
            maxLines: 2,
          ),
        ),
        onConfirm: () {
          onReject(notesCtrl.text.trim());
        },
      ),
    );
  }
}
