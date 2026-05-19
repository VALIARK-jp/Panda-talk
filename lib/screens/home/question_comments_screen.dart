import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/comment_providers.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';

class QuestionCommentsScreen extends ConsumerStatefulWidget {
  final DummyQuestion question;

  const QuestionCommentsScreen({super.key, required this.question});

  static Future<bool> showModal(
    BuildContext context, {
    required DummyQuestion question,
  }) async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.88;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SizedBox(
            height: height,
            child: QuestionCommentsScreen(question: question),
          ),
        );
      },
    );
    return posted ?? false;
  }

  @override
  ConsumerState<QuestionCommentsScreen> createState() =>
      _QuestionCommentsScreenState();
}

class _QuestionCommentsScreenState
    extends ConsumerState<QuestionCommentsScreen> {
  int _tabIndex = 0;
  final _bodyController = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  String get _myAnswerOption {
    final fromFeed = ref
        .read(questionFeedControllerProvider)
        .selectedOptionFor(widget.question.number);
    return fromFeed ?? widget.question.myAnswer ?? widget.question.optionA;
  }

  Future<void> _submitComment() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      _showMessage('コメントを入力してください');
      return;
    }
    if (Supabase.instance.client.auth.currentSession == null) {
      _showMessage('コメントするにはログインが必要です');
      return;
    }
    if (widget.question.apiId == null) {
      _showMessage('この質問にはまだコメントできません');
      return;
    }

    setState(() => _posting = true);
    try {
      await ref
          .read(commentControllerProvider(widget.question).notifier)
          .postComment(_myAnswerOption, body);
      _bodyController.clear();
      if (mounted) {
        _showMessage('投稿しました');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('投稿に失敗しました。もう一度お試しください');
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final commentStateAsync = ref.watch(commentControllerProvider(widget.question));
    final commentsController = ref.read(
      commentControllerProvider(widget.question).notifier,
    );
    final myOption = _myAnswerOption;
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.black),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                widget.question.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
              child: commentStateAsync.when(
                data: (commentState) {
                  final visible = commentState.comments.where((c) {
                    if (_tabIndex == 1) return c.option == widget.question.optionA;
                    if (_tabIndex == 2) return c.option == widget.question.optionB;
                    return true;
                  }).toList();

                  if (visible.isEmpty) {
                    return const Center(
                      child: Text(
                        'まだコメントはありません',
                        style: TextStyle(color: AppColors.textGray),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final comment = visible[i];
                      return _CommentTile(
                        comment: comment,
                        canLike: isLoggedIn,
                        onLike: () async {
                          if (!isLoggedIn) {
                            _showMessage('いいねするにはログインが必要です');
                            return;
                          }
                          try {
                            await commentsController.toggleLike(comment);
                          } catch (_) {
                            if (mounted) {
                              _showMessage('いいねに失敗しました');
                            }
                          }
                        },
                        onDelete: () =>
                            commentsController.deleteComment(comment.id),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.black),
                ),
                error: (error, stack) => const Center(
                  child: Text(
                    'コメントを読み込めませんでした',
                    style: TextStyle(color: AppColors.textGray),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      enabled: isLoggedIn && !_posting,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: isLoggedIn
                            ? '$myOptionとしてコメント'
                            : 'ログインしてコメント',
                        filled: true,
                        fillColor: AppColors.softGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PandaButton(
                    label: _posting ? '…' : '投稿',
                    width: 76,
                    onTap: _posting || !isLoggedIn ? null : _submitComment,
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
  final bool canLike;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.canLike,
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
            onTap: canLike ? onLike : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  comment.likedByMe ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: comment.likedByMe
                      ? AppColors.likeRed
                      : AppColors.textGray,
                ),
                const SizedBox(width: 4),
                Text(
                  '${comment.likes}',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w700,
                    color: comment.likedByMe
                        ? AppColors.likeRed
                        : AppColors.textGray,
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
