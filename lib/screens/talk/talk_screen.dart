import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/talk_providers.dart';
import '../../widgets/guest_login_button.dart';
import '../../widgets/group_card.dart';
import '../../widgets/login_required_gate.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/segmented_tabs.dart';
import 'direct_chat_screen.dart';
import 'group_chat_screen.dart';

class TalkScreen extends ConsumerStatefulWidget {
  const TalkScreen({super.key, this.onOpenMatch});

  final VoidCallback? onOpenMatch;

  @override
  ConsumerState<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends ConsumerState<TalkScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user =
        ref.watch(authUserProvider).valueOrNull ??
        Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const LoginRequiredGate(featureLabel: 'トーク');
    }

    final groupsAsync = ref.watch(groupsProvider);
    final threadsAsync = ref.watch(directThreadsProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'トーク',
                      style: TextStyle(
                        fontSize: AppFontSize.xxl,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  GuestLoginButton(),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedTabs(
                tabs: const ['DM', 'グループ'],
                selectedIndex: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _tabIndex == 0
                    ? threadsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('エラー: $e')),
                        data: (threads) => _DmList(
                          threads: threads,
                          onOpenMatch: widget.onOpenMatch,
                        ),
                      )
                    : groupsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('エラー: $e')),
                        data: (groups) {
                          if (groups.isEmpty) {
                            return _TalkEmptyState(
                              title: 'まだグループがありません',
                              body: '回答が増えると、合致度に応じたグループに入りやすくなります。',
                              onOpenMatch: widget.onOpenMatch,
                            );
                          }
                          return ListView.builder(
                            itemCount: groups.length + 1,
                            itemBuilder: (context, i) {
                              if (i == 0) {
                                return const Padding(
                                  padding: EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: Text(
                                    '所属グループ。新規登録時に自動参加し、毎月1日に再編成されます。',
                                    style: TextStyle(
                                      fontSize: AppFontSize.sm,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                );
                              }
                              final g = groups[i - 1];
                              return GroupCard(
                                name: g.name,
                                avgMatchRate: g.avgMatchRate,
                                members: g.members,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GroupChatScreen(group: g),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DmList extends StatelessWidget {
  final List<DummyDirectThread> threads;
  final VoidCallback? onOpenMatch;
  const _DmList({required this.threads, required this.onOpenMatch});

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) {
      return _TalkEmptyState(
        title: 'まだトークがありません',
        body: '合致度の高い相手を見つけて、友達になったらメッセージを始めましょう。',
        onOpenMatch: onOpenMatch,
      );
    }

    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (context, i) {
        final thread = threads[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DirectChatScreen(user: thread.user),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Row(
              children: [
                PandaAvatar(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.user.name,
                        style: const TextStyle(
                          fontSize: AppFontSize.md,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      thread.time,
                      style: const TextStyle(
                        fontSize: AppFontSize.sm,
                        color: AppColors.textGray,
                      ),
                    ),
                    if (thread.unreadCount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style: const TextStyle(
                            fontSize: AppFontSize.sm,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TalkEmptyState extends StatelessWidget {
  const _TalkEmptyState({
    required this.title,
    required this.body,
    required this.onOpenMatch,
  });

  final String title;
  final String body;
  final VoidCallback? onOpenMatch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PandaAvatar(size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: const TextStyle(
                fontSize: AppFontSize.md,
                height: 1.5,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: onOpenMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  textStyle: const TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('合致度の高い友達を探す'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
