import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/presentation/scholarship_list_controller.dart';
import 'package:claim_whats_yours/shared/widgets/app_empty_state.dart';
import 'package:claim_whats_yours/shared/widgets/app_error.dart';
import 'package:claim_whats_yours/shared/widgets/app_loading.dart';
import 'package:claim_whats_yours/shared/widgets/responsive_content_container.dart';

/// Display labels for each known category, in the order they appear as chips.
const Map<ScholarshipCategory, String> _categoryLabels = {
  ScholarshipCategory.sc: 'SC',
  ScholarshipCategory.st: 'ST',
  ScholarshipCategory.obc: 'OBC',
  ScholarshipCategory.ebc: 'EBC',
  ScholarshipCategory.minority: 'Minority',
  ScholarshipCategory.economicallyWeaker: 'Economically weaker',
  ScholarshipCategory.disability: 'Disability',
  ScholarshipCategory.merit: 'Merit',
  ScholarshipCategory.general: 'General',
  ScholarshipCategory.other: 'Other',
};

/// Width at or above which results use two columns.
const double _twoColumnWidth = 840;

/// Matches the default `maxWidth` of [ResponsiveContentContainer].
const double _maxContentWidth = 1100;

/// Distance from the bottom, in logical pixels, that triggers the next page.
const double _loadMoreThreshold = 300;

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Browses the official scholarship catalogue with search, category filters,
/// pagination and pull-to-refresh.
class ScholarshipsScreen extends ConsumerStatefulWidget {
  const ScholarshipsScreen({super.key});

  @override
  ConsumerState<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends ConsumerState<ScholarshipsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ScholarshipListController get _controller =>
      ref.read(scholarshipListControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.ensureLoaded();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter <= _loadMoreThreshold) {
      _controller.loadMore();
    }
  }

  void _clearSearchText() {
    _searchController.clear();
    _controller.setSearch('');
  }

  void _clearAllFilters() {
    _searchController.clear();
    _controller.clearFilters();
  }

  void _openScholarship(String id) {
    context.push(
      RoutePaths.scholarshipDetail.replaceFirst(':id', Uri.encodeComponent(id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scholarshipListControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTwoColumn = width >= _twoColumnWidth;
    final overflow = width - _maxContentWidth;
    final sideInset = (overflow > 0 ? overflow / 2 : 0.0) + 16;
    final hasFilters =
        state.query.search != null || state.query.category != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Scholarships')),
      body: RefreshIndicator(
        onRefresh: _controller.refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ResponsiveContentContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    _buildCategoryFilters(state),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            ..._buildResults(state, hasFilters, isTwoColumn, sideInset),
            SliverToBoxAdapter(
              child: ResponsiveContentContainer(child: _buildFooter(state)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, value, _) {
        return TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (text) => _controller.setSearch(text),
          decoration: InputDecoration(
            hintText: 'Search scholarships',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: _clearSearchText,
                  ),
            border: const OutlineInputBorder(),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilters(ScholarshipListState state) {
    final selected = state.query.category;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: selected == null,
          onSelected: (_) => _controller.setCategory(null),
        ),
        for (final entry in _categoryLabels.entries)
          FilterChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (isSelected) =>
                _controller.setCategory(isSelected ? entry.key : null),
          ),
      ],
    );
  }

  List<Widget> _buildResults(
    ScholarshipListState state,
    bool hasFilters,
    bool isTwoColumn,
    double sideInset,
  ) {
    final items = state.items;
    if (items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: ResponsiveContentContainer(
            child: _buildStatusPanel(state, hasFilters),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: sideInset),
        sliver: isTwoColumn
            ? _buildTwoColumnList(items)
            : _buildSingleColumnList(items),
      ),
    ];
  }

  Widget _buildStatusPanel(ScholarshipListState state, bool hasFilters) {
    if (state.status == ScholarshipListStatus.error) {
      return AppError(
        title: 'Could not load scholarships',
        message: state.errorMessage ?? scholarshipGenericErrorMessage,
        onRetry: () => _controller.retry(),
        retryLabel: 'Try again',
      );
    }
    if (state.status == ScholarshipListStatus.loaded) {
      if (hasFilters) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No scholarships match your search. Try different words or clear the filters.',
          actionLabel: 'Clear filters',
          onAction: _clearAllFilters,
        );
      }
      return AppEmptyState(
        icon: Icons.school_outlined,
        title: 'No scholarships are available yet.',
        message: 'Verified government scholarships will appear here as soon as administrative review is finalized.\nIn the meantime, complete your student profile to get matched instantly when schemes are published.',
        actionLabel: 'Complete Student Profile',
        onAction: () => context.push(RoutePaths.onboarding),
      );
    }
    return const AppLoading();
  }

  Widget _buildSingleColumnList(List<Scholarship> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCard(items[index]),
        ),
        childCount: items.length,
      ),
    );
  }

  /// Two cards per row. Cards in a row share a height; cards have variable
  /// content, so a fixed-aspect-ratio grid would overflow.
  Widget _buildTwoColumnList(List<Scholarship> items) {
    final rowCount = (items.length + 1) ~/ 2;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, rowIndex) {
        final leftIndex = rowIndex * 2;
        final rightIndex = leftIndex + 1;
        final hasRight = rightIndex < items.length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildCard(items[leftIndex])),
                const SizedBox(width: 12),
                Expanded(
                  child: hasRight
                      ? _buildCard(items[rightIndex])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }, childCount: rowCount),
    );
  }

  Widget _buildCard(Scholarship item) {
    return _ScholarshipCard(
      scholarship: item,
      onTap: () => _openScholarship(item.id),
    );
  }

  Widget _buildFooter(ScholarshipListState state) {
    if (state.items.isEmpty) return const SizedBox.shrink();
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final message =
        state.loadMoreErrorMessage ??
        (state.status == ScholarshipListStatus.error
            ? state.errorMessage
            : null);
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _controller.retry(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

/// One scholarship summary card. Shows only fields that have content.
class _ScholarshipCard extends StatelessWidget {
  const _ScholarshipCard({required this.scholarship, required this.onTap});

  final Scholarship scholarship;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final item = scholarship;

    final provider = item.administeringAuthority.trim();
    final description = item.description?.trim();
    final award = _benefitSummary(item.benefits);
    final eligibility = _eligibilitySummary(item.eligibilityCriteria);
    final closing = _earliestClosingDate(item.academicYears);
    final categoryLabel = item.categoryValue == null
        ? item.category
        : (_categoryLabels[item.categoryValue] ?? item.category);

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (provider.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  provider,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Chip(
                label: Text(categoryLabel),
                visualDensity: VisualDensity.compact,
              ),
              if (award != null) ...[
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.account_balance_wallet_outlined,
                  text: 'Award: $award',
                ),
              ],
              if (eligibility != null) ...[
                const SizedBox(height: 8),
                _InfoLine(icon: Icons.checklist_rounded, text: eligibility),
              ],
              if (closing != null) ...[
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.event_outlined,
                  text: 'Closes: ${_formatDate(closing)}',
                ),
              ],
              const SizedBox(height: 12),
              _VerificationBadge(verified: item.hasVerifiedSource),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single icon-and-text detail line on a card.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Shows whether the scholarship has a verified official source.
class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = verified
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verified ? Icons.check_circle_rounded : Icons.help_outline_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          verified ? 'Verified source' : 'Source not verified',
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Joins benefit entries as `key: value` text. Returns null when nothing
/// displayable exists. Values are shown only when they are plain scalars.
String? _benefitSummary(List<BenefitEntry> benefits) {
  final parts = <String>[];
  for (final benefit in benefits) {
    final key = benefit.key.trim();
    final value = _scalarText(benefit.value);
    if (key.isNotEmpty && value != null) {
      parts.add('$key: $value');
    } else if (key.isNotEmpty) {
      parts.add(key);
    } else if (value != null) {
      parts.add(value);
    }
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

String? _scalarText(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num || value is bool) return value.toString();
  return null;
}

/// Counts the criteria and lists any education levels. Returns null when there
/// are no criteria.
String? _eligibilitySummary(List<EligibilityCriterion> criteria) {
  if (criteria.isEmpty) return null;
  final levels = <String>{};
  for (final criterion in criteria) {
    for (final level in criterion.educationLevels ?? const <String>[]) {
      final trimmed = level.trim();
      if (trimmed.isNotEmpty) levels.add(trimmed);
    }
  }
  final count = criteria.length;
  final countText =
      '$count eligibility ${count == 1 ? 'criterion' : 'criteria'}';
  if (levels.isEmpty) return countText;
  return '$countText · Education levels: ${levels.join(', ')}';
}

/// The soonest closing date across academic years, or null when none is set.
DateTime? _earliestClosingDate(List<AcademicYearAvailability> years) {
  DateTime? earliest;
  for (final year in years) {
    final closing = year.closingDate;
    if (closing != null && (earliest == null || closing.isBefore(earliest))) {
      earliest = closing;
    }
  }
  return earliest;
}

/// Formats a date as `d MMM yyyy`, for example `5 Jan 2026`.
String _formatDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}
