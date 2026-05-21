import 'package:flutter/material.dart';

import '../core/category_poster_copy.dart';
import '../core/design_tokens.dart';
import '../core/dummy_data.dart';
import '../core/feed_panda_picker.dart';
import 'panda_avatar.dart';

/// 質問カードのポスター風ヘッダー（カテゴリ空気感 + タイポ強化）。
class QuestionPosterSection extends StatelessWidget {
  final DummyQuestion question;
  final String pandaExpression;
  final FeedPandaChoice feedPanda;
  final Widget? commentHint;

  QuestionPosterSection({
    super.key,
    required this.question,
    this.pandaExpression = 'normal',
    FeedPandaChoice? feedPandaChoice,
    this.commentHint,
  }) : feedPanda = feedPandaChoice ?? FeedPandaChoice.forQuestion(question);

  @override
  Widget build(BuildContext context) {
    final tagline = categoryPosterTagline(question.category);
    final watermark = categoryWatermarkLabel(question.category);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (watermark != null)
          Positioned(
            top: -8,
            left: -4,
            right: -4,
            child: IgnorePointer(
              child: Text(
                watermark,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black.withValues(alpha: 0.04),
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                PandaMascot(
                  size: 72,
                  expression: pandaExpression,
                  assetPath: feedPanda.assetPathForExpression(pandaExpression),
                ),
                if (commentHint != null)
                  Positioned(
                    right: -12,
                    top: -6,
                    child: commentHint!,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              tagline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              question.text,
              style: const TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
                height: 1.35,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}
