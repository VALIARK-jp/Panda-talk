import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../core/design_tokens.dart';
import '../../core/share_utils.dart';
import '../../presentation/providers/profile_providers.dart';
import '../../widgets/guest_login_button.dart';
import '../../widgets/user_avatar.dart';
import '../../core/personality_axis.dart';
import '../../widgets/panda_type_profile_section.dart';
import '../../widgets/personality_tendency_chips.dart';
import '../../widgets/speech_bubble.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/username_label.dart';
import '../friends/friends_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../../presentation/providers/notification_providers.dart';
import '../notifications/notifications_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(profileControllerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
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
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        return ColoredBox(
          color: AppColors.white,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg + bottomInset,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
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
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileEditScreen(),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        UserAvatar(size: 72, imageUrl: profile.avatarUrl),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profile.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: UsernameLabel(
                      username: profile.username,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ProfileActionButton(
                        icon: Icons.edit_outlined,
                        label: '編集',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen(),
                          ),
                        ),
                      ),
                      _ProfileActionButton(
                        icon: Icons.people_outline,
                        label: '友達',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FriendsScreen(),
                          ),
                        ),
                      ),
                      _ProfileActionButton(
                        icon: Icons.ios_share,
                        label: '共有',
                        onTap: () => _shareProfile(context, profile),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // 統計
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 0,
                    runSpacing: 8,
                    children: [
                      _StatItem(label: '回答数', value: '${profile.answerCount}'),
                      _Divider(),
                      _StatItem(label: '投稿数', value: '${profile.postCount}'),
                      _Divider(),
                      _StatItem(label: '友達数', value: '${profile.friendCount}'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softGray,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '異端児スコア ${profile.oddballScore}%',
                      style: const TextStyle(
                        fontSize: AppFontSize.sm,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  if (profile.hasDiagnosis16)
                    PandaTypeProfileSection(
                      profile: profile,
                      bio: profile.bio,
                    )
                  else
                    _BioSection(bio: profile.bio),
                  if (profile.hasDiagnosis16) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${profile.name}の傾向',
                        style: const TextStyle(
                          fontSize: AppFontSize.md,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PersonalityTendencyChips(
                      scores: PersonalityAxisRegistry.scoresFromProfileFields(
                        affectionPct: profile.typeAffectionPct,
                        thinkingPct: profile.typeThinkingPct,
                        actionPct: profile.typeActionPct,
                        lifePct: profile.typeLifePct,
                      ),
                    ),
                  ] else if (profile.tags.isNotEmpty) ...[
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _shareProfile(BuildContext context, DummyProfile profile) {
    final tags = profile.tags.isEmpty
        ? ''
        : '\nタグ: ${profile.tags.join(' / ')}';
    final bio = profile.bio.trim().isEmpty
        ? ''
        : '\n自己紹介: ${profile.bio.trim()}';

    AppShare.text(
      context,
      '${profile.name}（@${profile.username}）のパンダトークプロフィール\n'
      '回答数: ${profile.answerCount} / 投稿数: ${profile.postCount} / 友達数: ${profile.friendCount}\n'
      '異端児スコア: ${profile.oddballScore}%\n'
      '$tags'
      '$bio\n'
      '#パンダトーク',
    );
  }
}

class _BioSection extends StatelessWidget {
  const _BioSection({required this.bio});

  final String bio;

  @override
  Widget build(BuildContext context) {
    final text = bio.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        const Text(
          '自己紹介',
          style: TextStyle(
            fontSize: AppFontSize.sm,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SpeechBubble(
          text: text.isEmpty ? 'まだ自己紹介がありません' : text,
          tail: SpeechBubbleTail.bottomLeft,
          maxLines: 3,
          textStyle: TextStyle(
            fontSize: AppFontSize.sm,
            fontWeight: FontWeight.w600,
            color: text.isEmpty ? AppColors.textGray : AppColors.black,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.black,
          side: const BorderSide(color: AppColors.borderGray),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(72, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(
            fontSize: AppFontSize.sm,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
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
