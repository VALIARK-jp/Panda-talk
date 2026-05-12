import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/talk_providers.dart';
import '../../widgets/group_card.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/segmented_tabs.dart';
import 'direct_chat_screen.dart';
import 'group_chat_screen.dart';

class TalkScreen extends ConsumerStatefulWidget {
  const TalkScreen({super.key});

  @override
  ConsumerState<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends ConsumerState<TalkScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final threads = ref.watch(directThreadsProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Text(
                'トーク',
                style: TextStyle(
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
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
                    ? _DmList(threads: threads)
                    : groupsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('エラー: $e')),
                        data: (groups) => ListView.builder(
                          itemCount: groups.length + 1,
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
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
                        ),
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
  const _DmList({required this.threads});

  @override
  Widget build(BuildContext context) {
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
