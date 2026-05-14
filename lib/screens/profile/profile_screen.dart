import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design_tokens.dart';
import '../../presentation/providers/profile_providers.dart';
import '../../widgets/guest_login_button.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/tag_chip.dart';
import '../friends/friends_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../../presentation/providers/notification_providers.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: Text('エラーが発生しました: $error')),
      ),
      data: (profile) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            Share.share('パンダトークやってます！\n一緒に合致度測ろう🐼\n#パンダトーク'),
                        child: const Icon(Icons.ios_share, color: AppColors.black),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.black,
                            ),
                            if (ref.watch(unreadNotificationCountProvider) > 0)
                              Positioned(
                                right: -1,
                                top: -1,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.black,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const GuestLoginButton(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PandaAvatar(size: 72),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.username}',
                    style: const TextStyle(
                      fontSize: AppFontSize.md,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: PandaOutlinedButton(
                          label: '編集',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileEditScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PandaOutlinedButton(
                          label: '友達',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FriendsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // 統計
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatItem(label: '回答数', value: '${profile.answerCount}'),
                      _Divider(),
                      _StatItem(label: '投稿数', value: '${profile.postCount}'),
                      _Divider(),
                      _StatItem(label: '友達数', value: '${profile.friendCount}人'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 異端児スコアシェア
                  GestureDetector(
                    onTap: () => Share.share(
                      '私の異端児スコアは26%（やや凡人寄り）\n凡人 ████░░░░░░ 異端児\n#パンダトーク',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softGray,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '異端児スコア ${profile.oddballScore}%',
                            style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.ios_share,
                            size: 14,
                            color: AppColors.textGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.softGray,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '自己紹介',
                          style: TextStyle(
                            fontSize: AppFontSize.sm,
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.bio,
                          style: const TextStyle(
                            fontSize: AppFontSize.md,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'あなたの傾向',
                      style: TextStyle(
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.tags
                        .map((t) => TagChip(label: t, filled: true))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: AppFontSize.xl,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSize.sm,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.borderGray);
  }
}
