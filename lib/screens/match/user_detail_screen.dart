import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../talk/direct_chat_screen.dart';
import 'answer_compare_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final DummyUser user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
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
                    onTap: () => Share.share(
                      '${u.name}さんと合致度${u.matchRate}%！\n価値観めっちゃ近い🐼\n#パンダトーク',
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
                '合致度 ${u.matchRate}%',
                style: const TextStyle(
                  fontSize: AppFontSize.xxxl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '共通回答数 128問',
                style: TextStyle(
                  fontSize: AppFontSize.md,
                  color: AppColors.textGray,
                ),
              ),
              const Text(
                '一致した質問 112問',
                style: TextStyle(
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
              PandaButton(label: '友達申請を送る', onTap: () {}),
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
