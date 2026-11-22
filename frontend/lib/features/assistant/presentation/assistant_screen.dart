import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/shared/widgets/responsive_content_container.dart';

/// Supported language definition for the multilingual AI assistant.
enum AssistantLanguage {
  english('English', 'EN', 'Grounded government guidelines'),
  telugu('తెలుగు', 'TE', 'తెలంగాణ పథకాలు మరియు పత్రాల వివరాలు'),
  hindi('हिंदी', 'HI', 'सरकारी छात्रवृत्ति और पात्रता नियम');

  const AssistantLanguage(this.label, this.code, this.description);
  final String label;
  final String code;
  final String description;
}

/// Production-ready, premium Presentation boundary for the Multilingual AI Scholarship Assistant.
/// Grounded strictly in official government gazettes and administrator-verified records
/// as defined in `docs/ai-architecture.md`.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  AssistantLanguage _selectedLanguage = AssistantLanguage.english;

  final Map<AssistantLanguage, List<String>> _samplePrompts = {
    AssistantLanguage.english: [
      'What is the family income limit for Postmatric Scholarships?',
      'Which documents are mandatory for Telangana ePASS renewal?',
      'Am I eligible for PM-USP CSSS as a 1st year undergraduate?',
      'What are the minimum marks required for PM YASASVI top-class education?',
    ],
    AssistantLanguage.telugu: [
      'తెలంగాణ ఈపాస్ పోస్ట్-మెట్రిక్ స్కాలర్‌షిప్ ఆదాయ పరిమితి ఎంత?',
      'స్కాలర్‌షిప్ దరఖాస్తుకు ఏయే సర్టిఫికెట్లు సమర్పించాలి?',
      'రెన్యువల్ కోసం కాలేజీ బోనఫైడ్ సర్టిఫికెట్ అవసరమా?',
      'హాస్టలర్లకు మరియు డే-స్కాలర్లకు ఉపకార వేతనం ఎంత లభిస్తుంది?',
    ],
    AssistantLanguage.hindi: [
      'पीएम यशस्वी योजना के लिए कौन से दस्तावेज आवश्यक हैं?',
      'पोस्ट-मैट्रिक छात्रवृत्ति के लिए वार्षिक पारिवारिक आय की सीमा क्या है?',
      'पीएम-यूएसपी योजना में आवेदन करने की पात्रता शर्तें क्या हैं?',
      'नवीनतम सरकारी अधिसूचना के अनुसार नवीनीकरण कैसे करें?',
    ],
  };

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _navigateBack(context),
        ),
        title: const Text('AI Guidance Assistant'),
        actions: [
          IconButton(
            tooltip: 'Scholarship Catalogue',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(RoutePaths.scholarships),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ResponsiveContentContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Banner
              _buildHeroBanner(context),
              const SizedBox(height: 20),

              // 2. Verified Grounding Policy Banner
              _buildGroundingPolicyCard(context),
              const SizedBox(height: 24),

              // 3. Language Selector
              _buildLanguageSelector(context),
              const SizedBox(height: 24),

              // 4. Sample Inquiries Preview
              _buildSampleInquiries(context),
              const SizedBox(height: 28),

              // 5. Verification Notice & Action Buttons
              _buildActionFooter(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: isDark ? AppColors.onPrimaryContainerDark : AppColors.onPrimaryContainer,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MULTILINGUAL SCHOLARSHIP GUIDANCE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.onPrimaryContainerDark : AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Official-Source Grounded Guidance',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Get clear answers to your scholarship and document eligibility questions in Telugu, Hindi or English — strictly backed by official government gazettes and verified portals.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariantLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundingPolicyCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: AppColors.secondaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Safety & Zero-Hallucination Policy',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'STRICT GROUNDING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSecondaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'To protect students from inaccurate rules or fabricated deadlines, our AI assistant is coupled with a deterministic eligibility engine and only synthesizes responses from verified, administrator-approved government sources. Conversational queries will be fully activated upon completion of the pending verification cycle.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSecondaryContainer.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Guidance Language',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: AssistantLanguage.values.map((lang) {
            final isSelected = _selectedLanguage == lang;
            return ChoiceChip(
              avatar: CircleAvatar(
                radius: 12,
                backgroundColor: isSelected ? Colors.white : theme.colorScheme.primaryContainer,
                child: Text(
                  lang.code,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : AppColors.onPrimaryContainer,
                  ),
                ),
              ),
              label: Text(lang.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedLanguage = lang);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSampleInquiries(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prompts = _samplePrompts[_selectedLanguage] ?? [];

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
                const Icon(Icons.help_outline_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Sample Grounded Inquiries (${_selectedLanguage.label})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...prompts.map((prompt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prompt,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _navigateBack(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to Dashboard'),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: () => context.go(RoutePaths.scholarships),
          icon: const Icon(Icons.search_rounded, size: 18),
          label: const Text('Browse Scholarships'),
        ),
      ],
    );
  }
}
