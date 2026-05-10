import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/panda_avatar.dart';

class DirectChatScreen extends StatelessWidget {
  final DummyUser user;
  const DirectChatScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softGray,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: AppColors.black)),
                  const SizedBox(width: 12),
                  PandaAvatar(size: 32),
                  const SizedBox(width: 8),
                  Expanded(child: Text(user.name, style: const TextStyle(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.black))),
                  const Icon(Icons.more_horiz, color: AppColors.black),
                ],
              ),
            ),
            // メッセージ
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                itemCount: directMessages.length,
                itemBuilder: (context, i) {
                  final m = directMessages[i];
                  return ChatBubble(text: m.text, isMe: m.isMe, time: m.time);
                },
              ),
            ),
            // フッター
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppColors.textGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.softGray,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Text('メッセージを入力…', style: TextStyle(fontSize: AppFontSize.md, color: AppColors.textGray)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward, color: AppColors.white, size: 20),
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
