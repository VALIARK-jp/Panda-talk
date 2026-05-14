import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/talk_providers.dart';
import '../../widgets/chat_bubble.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final DummyGroup group;
  const GroupChatScreen({super.key, required this.group});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _send() {
    ref
        .read(messageActionsProvider)
        .sendGroupMessage(widget.group.id, _messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(groupMessagesProvider(widget.group.id));
    final group = widget.group;
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: AppFontSize.lg,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          '(${group.members.length}人)',
                          style: const TextStyle(
                            fontSize: AppFontSize.sm,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz, color: AppColors.black),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.members
                    .map(
                      (member) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softGray,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '$member / ${group.avgMatchRate}%',
                          style: const TextStyle(
                            fontSize: AppFontSize.sm,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    )
                    .toList(),
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
                    return ChatBubble(
                      text: m.text,
                      isMe: m.isMe,
                      time: m.time,
                      senderName: m.senderName,
                    );
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
