import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/notifications/domain/notification_item.dart';

abstract interface class NotificationsRepository {
  Future<List<NotificationItem>> listMyNotifications();
  Future<int> getUnreadCount();
  Future<void> markRead(String notificationId);
  Future<void> markAllRead();
}

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<NotificationItem>> listMyNotifications() async {
    final response = await _client.get<List<dynamic>>('/notifications/me');
    final list = response.data ?? [];
    return list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _client.get<Map<String, dynamic>>('/notifications/me/unread-count');
    return response.data?['unread_count'] as int? ?? 0;
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _client.patch<Map<String, dynamic>>('/notifications/me/$notificationId/read');
  }

  @override
  Future<void> markAllRead() async {
    await _client.post<Map<String, dynamic>>('/notifications/me/read-all');
  }
}
