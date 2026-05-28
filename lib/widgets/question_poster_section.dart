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
    return LayoutBuilder(
      builder: (context, constraints) {
        final tagline = categoryPosterTagline(question.category);
        final watermark = categoryWatermarkLabel(question.category);
        final isCompactHeight = constraints.maxHeight < 200;
        final mascotSize = isCompactHeight ? 60.0 : 72.0;
        final questionFontSize = isCompactHeight
            ? AppFontSize.lg
            : AppFontSize.xxl;
        final watermarkFontSize = isCompactHeight ? 36.0 : 56.0;

        return ClipRect(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 0,
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
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
                            fontSize: watermarkFontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black.withValues(alpha: 0.04),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isCompactHeight ? AppSpacing.sm : AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            PandaMascot(
                              size: mascotSize,
                              expression: pandaExpression,
                              assetPath: feedPanda.assetPathForExpression(
                                pandaExpression,
                              ),
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
                            height: 1.25,
                          ),
                        ),
                        SizedBox(
                          height: isCompactHeight
                              ? AppSpacing.sm
                              : AppSpacing.md,
                        ),
                        Text(
                          question.text,
                          style: TextStyle(
                            fontSize: questionFontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
