import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/friend_providers.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../match/answer_compare_screen.dart';
import '../match/user_detail_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tabIndex = 0;
  final _searchController = TextEditingController(text: '@panda');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendStateAsync = ref.watch(friendControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.black),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '友達',
                    style: TextStyle(
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SegmentedTabs(
                tabs: const ['一覧', '申請', '検索'],
                selectedIndex: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: friendStateAsync.when(
                data: (friendState) => _buildTab(friendState),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.black),
                ),
                error: (e, st) => Center(
                  child: Text('エラーが発生しました\n$e', textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(FriendState friendState) {
    if (_tabIndex == 1) return _buildRequests(friendState);
    if (_tabIndex == 2) return _buildSearch(friendState);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: friendState.friends.length,
      itemBuilder: (context, i) => _FriendTile(
        user: friendState.friends[i],
        trailing: PandaOutlinedButton(
          label: '解除',
          width: 96,
          onTap: () => ref
              .read(friendControllerProvider.notifier)
              .deleteFriendship(friendState.friends[i].id),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailScreen(user: friendState.friends[i]),
          ),
        ),
        onCompare: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnswerCompareScreen(user: friendState.friends[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildRequests(FriendState friendState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: friendState.requests.length,
      itemBuilder: (context, i) {
        final request = friendState.requests[i];
        return _RequestCard(
          request: request,
          onAccept: () => ref
              .read(friendControllerProvider.notifier)
              .acceptRequest(request.user.id),
          onReject: () => ref
              .read(friendControllerProvider.notifier)
              .rejectRequest(request.user.id),
        );
      },
    );
  }

  Widget _buildSearch(FriendState friendState) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.softGray,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: AppColors.textGray),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: ref
                      .read(friendControllerProvider.notifier)
                      .setSearchQuery,
                  decoration: const InputDecoration.collapsed(
                    hintText: '@usernameで検索',
                  ),
                  style: const TextStyle(
                    fontSize: AppFontSize.md,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...friendState.searchResults.map(
          (user) => _FriendTile(
            user: user,
            trailing: friendState.requestedUserIds.contains(user.id)
                ? const _RequestedBadge()
                : PandaButton(
                    label: '申請',
                    width: 96,
                    onTap: () => ref
                        .read(friendControllerProvider.notifier)
                        .sendFriendRequest(user.id),
                  ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  final DummyUser user;
  final Widget trailing;
  final VoidCallback onTap;
  final VoidCallback? onCompare;

  const _FriendTile({
    required this.user,
    required this.trailing,
    required this.onTap,
    this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
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
          GestureDetector(onTap: onTap, child: PandaAvatar(size: 44)),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
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
          if (onCompare != null) ...[
            IconButton(
              onPressed: onCompare,
              icon: const Icon(Icons.compare_arrows, color: AppColors.black),
            ),
            const SizedBox(width: 4),
          ],
          trailing,
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final DummyFriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PandaAvatar(size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.user.name,
                      style: const TextStyle(
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      request.message,
                      style: const TextStyle(
                        fontSize: AppFontSize.sm,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PandaButton(label: '承認', onTap: onAccept),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PandaOutlinedButton(label: '断る', onTap: onReject),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestedBadge extends StatelessWidget {
  const _RequestedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      alignment: Alignment.center,
      child: const Text(
        '申請済み',
        style: TextStyle(
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w800,
          color: AppColors.textGray,
        ),
      ),
    );
  }
}
