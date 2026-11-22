import 'package:flutter/material.dart';

import 'package:claim_whats_yours/features/scholarships/domain/scholarship.dart';

/// Modal dialog for adding or editing eligibility criteria.
/// Note: Never includes `is_verified` per backend security requirements.
class CriteriaFormDialog extends StatefulWidget {
  const CriteriaFormDialog({
    super.key,
    this.initialCriterion,
    required this.onSubmit,
  });

  final EligibilityCriterion? initialCriterion;
  final void Function({
    double? minPercentage,
    double? maxPercentage,
    double? minIncome,
    double? maxIncome,
    List<String>? educationLevels,
    List<String>? courses,
    List<String>? categories,
    String? domicileState,
    String? genderRestriction,
    bool? disabilityRequired,
    bool renewalOnly,
    String? sourceReference,
    String? notes,
  }) onSubmit;

  @override
  State<CriteriaFormDialog> createState() => _CriteriaFormDialogState();
}

class _CriteriaFormDialogState extends State<CriteriaFormDialog> {
  late final TextEditingController _minPercentageCtrl;
  late final TextEditingController _maxPercentageCtrl;
  late final TextEditingController _minIncomeCtrl;
  late final TextEditingController _maxIncomeCtrl;
  late final TextEditingController _educationLevelsCtrl;
  late final TextEditingController _coursesCtrl;
  late final TextEditingController _categoriesCtrl;
  late final TextEditingController _domicileStateCtrl;
  late final TextEditingController _genderCtrl;
  late final TextEditingController _sourceRefCtrl;
  late final TextEditingController _notesCtrl;

  bool _renewalOnly = false;
  bool? _disabilityRequired;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCriterion;
    _minPercentageCtrl = TextEditingController(text: c?.minimumAcademicPercentage ?? '');
    _maxPercentageCtrl = TextEditingController(text: c?.maximumAcademicPercentage ?? '');
    _minIncomeCtrl = TextEditingController(text: c?.minimumFamilyIncome ?? '');
    _maxIncomeCtrl = TextEditingController(text: c?.maximumFamilyIncome ?? '');
    _educationLevelsCtrl = TextEditingController(text: c?.educationLevels?.join(', ') ?? '');
    _coursesCtrl = TextEditingController(text: c?.courses?.join(', ') ?? '');
    _categoriesCtrl = TextEditingController(text: c?.categories?.join(', ') ?? '');
    _domicileStateCtrl = TextEditingController(text: c?.domicileState ?? '');
    _genderCtrl = TextEditingController(text: c?.genderRestriction ?? '');
    _sourceRefCtrl = TextEditingController(text: c?.sourceReference ?? '');
    _notesCtrl = TextEditingController();
    _renewalOnly = c?.renewalOnly ?? false;
    _disabilityRequired = c?.disabilityRequired;
  }

  @override
  void dispose() {
    _minPercentageCtrl.dispose();
    _maxPercentageCtrl.dispose();
    _minIncomeCtrl.dispose();
    _maxIncomeCtrl.dispose();
    _educationLevelsCtrl.dispose();
    _coursesCtrl.dispose();
    _categoriesCtrl.dispose();
    _domicileStateCtrl.dispose();
    _genderCtrl.dispose();
    _sourceRefCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialCriterion != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Eligibility Criteria' : 'Add Eligibility Criteria'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEditing)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Security Policy: Updating this criterion will automatically reset its verification status to pending review.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPercentageCtrl,
                      decoration: const InputDecoration(labelText: 'Min Academic %'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxPercentageCtrl,
                      decoration: const InputDecoration(labelText: 'Max Academic %'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minIncomeCtrl,
                      decoration: const InputDecoration(labelText: 'Min Family Income (₹)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxIncomeCtrl,
                      decoration: const InputDecoration(labelText: 'Max Family Income (₹)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _educationLevelsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Education Levels (comma-separated)',
                  hintText: 'e.g. undergraduate, postgraduate, diploma',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _coursesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Eligible Courses (comma-separated)',
                  hintText: 'e.g. B.Tech, B.Sc, MBBS, all',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categoriesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Eligible Categories (comma-separated)',
                  hintText: 'e.g. general, sc, st, obc, minority',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _domicileStateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Domicile State',
                        hintText: 'e.g. Telangana, All India',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _genderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Gender Restriction',
                        hintText: 'e.g. female, male, all',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sourceRefCtrl,
                decoration: const InputDecoration(
                  labelText: 'Official Source Reference Clause',
                  hintText: 'e.g. Section 3.1 of Gazette notification',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Renewal Applicants Only'),
                value: _renewalOnly,
                onChanged: (val) => setState(() => _renewalOnly = val),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Admin Review Notes',
                  hintText: 'Internal verification justification',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            final minPct = double.tryParse(_minPercentageCtrl.text.trim());
            final maxPct = double.tryParse(_maxPercentageCtrl.text.trim());
            final minInc = double.tryParse(_minIncomeCtrl.text.trim());
            final maxInc = double.tryParse(_maxIncomeCtrl.text.trim());

            List<String>? parseList(String text) {
              final trimmed = text.trim();
              if (trimmed.isEmpty) return null;
              return trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            }

            widget.onSubmit(
              minPercentage: minPct,
              maxPercentage: maxPct,
              minIncome: minInc,
              maxIncome: maxInc,
              educationLevels: parseList(_educationLevelsCtrl.text),
              courses: parseList(_coursesCtrl.text),
              categories: parseList(_categoriesCtrl.text),
              domicileState: _domicileStateCtrl.text.trim().isEmpty ? null : _domicileStateCtrl.text.trim(),
              genderRestriction: _genderCtrl.text.trim().isEmpty ? null : _genderCtrl.text.trim(),
              disabilityRequired: _disabilityRequired,
              renewalOnly: _renewalOnly,
              sourceReference: _sourceRefCtrl.text.trim().isEmpty ? null : _sourceRefCtrl.text.trim(),
              notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            );
          },
          child: Text(isEditing ? 'Save Changes' : 'Create Criteria'),
        ),
      ],
    );
  }
}
