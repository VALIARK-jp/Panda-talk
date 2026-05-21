import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../widgets/answer_ratio_bar.dart';
import 'split_option_comments_panel.dart';

/// コメント表示時: 質問文 + 比率バー（上部）+ A/B コメント全画面。
class QuestionCommentFocusScreen extends StatefulWidget {
  final DummyQuestion question;
  final int percentA;
  final String? selectedOption;

  const QuestionCommentFocusScreen({
    super.key,
    required this.question,
    required this.percentA,
    required this.selectedOption,
  });

  @override
  State<QuestionCommentFocusScreen> createState() =>
      _QuestionCommentFocusScreenState();
}

class _QuestionCommentFocusScreenState extends State<QuestionCommentFocusScreen> {
  bool _posted = false;

  void _close() {
    Navigator.pop(context, _posted);
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = AppSpacing.md;

    return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: '閉じる',
                  onPressed: _close,
                  icon: const Icon(Icons.close, color: AppColors.black),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  0,
                  horizontal,
                  AppSpacing.sm,
                ),
                child: Text(
                  widget.question.text,
                  style: const TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Hero(
                  tag: answerRatioBarHeroTag(widget.question),
                  child: Material(
                    color: Colors.transparent,
                    child: AnswerRatioBar(
                      question: widget.question,
                      percentA: widget.percentA,
                      selectedOption: widget.selectedOption,
                      interactive: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.borderGray.withValues(alpha: 0.6),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SplitOptionCommentsPanel(
                    question: widget.question,
                    mySelectedOption: widget.selectedOption,
                    onCommentPosted: () => _posted = true,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
