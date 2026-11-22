import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

/// Renders the queue of pending scholarships awaiting verification.
class AdminPendingTable extends StatelessWidget {
  const AdminPendingTable({
    super.key,
    required this.scholarships,
    required this.onRefresh,
  });

  final List<Scholarship> scholarships;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (scholarships.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  'Queue is Clean',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All scholarships have been processed or published.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (!isDesktop) {
          // Mobile card list
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scholarships.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = scholarships[index];
              return _ScholarshipQueueCard(scholarship: s);
            },
          );
        }

        // Desktop Data Table View
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'Pending Scholarships (${scholarships.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh Queue',
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: onRefresh,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 80,
                  headingRowColor: WidgetStateProperty.all(
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  columns: const [
                    DataColumn(label: Text('Scholarship / Authority')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Official Sources')),
                    DataColumn(label: Text('Criteria Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: scholarships.map((s) {
                    final verifiedSources = s.sources
                        .where((src) => src.verificationStatus == 'verified')
                        .length;
                    final totalSources = s.sources.length;

                    final verifiedCriteria = s.eligibilityCriteria
                        .where((c) => c.isVerified)
                        .length;
                    final totalCriteria = s.eligibilityCriteria.length;

                    final allCriteriaVerified = totalCriteria > 0 &&
                        verifiedCriteria == totalCriteria;

                    return DataRow(
                      cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    s.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.administeringAuthority,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.category.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                verifiedSources > 0
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_rounded,
                                size: 16,
                                color: verifiedSources > 0
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$verifiedSources / $totalSources Verified',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                allCriteriaVerified
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                                size: 16,
                                color: allCriteriaVerified
                                    ? AppColors.success
                                    : (totalCriteria == 0
                                        ? colorScheme.outline
                                        : AppColors.warning),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                totalCriteria == 0
                                    ? 'No Criteria'
                                    : '$verifiedCriteria / $totalCriteria Verified',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          FilledButton.tonal(
                            onPressed: () {
                              context.go('/admin/verify/${s.id}');
                            },
                            child: const Text('Review & Verify'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScholarshipQueueCard extends StatelessWidget {
  const _ScholarshipQueueCard({required this.scholarship});

  final Scholarship scholarship;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final verifiedSources = scholarship.sources
        .where((src) => src.verificationStatus == 'verified')
        .length;
    final totalSources = scholarship.sources.length;

    final verifiedCriteria = scholarship.eligibilityCriteria
        .where((c) => c.isVerified)
        .length;
    final totalCriteria = scholarship.eligibilityCriteria.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PENDING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              scholarship.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scholarship.administeringAuthority,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sources',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$verifiedSources / $totalSources Verified',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Criteria',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalCriteria == 0
                            ? 'None Added'
                            : '$verifiedCriteria / $totalCriteria Verified',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  context.go('/admin/verify/${scholarship.id}');
                },
                child: const Text('Review & Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
