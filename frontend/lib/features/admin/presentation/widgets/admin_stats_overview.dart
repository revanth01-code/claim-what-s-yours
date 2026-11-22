import 'package:flutter/material.dart';

import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

/// Metrics overview calculated strictly from actual backend data.
class AdminStatsOverview extends StatelessWidget {
  const AdminStatsOverview({
    super.key,
    required this.scholarships,
    required this.totalCount,
  });

  final List<Scholarship> scholarships;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    // Genuine calculations from actual records
    final pendingCount = totalCount;
    int verifiedSourcesCount = 0;
    int pendingSourcesCount = 0;
    int verifiedCriteriaCount = 0;
    int pendingCriteriaCount = 0;
    int readyToPublishCount = 0;

    for (final s in scholarships) {
      final hasVerifiedSource = s.sources.any((src) => src.verificationStatus == 'verified');
      final allCriteriaVerified = s.eligibilityCriteria.isNotEmpty &&
          s.eligibilityCriteria.every((c) => c.isVerified);
      final hasAcademicYear = s.academicYears.isNotEmpty;

      if (hasVerifiedSource && allCriteriaVerified && hasAcademicYear && !s.isActive) {
        readyToPublishCount++;
      }

      for (final src in s.sources) {
        if (src.verificationStatus == 'verified') {
          verifiedSourcesCount++;
        } else if (src.verificationStatus == 'pending_verification') {
          pendingSourcesCount++;
        }
      }

      for (final c in s.eligibilityCriteria) {
        if (c.isVerified) {
          verifiedCriteriaCount++;
        } else {
          pendingCriteriaCount++;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        final statCards = [
          _StatCard(
            title: 'Pending Queue',
            value: '$pendingCount',
            subtitle: 'Awaiting publication',
            icon: Icons.hourglass_top_rounded,
            color: AppColors.primary,
          ),
          _StatCard(
            title: 'Ready to Publish',
            value: '$readyToPublishCount',
            subtitle: 'All gates verified',
            icon: Icons.verified_outlined,
            color: AppColors.success,
          ),
          _StatCard(
            title: 'Official Sources',
            value: '$verifiedSourcesCount / ${verifiedSourcesCount + pendingSourcesCount}',
            subtitle: '$pendingSourcesCount pending review',
            icon: Icons.link_rounded,
            color: AppColors.secondary,
          ),
          _StatCard(
            title: 'Eligibility Rules',
            value: '$verifiedCriteriaCount / ${verifiedCriteriaCount + pendingCriteriaCount}',
            subtitle: '$pendingCriteriaCount pending review',
            icon: Icons.rule_rounded,
            color: AppColors.tertiary,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: statCards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: statCards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: statCards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: statCards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: statCards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: card,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
