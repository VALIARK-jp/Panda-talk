import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../core/share_utils.dart';
import '../../presentation/providers/friend_providers.dart';
import '../../presentation/providers/match_providers.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../talk/direct_chat_screen.dart';
import 'answer_compare_screen.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final DummyUser user;
  const UserDetailScreen({super.key, required this.user});

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

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final compareAsync = ref.watch(compareAnswersProvider(u.id));
    final compareAnswers = compareAsync.valueOrNull ?? const [];
    final commonAnswerCount = compareAnswers.length;
    final sameAnswerCount = compareAnswers
        .where((answer) => answer['match'] == true)
        .length;
    final displayedMatchRate = commonAnswerCount > 0
        ? (sameAnswerCount / commonAnswerCount * 100).round()
        : u.matchRate;
    final friendState = ref.watch(friendControllerProvider).valueOrNull;
    final isFriend =
        friendState?.friends.any((friend) => friend.id == u.id) ?? false;
    final isRequested = friendState?.requestedUserIds.contains(u.id) ?? false;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              // ヘッダー
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.black),
                  ),
                  GestureDetector(
                    onTap: () => AppShare.text(
                      context,
                      '${u.name}さんと合致度$displayedMatchRate%！\n価値観めっちゃ近い\n#パンダトーク',
                    ),
                    child: const Icon(Icons.ios_share, color: AppColors.black),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PandaAvatar(size: 80),
              const SizedBox(height: AppSpacing.md),
              Text(
                u.name,
                style: const TextStyle(
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              Text(
                '@${u.id}',
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '合致度 $displayedMatchRate%',
                style: const TextStyle(
                  fontSize: AppFontSize.xxxl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                compareAsync.isLoading
                    ? '共通回答数 読み込み中'
                    : '共通回答数 $commonAnswerCount問',
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  color: AppColors.textGray,
                ),
              ),
              Text(
                compareAsync.isLoading
                    ? '一致した質問 読み込み中'
                    : '一致した質問 $sameAnswerCount問',
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SegmentedTabs(
                tabs: const ['プロフィール', '回答を見る'],
                selectedIndex: _tabIndex,
                onChanged: (i) {
                  setState(() => _tabIndex = i);
                  if (i == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnswerCompareScreen(user: widget.user),
                      ),
                    );
                  }
                },
              ),
              const Spacer(),
              PandaButton(
                label: isFriend ? '友達' : (isRequested ? '申請済み' : '友達申請を送る'),
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
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
