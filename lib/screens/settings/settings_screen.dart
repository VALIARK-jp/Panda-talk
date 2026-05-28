import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../presentation/session_reset.dart';
import '../../widgets/panda_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            PandaOutlinedButton(
              label: 'ログアウト',
              onTap: () async {
                await performSignOut(ref);
                if (context.mounted) Navigator.pop(context);
              },
            ),
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
