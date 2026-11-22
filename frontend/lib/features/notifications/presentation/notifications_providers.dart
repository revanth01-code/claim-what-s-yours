import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:claim_whats_yours/core/network/api_client.dart';
import 'package:claim_whats_yours/features/notifications/data/notifications_repository.dart';
import 'package:claim_whats_yours/features/notifications/domain/notification_item.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return ApiNotificationsRepository(ref.watch(apiClientProvider));
});

final myNotificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) {
  return ref.watch(notificationsRepositoryProvider).listMyNotifications();
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).getUnreadCount();
});
