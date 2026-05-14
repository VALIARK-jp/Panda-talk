import '../notification_repository.dart';
import '../../core/dummy_data.dart';

class MockNotificationRepository implements NotificationRepository {
  final List<DummyNotification> _notifications = [
    const DummyNotification(
      id: 'friend_request_rina',
      title: '友達申請が届きました',
      body: 'りなさんが友達になりたがっています',
      time: '3分前',
      isRead: false,
      targetLabel: '友達申請',
    ),
    const DummyNotification(
      id: 'question_like_morning',
      title: '質問にいいねされました',
      body: '投稿した「朝型？夜型？」にいいねがつきました',
      time: '1時間前',
      isRead: false,
      targetLabel: '質問',
    ),
    const DummyNotification(
      id: 'friend_accepted_kotaro',
      title: '友達申請が承認されました',
      body: 'こうたろうさんと友達になりました',
      time: '昨日',
      isRead: true,
      targetLabel: 'プロフィール',
    ),
  ];

  @override
  Future<List<DummyNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_notifications);
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }
}
