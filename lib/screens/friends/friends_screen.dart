import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/friend_providers.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/user_avatar.dart';
import '../match/user_detail_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tabIndex = 0;

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
                tabs: const ['一覧', '申請'],
                selectedIndex: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: friendStateAsync.when(
                data: (friendState) => _tabIndex == 0
                    ? _buildFriendsList(friendState)
                    : _buildRequests(friendState),
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

  void _openProfile(DummyUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
    );
  }

  Widget _buildFriendsList(FriendState friendState) {
    if (friendState.friends.isEmpty) {
      return const Center(
        child: Text(
          'まだ友達がいません',
          style: TextStyle(fontSize: AppFontSize.md, color: AppColors.textGray),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: friendState.friends.length,
      itemBuilder: (context, i) {
        final user = friendState.friends[i];
        return _FriendTile(
          user: user,
          trailing: PandaOutlinedButton(
            label: '解除',
            width: 96,
            onTap: () => ref
                .read(friendControllerProvider.notifier)
                .deleteFriendship(user.id),
          ),
          onTap: () => _openProfile(user),
        );
      },
    );
  }

  Widget _buildRequests(FriendState friendState) {
    if (friendState.requests.isEmpty) {
      return const Center(
        child: Text(
          '届いている申請はありません',
          style: TextStyle(fontSize: AppFontSize.md, color: AppColors.textGray),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: friendState.requests.length,
      itemBuilder: (context, i) {
        final request = friendState.requests[i];
        return _RequestCard(
          request: request,
          onOpenProfile: () => _openProfile(request.user),
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
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.user,
    required this.trailing,
    required this.onTap,
  });

  final DummyUser user;
  final Widget trailing;
  final VoidCallback onTap;

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
          GestureDetector(
            onTap: onTap,
            child: UserAvatar(size: 44, imageUrl: user.avatarUrl),
          ),
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
                    '@${user.id}',
                    style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onOpenProfile,
    required this.onAccept,
    required this.onReject,
  });

  final DummyFriendRequest request;
  final VoidCallback onOpenProfile;
  final VoidCallback onAccept;
  final VoidCallback onReject;

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
          GestureDetector(
            onTap: onOpenProfile,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                UserAvatar(size: 44, imageUrl: request.user.avatarUrl),
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
                const Icon(Icons.chevron_right, color: AppColors.textGray),
              ],
            ),
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
