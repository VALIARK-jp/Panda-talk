import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import 'speech_bubble.dart';

/// フィード上で「コメントが伸びている」ことを伝える吹き出し。
class CommentActivityHint extends StatelessWidget {
  final int commentCount;

  const CommentActivityHint({super.key, required this.commentCount});

  static bool shouldShow(int commentCount) => commentCount >= 3;

  @override
  Widget build(BuildContext context) {
    final label = commentCount >= 10
        ? 'コメントが伸びてる'
        : 'コメントが増えてる';

    return SpeechBubble(
      text: label,
      variant: SpeechBubbleVariant.dark,
      tail: SpeechBubbleTail.bottomLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      maxLines: 2,
      textStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        height: 1.2,
      ),
    );
  }
}
