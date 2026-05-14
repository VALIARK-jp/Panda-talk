import '../core/dummy_data.dart';

abstract class NotificationRepository {
  Future<List<DummyNotification>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}
