import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:claim_whats_yours/app/router/route_names.dart';
import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/assistant/data/assistant_repository.dart';
import 'package:claim_whats_yours/features/assistant/domain/ai_guidance.dart';
import 'package:claim_whats_yours/shared/widgets/responsive_content_container.dart';

enum AssistantLanguage {
  english('English', 'en', 'Grounded government guidelines'),
  telugu('తెలుగు', 'te', 'తెలంగాణ పథకాలు మరియు పత్రాల వివరాలు'),
  hindi('हिंदी', 'hi', 'सरकारी छात्रवृत्ति और पात्रता नियम');

  const AssistantLanguage(this.label, this.code, this.description);
  final String label;
  final String code;
  final String description;
}

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  AssistantLanguage _selectedLanguage = AssistantLanguage.english;
  final TextEditingController _queryCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = false;

  final List<ChatMessage> _messages = [];

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

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Welcome to Claim What\'s Yours AI Guidance Assistant. '
            'I provide answers grounded strictly in verified government notifications, gazettes, and official criteria. '
            'Ask me anything about eligibility, deadlines, required documents, or application portals.',
        isUser: false,
        language: 'en',
        suggestedActions: [
          'What documents are needed for Postmatric?',
          'Income threshold for Telangana ePASS',
        ],
      ),
    );
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _queryCtrl.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: trimmed,
          isUser: true,
          language: _selectedLanguage.code,
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final repository = ApiAssistantRepository(ref.read(apiClientProvider));
      final result = await repository.askGuidance(
        query: trimmed,
        language: _selectedLanguage.code,
        includeProfileContext: true,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: result.answer,
              isUser: false,
              language: result.language,
              citations: result.citations,
              suggestedActions: result.suggestedActions,
              disclaimer: result.disclaimer,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Unable to connect to scholarship guidance service. Please verify your connection and try again.',
              isUser: false,
              language: _selectedLanguage.code,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearHistory() {
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          text: 'Conversation history cleared. How can I assist you with government scholarships today?',
          isUser: false,
          language: _selectedLanguage.code,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.home);
            }
          },
        ),
        title: const Text('AI Guidance Assistant'),
        actions: [
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _messages.length > 1 ? _clearHistory : null,
          ),
          IconButton(
            tooltip: 'Scholarship Catalogue',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(RoutePaths.scholarships),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveContentContainer(
        maxWidth: 900,
        child: Column(
          children: [
            // Top Bar: Language Selector & Grounding Disclaimer
            _buildTopBar(theme, isDark),

            // Chat Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingBubble(theme, isDark);
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(theme, isDark, msg);
                },
              ),
            ),

            // Quick Suggestions Chips
            _buildQuickSuggestions(theme, isDark),

            // Input Area
            _buildInputArea(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'STRICT GROUNDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.teal,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Official-Source Grounded Guidance',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Language Selector SegmentedButton with full language labels
              SegmentedButton<AssistantLanguage>(
                segments: AssistantLanguage.values.map((lang) {
                  return ButtonSegment<AssistantLanguage>(
                    value: lang,
                    label: Text(lang.label),
                  );
                }).toList(),
                selected: {_selectedLanguage},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    setState(() => _selectedLanguage = set.first);
                  }
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: AppColors.teal),
              const SizedBox(width: 6),
              const Text(
                'Safety & Zero-Hallucination Policy',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '• Answers are grounded exclusively in verified official scholarship criteria.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, bool isDark, ChatMessage msg) {
    final isUser = msg.isUser;
    final bubbleColor = isUser
        ? (isDark ? AppColors.primaryDark : AppColors.primary)
        : (isDark ? AppColors.cardDark : AppColors.cardLight);
    final textColor = isUser
        ? (isDark ? AppColors.onPrimaryDark : AppColors.onPrimary)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final borderColor = isUser
        ? Colors.transparent
        : (isDark ? AppColors.outlineDark : AppColors.outlineLight);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 680),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(2),
          ),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_outline : Icons.auto_awesome,
                  size: 14,
                  color: isUser ? textColor.withOpacity(0.8) : AppColors.lavender,
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'You' : 'Claim What\'s Yours Assistant',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUser ? textColor.withOpacity(0.8) : AppColors.lavender,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              msg.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.45,
              ),
            ),
            // Citations
            if (msg.citations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: msg.citations.map((c) {
                  return InkWell(
                    onTap: c.url != null ? () => launchUrl(Uri.parse(c.url!)) : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceElevatedDark : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? AppColors.outlineDark : AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link, size: 12, color: AppColors.teal),
                          const SizedBox(width: 4),
                          Text(
                            c.title,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark ? AppColors.tealDark : AppColors.teal,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // Suggested Next Prompts
            if (msg.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: msg.suggestedActions.map((action) {
                  return ActionChip(
                    label: Text(action),
                    labelStyle: theme.textTheme.labelSmall,
                    onPressed: () => _sendMessage(action),
                  );
                }).toList(),
              ),
            ],
            // Grounding Disclaimer
            if (msg.disclaimer != null && !isUser) ...[
              const SizedBox(height: 8),
              Text(
                msg.disclaimer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(ThemeData theme, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(2)),
          border: Border.all(color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Consulting verified scholarship records...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions(ThemeData theme, bool isDark) {
    final prompts = _samplePrompts[_selectedLanguage] ?? [];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sample Grounded Inquiries (${_selectedLanguage.label})',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final p = prompts[i];
                return ActionChip(
                  label: Text(p),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  backgroundColor: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                  side: BorderSide(
                    color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                  ),
                  onPressed: () => _sendMessage(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: _selectedLanguage == AssistantLanguage.telugu
                    ? 'స్కాలర్‌షిప్‌లు, నియమాలు లేదా అర్హత గురించి అడగండి...'
                    : 'Ask about eligibility, deadlines, documents, or schemes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send_rounded),
            onPressed: _isLoading ? null : () => _sendMessage(_queryCtrl.text),
          ),
        ],
      ),
    );
  }
}
