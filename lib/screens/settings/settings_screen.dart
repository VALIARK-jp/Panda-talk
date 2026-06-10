import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../core/design_tokens.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../presentation/providers/notification_providers.dart';
import '../../presentation/providers/settings_providers.dart';
import '../../presentation/session_reset.dart';
import '../../widgets/panda_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sendingTestNotification = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: AppColors.black),
                ),
                const SizedBox(width: 12),
                const Text(
                  '設定',
                  style: TextStyle(
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'プッシュ通知',
              style: TextStyle(
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            settings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('エラー: $e'),
              data: (s) => Column(
                children: [
                  _SwitchRow(
                    title: '友達申請',
                    value: s.friendRequestsEnabled,
                    onChanged: controller.updateFriendRequests,
                  ),
                  _SwitchRow(
                    title: '質問へのいいね',
                    value: s.likesEnabled,
                    onChanged: controller.updateQuestionLikes,
                  ),
                  _SwitchRow(
                    title: 'コメント',
                    value: s.commentsEnabled,
                    onChanged: controller.updateComments,
                  ),
                  _SwitchRow(
                    title: '友達承認',
                    value: s.friendAcceptedEnabled,
                    onChanged: controller.updateFriendAccepted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PandaOutlinedButton(
              label: 'ログアウト',
              onTap: () async {
                await performSignOut(ref);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            if (AppConfig.notificationTestEnabled) ...[
              const SizedBox(height: AppSpacing.sm),
              PandaOutlinedButton(
                label: _sendingTestNotification
                    ? '通知テスト送信中...'
                    : '通知テストを送る',
                onTap: _sendingTestNotification ? null : _sendTestNotification,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            PandaButton(
              label: 'アカウントを削除',
              onTap: () => _showDeleteDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    debugPrint('settings:sendTestNotification:start');
    setState(() => _sendingTestNotification = true);
    try {
      await ref.read(settingsRepositoryProvider).sendTestNotification();
      debugPrint('settings:sendTestNotification:done');
      ref.invalidate(notificationControllerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通知テストを送信しました')),
      );
    } catch (e) {
      debugPrint('settings:sendTestNotification:error $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通知テストの送信に失敗しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingTestNotification = false);
      }
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('アカウントを削除しますか？'),
        content: const Text(
          '回答・投稿・プロフィールなど、すべてのデータが削除されます。\n'
          'この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _runAccountDeletion(context, ref);
            },
            child: const Text(
              '削除する',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAccountDeletion(BuildContext context, WidgetRef ref) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      await performAccountDeletion(ref);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アカウントを削除しました')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.black,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.black,
          ),
        ],
      ),
    );
  }
}
