import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/match_providers.dart';
import '../../widgets/match_user_tile.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/segmented_tabs.dart';
import '../friends/friends_screen.dart';
import 'user_detail_screen.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  int _tabIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _requestedUserIds = {};

  final _friendCandidates = const [
    DummyUser(name: 'ぱんだ好き', id: 'panda_love', matchRate: 74),
    DummyUser(name: 'ぱんだ夜型', id: 'panda_night', matchRate: 67),
    DummyUser(name: 'ぱんだ社長', id: 'panda_ceo', matchRate: 52),
    DummyUser(name: 'こうたろう', id: 'kotaro_123', matchRate: 92),
    DummyUser(name: 'まなみ', id: 'manami_456', matchRate: 88),
  ];

  AsyncValue<List<DummyUser>> get _usersAsync {
    if (_tabIndex == 0) return ref.watch(similarUsersProvider);
    if (_tabIndex == 1) return ref.watch(oppositeUsersProvider);
    return ref.watch(middleUsersProvider);
  }

  List<DummyUser> get _searchResults {
    final query = _searchQuery.trim().replaceFirst('@', '').toLowerCase();
    if (query.isEmpty) return const [];
    return _friendCandidates.where((user) {
      return user.id.toLowerCase().startsWith(query) ||
          user.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _searchQuery.trim().isNotEmpty;

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
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: const InputDecoration.collapsed(
                          hintText: '@usernameで友達検索',
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
                    ? _FriendSearchResults(
                        users: _searchResults,
                        requestedUserIds: _requestedUserIds,
                        onOpenUser: (user) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserDetailScreen(user: user),
                          ),
                        ),
                        onRequest: (user) {
                          setState(() => _requestedUserIds.add(user.id));
                        },
                      )
                    : _usersAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('エラー: $e')),
                        data: (users) => ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, i) {
                            final u = users[i];
                            return MatchUserTile(
                              rank: i + 1,
                              name: u.name,
                              matchRate: u.matchRate,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserDetailScreen(user: u),
                                ),
                              ),
                            );
                          },
                        ),
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
      return const Center(
        child: Text(
          '該当するユーザーがいません',
          style: TextStyle(fontSize: AppFontSize.md, color: AppColors.textGray),
        ),
      );
    }

    return ListView.builder(
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
                child: PandaAvatar(size: 44),
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
                        '@${user.id}  合致度 ${user.matchRate}%',
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
