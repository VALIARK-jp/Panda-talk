import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../presentation/providers/notification_providers.dart';
import '../../widgets/panda_avatar.dart';
import '../home/question_comments_screen.dart';
import '../friends/friends_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(notificationControllerProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
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
                      'お知らせ ${unreadCount > 0 ? unreadCount : ''}',
                      style: const TextStyle(
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(notificationControllerProvider.notifier)
                        .markAllAsRead(),
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
              child: notificationAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (notifications) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: notifications.length,
                  itemBuilder: (context, i) {
                    final n = notifications[i];
                    return _NotificationTile(
                      notification: n,
                      isRead: n.isRead,
                      onTap: () => _handleNotificationTap(context, ref, n),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleNotificationTap(
  BuildContext context,
  WidgetRef ref,
  DummyNotification notification,
) async {
  await ref
      .read(notificationControllerProvider.notifier)
      .markAsRead(notification.id);

  if (!context.mounted) return;

  if (notification.type == 'friend_request' ||
      notification.type == 'friend_accepted') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FriendsScreen(),
      ),
    );
    return;
  }

  if ((notification.type == 'like' || notification.type == 'comment') &&
      notification.targetId != null) {
    try {
      final repo = ref.read(questionRepositoryProvider);
      final questions = await repo.getFeedWindowAround(
        before: 0,
        after: 0,
        questionId: notification.targetId,
      );
      final question = questions.isNotEmpty ? questions.first : null;
      if (question != null && context.mounted) {
        await QuestionCommentsScreen.openFocus(
          context,
          question: question,
          percentA: question.percentA,
          selectedOption: question.myAnswer,
        );
      }
    } catch (_) {
      // Fall through: mark-as-read already completed.
    }
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
