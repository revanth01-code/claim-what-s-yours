import 'package:flutter/foundation.dart';

@immutable
class AICitation {
  const AICitation({
    required this.title,
    this.url,
    this.sourceType,
  });

  final String title;
  final String? url;
  final String? sourceType;

  factory AICitation.fromJson(Map<String, dynamic> json) {
    return AICitation(
      title: json['title'] as String? ?? '',
      url: json['url'] as String?,
      sourceType: json['source_type'] as String?,
    );
  }
}

@immutable
class AIGuidanceResult {
  const AIGuidanceResult({
    required this.answer,
    required this.language,
    required this.grounded,
    this.citations = const [],
    this.suggestedActions = const [],
    required this.disclaimer,
  });

  final String answer;
  final String language;
  final bool grounded;
  final List<AICitation> citations;
  final List<String> suggestedActions;
  final String disclaimer;

  factory AIGuidanceResult.fromJson(Map<String, dynamic> json) {
    return AIGuidanceResult(
      answer: json['answer'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      grounded: json['grounded'] as bool? ?? true,
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => AICitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      suggestedActions: (json['suggested_actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      disclaimer: json['disclaimer'] as String? ??
          'This response is grounded in official scholarship guidelines and gazettes.',
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.language = 'en',
    this.citations = const [],
    this.suggestedActions = const [],
    this.disclaimer,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final String language;
  final List<AICitation> citations;
  final List<String> suggestedActions;
  final String? disclaimer;
  final DateTime timestamp;
}
