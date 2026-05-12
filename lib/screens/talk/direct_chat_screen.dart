import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/talk_providers.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/panda_avatar.dart';

class DirectChatScreen extends ConsumerStatefulWidget {
  final DummyUser user;
  const DirectChatScreen({super.key, required this.user});

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _send() {
    ref
        .read(messageActionsProvider)
        .sendDirectMessage(widget.user.id, _messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(directMessagesProvider(widget.user.id));
    return Scaffold(
      backgroundColor: AppColors.softGray,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.white,
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
                  PandaAvatar(size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.more_horiz, color: AppColors.black),
                ],
              ),
            ),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (messages) => ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    return ChatBubble(text: m.text, isMe: m.isMe, time: m.time);
                  },
                ),
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppColors.textGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.softGray,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'メッセージを入力...',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
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
