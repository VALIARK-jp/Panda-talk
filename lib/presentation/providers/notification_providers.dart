import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

import 'dart:async';

class NotificationController extends AsyncNotifier<List<DummyNotification>> {
  @override
  FutureOr<List<DummyNotification>> build() {
    return _fetch();
  }

  Future<List<DummyNotification>> _fetch() {
    return ref.read(notificationRepositoryProvider).getNotifications();
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    ref.invalidateSelf();
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    ref.invalidateSelf();
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, List<DummyNotification>>(() {
  return NotificationController();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationControllerProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) =>
        notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
