import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

class NotificationState {
  final List<DummyNotification> notifications;

  const NotificationState({required this.notifications});

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;
}

class NotificationController extends StateNotifier<NotificationState> {
  NotificationController(this._ref)
    : super(const NotificationState(notifications: [])) {
    _refresh();
  }

  final Ref _ref;

  void markAsRead(String id) {
    _ref.read(notificationRepositoryProvider).markAsRead(id);
    _refresh();
  }

  void markAllAsRead() {
    _ref.read(notificationRepositoryProvider).markAllAsRead();
    _refresh();
  }

  void _refresh() {
    state = NotificationState(
      notifications: _ref
          .read(notificationRepositoryProvider)
          .getNotifications(),
    );
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
      return NotificationController(ref);
    });
