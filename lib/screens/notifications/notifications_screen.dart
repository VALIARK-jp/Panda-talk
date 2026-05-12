import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../widgets/panda_avatar.dart';
import '../friends/friends_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _allRead = false;

  final _notifications = const [
    DummyNotification(
      title: '友達申請が届きました',
      body: 'りなさんが友達になりたがっています',
      time: '3分前',
      isRead: false,
      targetLabel: '友達申請',
    ),
    DummyNotification(
      title: '質問にいいねされました',
      body: '投稿した「朝型？夜型？」にいいねがつきました',
      time: '1時間前',
      isRead: false,
      targetLabel: '質問',
    ),
    DummyNotification(
      title: '友達申請が承認されました',
      body: 'こうたろうさんと友達になりました',
      time: '昨日',
      isRead: true,
      targetLabel: 'プロフィール',
    ),
  ];

  int get _unreadCount =>
      _allRead ? 0 : _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'お知らせ $_unreadCount',
                      style: const TextStyle(
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _allRead = true),
                    child: const Text(
                      'すべて既読',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: _notifications.length,
                itemBuilder: (context, i) {
                  final n = _notifications[i];
                  final isRead = _allRead || n.isRead;
                  return _NotificationTile(
                    notification: n,
                    isRead: isRead,
                    onTap: () {
                      setState(() => _allRead = true);
                      if (n.targetLabel == '友達申請') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FriendsScreen(),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final DummyNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isRead ? AppColors.white : AppColors.softGray,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                PandaAvatar(size: 40),
                if (!isRead)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${notification.time} / ${notification.targetLabel}',
                    style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
