import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/core/errors/api_exception.dart';
import 'package:claim_whats_yours/core/errors/app_exception.dart';
import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';
import 'package:claim_whats_yours/features/scholarships/scholarship_providers.dart';
import 'package:claim_whats_yours/shared/widgets/app_error.dart';
import 'package:claim_whats_yours/shared/widgets/app_loading.dart';
import 'package:claim_whats_yours/shared/widgets/responsive_content_container.dart';

/// Display labels for each known category. Mirrors the list screen.
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

const String _genericErrorMessage =
    'Something unexpected happened. Please try again.';

const String _loadErrorTitle = 'Could not load this scholarship';

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

/// Shows one scholarship with its benefits, eligibility conditions, academic
/// years, application link and official sources.
class ScholarshipDetailScreen extends ConsumerStatefulWidget {
  const ScholarshipDetailScreen({super.key, required this.scholarshipId});

  /// Backend scholarship id, taken from the route path.
  final String scholarshipId;

  @override
  ConsumerState<ScholarshipDetailScreen> createState() =>
      _ScholarshipDetailScreenState();
}

class _ScholarshipDetailScreenState
    extends ConsumerState<ScholarshipDetailScreen> {
  /// True while an external link launch is in flight. Blocks double taps.
  bool _launching = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(scholarshipDetailProvider(widget.scholarshipId));
    return detail.when(
      loading: () => _buildScaffold(context, 'Scholarship', const AppLoading()),
      error: (error, _) =>
          _buildScaffold(context, 'Scholarship', _buildError(error)),
      data: (scholarship) => _buildScaffold(
        context,
        scholarship.name,
        _buildContent(context, scholarship),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, String title, Widget body) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _goBack(context),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: body,
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.scholarships);
    }
  }

  Widget _buildError(Object error) {
    if (error is ApiException && error.statusCode == 404) {
      return const AppError(
        title: _loadErrorTitle,
        message: 'This scholarship is no longer available.',
        icon: Icons.search_off_rounded,
      );
    }
    final message = error is AppException ? _nonEmpty(error.message) : null;
    return AppError(
      title: _loadErrorTitle,
      message: message ?? _genericErrorMessage,
      onRetry: () =>
          ref.invalidate(scholarshipDetailProvider(widget.scholarshipId)),
      retryLabel: 'Try again',
    );
  }

  Widget _buildContent(BuildContext context, Scholarship scholarship) {
    final theme = Theme.of(context);
    final description = _nonEmpty(scholarship.description);
    final sections = <Widget>[
      _buildHeader(context, scholarship),
      if (description != null)
        _section(context, 'About', [
          Text(description, style: theme.textTheme.bodyLarge),
        ]),
      _section(
        context,
        'Benefits',
        _buildBenefits(context, scholarship.benefits),
      ),
      _section(
        context,
        'Eligibility',
        _buildEligibility(context, scholarship.eligibilityCriteria),
      ),
      if (scholarship.academicYears.isNotEmpty)
        _section(context, 'Academic years', [
          for (final year in scholarship.academicYears)
            _buildAcademicYearCard(context, year),
        ]),
      _section(
        context,
        'Application',
        _buildApplication(context, scholarship.applicationUrl),
      ),
      _section(
        context,
        'Official sources',
        _buildSources(context, scholarship.sources),
      ),
      Text(
        'Record updated ${_formatDate(scholarship.updatedAt)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];

    return SingleChildScrollView(
      child: ResponsiveContentContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sections,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Scholarship scholarship) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authority = _nonEmpty(scholarship.administeringAuthority);
    final categoryText = _categoryLabel(scholarship.category);
    final verified = scholarship.hasVerifiedSource;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(scholarship.name, style: theme.textTheme.headlineSmall),
          if (authority != null) ...[
            const SizedBox(height: 4),
            Text(
              authority,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (categoryText != null) ...[
            const SizedBox(height: 12),
            Chip(
              label: Text(categoryText),
              visualDensity: VisualDensity.compact,
            ),
          ],
          const SizedBox(height: 12),
          _StatusLine(
            icon: verified
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: verified ? colors.primary : colors.onSurfaceVariant,
            text: verified ? 'Verified official source' : 'Official verification not shown for this record. Confirm details with the official source before applying.',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBenefits(
    BuildContext context,
    List<BenefitEntry> benefits,
  ) {
    final lines = <String>[];
    for (final benefit in benefits) {
      final line = _benefitLine(benefit);
      if (line != null) lines.add(line);
    }
    if (lines.isEmpty) {
      return [
        _bodyText(
          context,
          'Benefit details are not available for this scholarship.',
        ),
      ];
    }
    return [for (final line in lines) _bodyText(context, line)];
  }

  List<Widget> _buildEligibility(
    BuildContext context,
    List<EligibilityCriterion> criteria,
  ) {
    if (criteria.isEmpty) {
      return [
        _bodyText(
          context,
          'Eligibility conditions are not available for this scholarship.',
        ),
      ];
    }
    return [
      for (final criterion in criteria) _buildCriterionCard(context, criterion),
    ];
  }

  Widget _buildCriterionCard(BuildContext context, EligibilityCriterion c) {
    final colors = Theme.of(context).colorScheme;
    final fields = <Widget>[];
    void addField(String label, String? value) {
      final text = _nonEmpty(value);
      if (text != null) fields.add(_DetailField(label: label, value: text));
    }

    addField('Minimum academic percentage', c.minimumAcademicPercentage);
    addField('Maximum academic percentage', c.maximumAcademicPercentage);
    addField('Minimum family income', c.minimumFamilyIncome);
    addField('Maximum family income', c.maximumFamilyIncome);
    addField('Education levels', _joinList(c.educationLevels));
    addField('Courses', _joinList(c.courses));
    addField(
      'Categories',
      _joinList(
        c.categories?.map((raw) => _categoryLabel(raw) ?? raw).toList(),
      ),
    );
    addField('Domicile state', c.domicileState);
    addField('Gender restriction', c.genderRestriction);
    if (c.disabilityRequired != null) {
      addField('Disability required', c.disabilityRequired! ? 'Yes' : 'No');
    }
    addField('Renewal only', c.renewalOnly ? 'Yes' : 'No');
    addField('Source reference', c.sourceReference);

    final verified = c.isVerified;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...fields,
            if (fields.isNotEmpty) const SizedBox(height: 4),
            _StatusLine(
              icon: verified
                  ? Icons.check_circle_rounded
                  : Icons.help_outline_rounded,
              color: verified ? colors.primary : colors.onSurfaceVariant,
              text: verified ? 'Verified condition' : 'Not yet verified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicYearCard(
    BuildContext context,
    AcademicYearAvailability year,
  ) {
    final theme = Theme.of(context);
    final name = _nonEmpty(year.nameOverride);
    final description = _nonEmpty(year.descriptionOverride);
    final applyUri = _webUri(year.applicationUrlOverride);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(year.academicYear, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _DetailField(
              label: 'Availability',
              value: year.isAvailable ? 'Open' : 'Closed',
            ),
            if (year.openingDate != null)
              _DetailField(
                label: 'Opening date',
                value: _formatDate(year.openingDate!),
              ),
            if (year.closingDate != null)
              _DetailField(
                label: 'Closing date',
                value: _formatDate(year.closingDate!),
              ),
            if (name != null) _DetailField(label: 'Name', value: name),
            if (description != null)
              _DetailField(label: 'Description', value: description),
            if (applyUri != null) ...[
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _launching ? null : () => _openExternal(applyUri),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open application page'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildApplication(BuildContext context, String? rawUrl) {
    final url = _nonEmpty(rawUrl);
    final uri = _webUri(url);
    if (url == null || uri == null) {
      return [_bodyText(context, 'No application link is available.')];
    }
    return [
      FilledButton.icon(
        onPressed: _launching ? null : () => _openExternal(uri),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Open official application page'),
      ),
      SelectableText(url, style: Theme.of(context).textTheme.bodySmall),
    ];
  }

  List<Widget> _buildSources(
    BuildContext context,
    List<OfficialSource> sources,
  ) {
    if (sources.isEmpty) {
      return [
        _bodyText(
          context,
          'No official source information is available for this scholarship.',
        ),
      ];
    }
    return [for (final source in sources) _buildSourceCard(context, source)];
  }

  Widget _buildSourceCard(BuildContext context, OfficialSource source) {
    final theme = Theme.of(context);
    final authority = _nonEmpty(source.authority);
    final title = _nonEmpty(source.title);
    final reference = _nonEmpty(source.documentReference);
    final status = _nonEmpty(source.verificationStatus);
    final verifiedBy = _nonEmpty(source.verifiedBy);
    final sourceUrl = _nonEmpty(source.sourceUrl);
    final sourceUri = _webUri(sourceUrl);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (authority != null)
              Text(authority, style: theme.textTheme.titleSmall),
            if (title != null) ...[
              const SizedBox(height: 4),
              Text(title, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 8),
            if (reference != null)
              _DetailField(label: 'Document reference', value: reference),
            if (status != null)
              _DetailField(label: 'Verification status', value: status),
            if (source.lastVerifiedAt != null)
              _DetailField(
                label: 'Last verified',
                value: _formatDate(source.lastVerifiedAt!),
              ),
            if (verifiedBy != null)
              _DetailField(label: 'Verified by', value: verifiedBy),
            if (sourceUrl != null) ...[
              const SizedBox(height: 4),
              SelectableText(sourceUrl, style: theme.textTheme.bodySmall),
            ],
            if (sourceUri != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _launching ? null : () => _openExternal(sourceUri),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open source'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Launches [uri] in the external browser. Ignores taps while a launch is
  /// already in flight and shows a SnackBar when the link cannot be opened.
  Future<void> _openExternal(Uri uri) async {
    if (_launching) return;
    setState(() => _launching = true);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    } finally {
      if (mounted) setState(() => _launching = false);
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the link. Copy it from the official source list below.',
          ),
        ),
      );
    }
  }

  /// A titled section with a gap between its children.
  Widget _section(BuildContext context, String title, List<Widget> children) {
    final gapped = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) gapped.add(const SizedBox(height: 8));
      gapped.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...gapped,
        ],
      ),
    );
  }

  Widget _bodyText(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

/// One labelled value, for example `Minimum family income: 100000`.
class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

/// An icon followed by a line of text.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Trims [value] and returns null when nothing remains.
String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Maps a raw category string to its display label, or the trimmed raw value
/// when it is unknown. Returns null when the raw value is empty.
String? _categoryLabel(String raw) {
  final known = ScholarshipCategory.fromWire(raw.trim());
  final label = known == null ? null : _categoryLabels[known];
  return label ?? _nonEmpty(raw);
}

/// Joins non-empty trimmed items with commas. Returns null when none remain.
String? _joinList(List<String>? items) {
  if (items == null) return null;
  final cleaned = <String>[];
  for (final item in items) {
    final text = _nonEmpty(item);
    if (text != null) cleaned.add(text);
  }
  return cleaned.isEmpty ? null : cleaned.join(', ');
}

/// Returns [value] when it is a plain string, number or boolean. Otherwise
/// null. Used so that nested benefit data is never shown as raw Dart output.
String? _scalarText(Object? value) {
  if (value is String) return _nonEmpty(value);
  if (value is num || value is bool) return value.toString();
  return null;
}

/// Renders a benefit value without inventing units or currency. Lists and
/// maps are shown only through their scalar members.
String? _displayValue(Object? value) {
  if (value is List) {
    final parts = <String>[];
    for (final item in value) {
      final text = _scalarText(item);
      if (text != null) parts.add(text);
    }
    return parts.isEmpty ? null : parts.join(', ');
  }
  if (value is Map) {
    final parts = <String>[];
    for (final entry in value.entries) {
      final key = _nonEmpty(entry.key.toString());
      final text = _scalarText(entry.value);
      if (key != null && text != null) {
        parts.add('$key: $text');
      } else if (text != null) {
        parts.add(text);
      }
    }
    return parts.isEmpty ? null : parts.join('; ');
  }
  return _scalarText(value);
}

/// Builds `key: value` for a benefit, or just the key or value when the other
/// half is missing. Returns null when both are empty.
String? _benefitLine(BenefitEntry benefit) {
  final key = benefit.key.trim();
  final value = _displayValue(benefit.value);
  if (key.isNotEmpty && value != null) return '$key: $value';
  if (key.isNotEmpty) return key;
  return value;
}

/// Parses [raw] and returns it only when it is an absolute http or https URL
/// with a host. Returns null for anything else.
Uri? _webUri(String? raw) {
  final text = _nonEmpty(raw);
  if (text == null) return null;
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}

/// Formats a date as `d MMM yyyy`, for example `5 Jan 2026`.
String _formatDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}
