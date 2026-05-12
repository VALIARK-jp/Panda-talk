import 'package:flutter/material.dart';
import '../core/design_tokens.dart';
import 'panda_avatar.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final String? senderName;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[PandaAvatar(size: 32), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (senderName != null && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      senderName!,
                      style: const TextStyle(
                        fontSize: AppFontSize.sm,
                        color: AppColors.textGray,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.black : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.lg),
                      topRight: const Radius.circular(AppRadius.lg),
                      bottomLeft: isMe
                          ? const Radius.circular(AppRadius.lg)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(AppRadius.lg),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: AppColors.borderGray),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? AppColors.white : AppColors.black,
                      fontSize: AppFontSize.md,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
