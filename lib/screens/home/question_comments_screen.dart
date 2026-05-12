import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/comment_providers.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';

class QuestionCommentsScreen extends ConsumerStatefulWidget {
  final DummyQuestion question;
  const QuestionCommentsScreen({super.key, required this.question});

  @override
  ConsumerState<QuestionCommentsScreen> createState() =>
      _QuestionCommentsScreenState();
}

class _QuestionCommentsScreenState
    extends ConsumerState<QuestionCommentsScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final commentState = ref.watch(commentControllerProvider(widget.question));
    final commentsController = ref.read(
      commentControllerProvider(widget.question).notifier,
    );
    final visible = commentState.comments.where((c) {
      if (_tabIndex == 1) return c.option == widget.question.optionA;
      if (_tabIndex == 2) return c.option == widget.question.optionB;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
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
                  const Expanded(
                    child: Text(
                      'コメント',
                      style: TextStyle(
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                widget.question.text,
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SegmentedTabs(
                tabs: ['すべて', widget.question.optionA, widget.question.optionB],
                selectedIndex: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final comment = visible[i];
                  return _CommentTile(
                    comment: comment,
                    onLike: () => commentsController.toggleLike(comment.id),
                    onDelete: () =>
                        commentsController.deleteComment(comment.id),
                  );
                },
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softGray,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${widget.question.optionA}として匿名コメント',
                        style: const TextStyle(
                          fontSize: AppFontSize.md,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PandaButton(
                    label: '投稿',
                    width: 76,
                    onTap: () => commentsController.postComment(
                      widget.question.optionA,
                      '匿名コメントを投稿しました。',
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

class _CommentTile extends StatelessWidget {
  final DummyComment comment;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Text(
                  comment.option,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              const Spacer(),
              if (comment.isMine)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.textGray,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.body,
            style: const TextStyle(
              fontSize: AppFontSize.md,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  comment.likedByMe ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: AppColors.black,
                ),
                const SizedBox(width: 4),
                Text(
                  '${comment.likes}',
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
    );
  }
}
