import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../match/answer_compare_screen.dart';
import '../match/user_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  int _tabIndex = 0;
  final _searchController = TextEditingController(text: '@panda');

  final _friends = const [
    DummyUser(name: 'こうたろう', id: 'kotaro_123', matchRate: 92),
    DummyUser(name: 'まなみ', id: 'manami_456', matchRate: 88),
    DummyUser(name: 'たくみ', id: 'takumi_111', matchRate: 29),
  ];

  final _requests = const [
    DummyFriendRequest(
      user: DummyUser(name: 'りな', id: 'rina_222', matchRate: 31),
      message: '友達申請が届いています',
    ),
    DummyFriendRequest(
      user: DummyUser(name: 'ゆうき', id: 'yuuki_789', matchRate: 84),
      message: '回答の傾向が近いユーザーです',
    ),
  ];

  final _searchResults = const [
    DummyUser(name: 'ぱんだ好き', id: 'panda_love', matchRate: 74),
    DummyUser(name: 'ぱんだ社長', id: 'panda_ceo', matchRate: 52),
    DummyUser(name: 'ぱんだ夜型', id: 'panda_night', matchRate: 67),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Expanded(child: _buildTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    if (_tabIndex == 1) return _buildRequests();
    if (_tabIndex == 2) return _buildSearch();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: _friends.length,
      itemBuilder: (context, i) => _FriendTile(
        user: _friends[i],
        trailing: PandaOutlinedButton(label: '解除', width: 96, onTap: () {}),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailScreen(user: _friends[i]),
          ),
        ),
        onCompare: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnswerCompareScreen(user: _friends[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildRequests() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: _requests.length,
      itemBuilder: (context, i) {
        final request = _requests[i];
        return _RequestCard(request: request);
      },
    );
  }

  Widget _buildSearch() {
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
        ..._searchResults.map(
          (user) => _FriendTile(
            user: user,
            trailing: PandaButton(label: '申請', width: 96, onTap: () {}),
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
  const _RequestCard({required this.request});

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
                child: PandaButton(label: '承認', onTap: () {}),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PandaOutlinedButton(label: '断る', onTap: () {}),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
