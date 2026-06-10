import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_error_messages.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/friend_providers.dart';
import '../../presentation/providers/match_providers.dart';
import '../../presentation/providers/moderation_providers.dart';
import '../../widgets/guest_login_button.dart';
import '../../widgets/login_required_gate.dart';
import '../../widgets/match_user_tile.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/user_avatar.dart';
import '../friends/friends_screen.dart';
import 'user_detail_screen.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key, this.onOpenDiagnosis});

  final VoidCallback? onOpenDiagnosis;

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  int _tabIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  AsyncValue<List<DummyUser>> get _usersAsync {
    if (_tabIndex == 0) return ref.watch(similarUsersProvider);
    if (_tabIndex == 1) return ref.watch(oppositeUsersProvider);
    return ref.watch(middleUsersProvider);
  }

  Future<void> _refreshMatchData() async {
    try {
      if (_searchQuery.trim().isNotEmpty) {
        await ref
            .read(friendControllerProvider.notifier)
            .setSearchQuery(_searchQuery);
        return;
      }
      await refreshMatchLists(ref, activeTabIndex: _tabIndex);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: ${formatApiUserFacingError(e)}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user =
        ref.watch(authUserProvider).valueOrNull ??
        Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const LoginRequiredGate(featureLabel: 'マッチ');
    }

    final searching = _searchQuery.trim().isNotEmpty;
    final friendStateAsync = ref.watch(friendControllerProvider);
    final blockedUserIds =
        ref.watch(moderationControllerProvider).valueOrNull?.blockedUserIds ??
        const {};

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'マッチ',
                      style: TextStyle(
                        fontSize: AppFontSize.xxl,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FriendsScreen()),
                    ),
                    icon: const Icon(
                      Icons.people_outline,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const GuestLoginButton(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textGray,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          ref
                              .read(friendControllerProvider.notifier)
                              .setSearchQuery(value);
                        },
                        decoration: const InputDecoration.collapsed(
                          hintText: 'ユーザー名 / ユーザーコードで友達検索',
                        ),
                        style: const TextStyle(
                          fontSize: AppFontSize.md,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    if (searching)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          ref
                              .read(friendControllerProvider.notifier)
                              .setSearchQuery('');
                        },
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textGray,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!searching) ...[
                SegmentedTabs(
                  tabs: const ['似ている人', '真逆な人', '50%付近'],
                  selectedIndex: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Expanded(
                child: searching
                    ? friendStateAsync.when(
                        data: (friendState) => RefreshIndicator(
                          onRefresh: _refreshMatchData,
                          child: _FriendSearchResults(
                            users: friendState.searchResults
                                .where((user) => !blockedUserIds.contains(user.id))
                                .toList(),
                            requestedUserIds: friendState.requestedUserIds,
                            onOpenUser: (user) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserDetailScreen(user: user, fromMatch: true),
                              ),
                            ),
                            onRequest: (user) => ref
                                .read(friendControllerProvider.notifier)
                                .sendFriendRequest(user.id),
                          ),
                        ),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.black,
                          ),
                        ),
                        error: (e, st) => Center(
                          child: Text(
                            'エラーが発生しました\n${formatApiUserFacingError(e)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _usersAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Text(
                            'エラー: ${formatApiUserFacingError(e)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        data: (users) {
                          final visibleUsers = users
                              .where((user) => !blockedUserIds.contains(user.id))
                              .toList();
                          if (visibleUsers.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: _refreshMatchData,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.sizeOf(context).height * 0.55,
                                  child: _MatchEmptyState(
                                    onOpenDiagnosis: widget.onOpenDiagnosis,
                                  ),
                                ),
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: _refreshMatchData,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: visibleUsers.length,
                              itemBuilder: (context, i) {
                                final u = visibleUsers[i];
                                return MatchUserTile(
                                  rank: i + 1,
                                  name: u.name,
                                  matchRate: u.resolvedMatchRate,
                                  avatarUrl: u.avatarUrl,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserDetailScreen(
                                        user: u,
                                        fromMatch: true,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchEmptyState extends StatelessWidget {
  const _MatchEmptyState({required this.onOpenDiagnosis});

  final VoidCallback? onOpenDiagnosis;

  @override
  Widget build(BuildContext context) {
    return _EmptyActionPanel(
      title: 'まだ候補が少ないです',
      body: '質問に答えるほど、合致度の高い相手や真逆の相手が見つかりやすくなります。',
      actionLabel: '診断で回答を増やす',
      onAction: onOpenDiagnosis,
    );
  }
}

class _FriendSearchResults extends StatelessWidget {
  final List<DummyUser> users;
  final Set<String> requestedUserIds;
  final ValueChanged<DummyUser> onOpenUser;
  final ValueChanged<DummyUser> onRequest;

  const _FriendSearchResults({
    required this.users,
    required this.requestedUserIds,
    required this.onOpenUser,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PandaAvatar(size: 64),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      '該当するユーザーがいません',
                      style: TextStyle(
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'ユーザー名かユーザーコードを変えて検索してみてください',
                      style: TextStyle(
                        fontSize: AppFontSize.sm,
                        color: AppColors.textGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final user = users[i];
        final requested = requestedUserIds.contains(user.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onOpenUser(user),
                child: UserAvatar(size: 44, imageUrl: user.avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => onOpenUser(user),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: AppFontSize.md,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username ?? user.id}  合致度 ${user.matchRate}%',
                        style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: requested ? null : () => onRequest(user),
                child: Container(
                  width: 104,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: requested ? AppColors.softGray : AppColors.black,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    requested ? '申請済み' : '友達申請',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w800,
                      color: requested ? AppColors.textGray : AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyActionPanel extends StatelessWidget {
  const _EmptyActionPanel({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PandaAvatar(size: 64),
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
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
