import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../core/match_rate_utils.dart';
import '../../core/share_utils.dart';
import '../../presentation/providers/friend_providers.dart';
import '../../presentation/providers/match_providers.dart';
import '../../presentation/providers/moderation_providers.dart';
import '../../presentation/providers/user_profile_providers.dart';
import '../../infrastructure/moderation_repository.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/report_content_sheet.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/panda_type_profile_section.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/username_label.dart';
import '../talk/direct_chat_screen.dart';
import 'answer_compare_screen.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final DummyUser user;

  /// マッチ画面から開いたとき true。あなたとの合致度を強調表示する。
  final bool fromMatch;

  const UserDetailScreen({
    super.key,
    required this.user,
    this.fromMatch = false,
  });

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  int _tabIndex = 0;

  Future<void> _sendFriendRequest() async {
    await ref
        .read(friendControllerProvider.notifier)
        .sendFriendRequest(widget.user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('友達申請を送りました')));
  }

  Future<void> _acceptFriendRequest() async {
    await ref
        .read(friendControllerProvider.notifier)
        .acceptRequest(widget.user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('友達申請を承諾しました')));
  }

  Future<void> _confirmBlockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text(
          'このユーザーをブロック',
          style: TextStyle(
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        content: const Text(
          'ブロックすると、このユーザーの投稿やプロフィールが表示されなくなります。',
          style: TextStyle(
            fontSize: AppFontSize.md,
            color: AppColors.black,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppColors.textGray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'ブロックする',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(moderationControllerProvider.notifier)
          .blockUser(widget.user.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザーをブロックしました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ブロックに失敗しました: $e')),
      );
    }
  }

  void _openAnswerCompare() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnswerCompareScreen(user: widget.user),
      ),
    );
  }

  void _onAnswersTabTap({
    required bool isFriend,
    required bool isRequested,
    required bool hasIncomingRequest,
  }) {
    if (isFriend) {
      setState(() => _tabIndex = 1);
      _openAnswerCompare();
      return;
    }

    final message = hasIncomingRequest
        ? '友達申請が届いています。承諾すれば回答を見られるようになります。'
        : isRequested
        ? '友達申請を送りました。相手が承認すれば回答を見られるようになります。'
        : '回答の比較を見るには友達になる必要があります。友達申請を送ると、承認後に閲覧できます。';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text(
          '友達になると回答を見られます',
          style: TextStyle(
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: AppFontSize.md,
            color: AppColors.black,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              '閉じる',
              style: TextStyle(color: AppColors.textGray),
            ),
          ),
          if (hasIncomingRequest)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _acceptFriendRequest();
                if (!mounted) return;
                setState(() => _tabIndex = 1);
                _openAnswerCompare();
              },
              child: const Text(
                '承諾する',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (!isRequested)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _sendFriendRequest();
              },
              child: const Text(
                '友達申請を送る',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final profileAsync = ref.watch(userProfileProvider(u.id));
    final compareAsync = ref.watch(compareAnswersProvider(u.id));
    final compareAnswers = compareAsync.valueOrNull ?? const [];
    final compareCommonAnswerCount = compareAnswers.length;
    final compareSameAnswerCount = compareAnswers
        .where((answer) => answer['match'] == true)
        .length;
    final commonAnswerCount = compareAsync.hasValue
        ? compareCommonAnswerCount
        : (u.commonAnswerCount ?? 0);
    final sameAnswerCount = compareAsync.hasValue
        ? compareSameAnswerCount
        : (u.sameAnswerCount ?? 0);
    final displayedMatchRate = commonAnswerCount > 0
        ? matchRatePercent(
            sameAnswerCount: sameAnswerCount,
            commonAnswerCount: commonAnswerCount,
          )
        : u.resolvedMatchRate;
    final friendState = ref.watch(friendControllerProvider).valueOrNull;
    final isFriend =
        friendState?.friends.any((friend) => friend.id == u.id) ?? false;
    final isRequested = friendState?.requestedUserIds.contains(u.id) ?? false;
    final hasIncomingRequest = friendState?.requests.any(
          (request) => request.user.id == u.id,
        ) ??
        false;

    final displayName = profileAsync.valueOrNull?.name ?? u.name;
    final displayUsername =
        profileAsync.valueOrNull?.username ?? u.id;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isSelf = currentUserId != null && currentUserId == u.id;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.fromMatch ? 'プロフィール' : displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  if (!isSelf) ...[
                    GestureDetector(
                      onTap: () => AppShare.text(
                        context,
                        '${displayName}さんと合致度$displayedMatchRate%！\n価値観めっちゃ近い\n#パンダトーク',
                      ),
                      child: const Icon(Icons.ios_share, color: AppColors.black),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.black),
                      onSelected: (value) {
                        switch (value) {
                          case 'report':
                            showReportContentSheet(
                              context,
                              ref: ref,
                              targetType: ReportTargetType.user,
                              targetId: u.id,
                              subjectLabel: displayName,
                            );
                            break;
                          case 'block':
                            _confirmBlockUser();
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'report',
                          child: Text('通報する'),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Text('ブロックする'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            profileAsync.when(
              loading: () => const UserAvatar(size: 80),
              error: (_, __) => const UserAvatar(size: 80),
              data: (profile) => UserAvatar(
                size: 80,
                imageUrl: profile.avatarUrl,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: UsernameLabel(
                username: displayUsername,
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.fromMatch) ...[
              const SizedBox(height: AppSpacing.md),
              _SelfMatchRateCard(
                matchRate: displayedMatchRate,
                loading: compareAsync.isLoading,
                commonAnswerCount: commonAnswerCount,
                sameAnswerCount: sameAnswerCount,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SegmentedTabs(
                tabs: const ['プロフィール', '回答を見る'],
                selectedIndex: _tabIndex,
                onChanged: (i) {
                  if (i == 0) {
                    setState(() => _tabIndex = 0);
                    return;
                  }
                  _onAnswersTabTap(
                    isFriend: isFriend,
                    isRequested: isRequested,
                    hasIncomingRequest: hasIncomingRequest,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _tabIndex == 0
                  ? profileAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, __) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'プロフィールを読み込めませんでした',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textGray),
                          ),
                        ),
                      ),
                      data: (profile) => _UserProfilePanel(profile: profile),
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  PandaButton(
                    label: isFriend
                        ? '友達'
                        : (isRequested ? '申請済み' : '友達申請を送る'),
                    onTap: isFriend || isRequested ? null : _sendFriendRequest,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PandaOutlinedButton(
                    label: 'メッセージ',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectChatScreen(user: widget.user),
                      ),
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

class _SelfMatchRateCard extends StatelessWidget {
  const _SelfMatchRateCard({
    required this.matchRate,
    required this.loading,
    required this.commonAnswerCount,
    required this.sameAnswerCount,
  });

  final int matchRate;
  final bool loading;
  final int commonAnswerCount;
  final int sameAnswerCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        children: [
          const Text(
            'あなたとの合致度',
            style: TextStyle(
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w700,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loading ? '—' : '$matchRate%',
            style: const TextStyle(
              fontSize: AppFontSize.xxxl,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loading
                ? '共通回答を集計中…'
                : '共通回答 $commonAnswerCount問 · 一致 $sameAnswerCount問',
            textAlign: TextAlign.center,
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

class _UserProfilePanel extends StatelessWidget {
  const _UserProfilePanel({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final bio = profile.bio.trim();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatItem(label: '回答数', value: '${profile.answerCount}'),
            _Divider(),
            _StatItem(label: '投稿数', value: '${profile.postCount}'),
            _Divider(),
            _StatItem(label: '友達数', value: '${profile.friendCount}'),
          ],
        ),
        if (profile.oddballScore > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
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
          ),
        ],
        PandaTypeProfileSection(profile: profile),
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
                bio.isEmpty ? 'まだ自己紹介がありません' : bio,
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        if (profile.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '傾向',
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
