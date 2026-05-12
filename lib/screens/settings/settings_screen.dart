import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../presentation/providers/settings_providers.dart';
import '../../widgets/panda_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _SwitchRow(
              title: '友達申請',
              value: settings.friendRequests,
              onChanged: controller.updateFriendRequests,
            ),
            _SwitchRow(
              title: '質問へのいいね',
              value: settings.questionLikes,
              onChanged: controller.updateQuestionLikes,
            ),
            _SwitchRow(
              title: 'DM・グループチャット',
              value: settings.messages,
              onChanged: controller.updateMessages,
            ),
            _SwitchRow(
              title: 'グループ再編成',
              value: settings.groupUpdates,
              onChanged: controller.updateGroupUpdates,
            ),
            const SizedBox(height: AppSpacing.lg),
            PandaOutlinedButton(
              label: 'ログアウト',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            PandaButton(
              label: 'アカウントを削除',
              onTap: () => _showDeleteDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントを削除しますか？'),
        content: const Text('すべてのデータが削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('削除'),
          ),
        ],
      ),
    );
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
