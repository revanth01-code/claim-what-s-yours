import 'package:flutter/foundation.dart';

@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    this.linkUrl,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final String? linkUrl;
  final DateTime createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? 'general',
      isRead: json['is_read'] as bool? ?? false,
      linkUrl: json['link_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
