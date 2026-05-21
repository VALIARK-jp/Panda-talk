import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/comment_providers.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/panda_button.dart';

/// `a` / `b` と表示ラベルのどちらでも選択肢を判定する。
String? resolveSelectedOptionLabel(DummyQuestion question, String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value == 'a' || value == question.optionA) return question.optionA;
  if (value == 'b' || value == question.optionB) return question.optionB;
  return value;
}

bool commentMatchesOptionA(DummyComment comment, DummyQuestion question) {
  final value = comment.option.trim();
  if (value == 'a' || value == question.optionA) return true;
  if (value == 'b' || value == question.optionB) return false;
  return value == question.optionA;
}

/// A/B 二列でコメント一覧と投稿欄を表示する。
class SplitOptionCommentsPanel extends ConsumerStatefulWidget {
  final DummyQuestion question;
  final String? mySelectedOption;
  final bool popOnPost;
  final VoidCallback? onCommentPosted;

  const SplitOptionCommentsPanel({
    super.key,
    required this.question,
    this.mySelectedOption,
    this.popOnPost = false,
    this.onCommentPosted,
  });

  @override
  ConsumerState<SplitOptionCommentsPanel> createState() =>
      _SplitOptionCommentsPanelState();
}

class _SplitOptionCommentsPanelState
    extends ConsumerState<SplitOptionCommentsPanel> {
  final _bodyControllerA = TextEditingController();
  final _bodyControllerB = TextEditingController();
  bool _postingA = false;
  bool _postingB = false;

  @override
  void dispose() {
    _bodyControllerA.dispose();
    _bodyControllerB.dispose();
    super.dispose();
  }

  String? get _myAnswerOption {
    final fromFeed = ref
        .read(questionFeedControllerProvider)
        .selectedOptionFor(widget.question.number);
    return resolveSelectedOptionLabel(
      widget.question,
      widget.mySelectedOption ?? fromFeed ?? widget.question.myAnswer,
    );
  }

  Future<void> _submitComment(
    String option,
    TextEditingController controller,
    void Function(bool) setPosting,
  ) async {
    final body = controller.text.trim();
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

    setPosting(true);
    try {
      await ref
          .read(commentControllerProvider(widget.question).notifier)
          .postComment(option, body);
      controller.clear();
      if (!mounted) return;
      _showMessage('投稿しました');
      widget.onCommentPosted?.call();
      if (widget.popOnPost) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('投稿に失敗しました。もう一度お試しください');
      }
    } finally {
      if (mounted) setPosting(false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final commentStateAsync =
        ref.watch(commentControllerProvider(widget.question));
    final commentsController = ref.read(
      commentControllerProvider(widget.question).notifier,
    );
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final myOption = _myAnswerOption;

    return commentStateAsync.when(
      data: (commentState) {
        final commentsA = commentState.comments
            .where((c) => commentMatchesOptionA(c, widget.question))
            .toList();
        final commentsB = commentState.comments
            .where((c) => !commentMatchesOptionA(c, widget.question))
            .toList();
        final hasAnswered = myOption != null;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _OptionCommentColumn(
                optionLabel: widget.question.optionA,
                dark: false,
                comments: commentsA,
                isMySide: myOption == widget.question.optionA,
                hasAnswered: hasAnswered,
                isLoggedIn: isLoggedIn,
                canPost: isLoggedIn && myOption == widget.question.optionA,
                posting: _postingA,
                bodyController: _bodyControllerA,
                onPost: () => _submitComment(
                  widget.question.optionA,
                  _bodyControllerA,
                  (v) => setState(() => _postingA = v),
                ),
                onLike: (comment) => _toggleLike(commentsController, comment),
                onDelete: (id) => commentsController.deleteComment(id),
              ),
            ),
            Container(width: 1, color: AppColors.borderGray),
            Expanded(
              child: _OptionCommentColumn(
                optionLabel: widget.question.optionB,
                dark: true,
                comments: commentsB,
                isMySide: myOption == widget.question.optionB,
                hasAnswered: hasAnswered,
                isLoggedIn: isLoggedIn,
                canPost: isLoggedIn && myOption == widget.question.optionB,
                posting: _postingB,
                bodyController: _bodyControllerB,
                onPost: () => _submitComment(
                  widget.question.optionB,
                  _bodyControllerB,
                  (v) => setState(() => _postingB = v),
                ),
                onLike: (comment) => _toggleLike(commentsController, comment),
                onDelete: (id) => commentsController.deleteComment(id),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.black),
      ),
      error: (_, __) => const Center(
        child: Text(
          'コメントを読み込めませんでした',
          style: TextStyle(color: AppColors.textGray),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _toggleLike(
    CommentController controller,
    DummyComment comment,
  ) async {
    if (Supabase.instance.client.auth.currentSession == null) {
      _showMessage('いいねするにはログインが必要です');
      return;
    }
    try {
      await controller.toggleLike(comment);
    } catch (_) {
      if (mounted) _showMessage('いいねに失敗しました');
    }
  }
}

class _OptionCommentColumn extends StatelessWidget {
  final String optionLabel;
  final bool dark;
  final List<DummyComment> comments;
  final bool isMySide;
  final bool hasAnswered;
  final bool isLoggedIn;
  final bool canPost;
  final bool posting;
  final TextEditingController bodyController;
  final VoidCallback onPost;
  final Future<void> Function(DummyComment) onLike;
  final void Function(String) onDelete;

  const _OptionCommentColumn({
    required this.optionLabel,
    required this.dark,
    required this.comments,
    required this.isMySide,
    required this.hasAnswered,
    required this.isLoggedIn,
    required this.canPost,
    required this.posting,
    required this.bodyController,
    required this.onPost,
    required this.onLike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          color: dark ? AppColors.black : AppColors.softGray,
          child: Column(
            children: [
              Text(
                optionLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w800,
                  color: dark ? AppColors.white : AppColors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isMySide)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.white.withValues(alpha: 0.2)
                            : AppColors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'あなた',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: dark ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                  Text(
                    '${comments.length}件',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: dark
                          ? AppColors.white.withValues(alpha: 0.75)
                          : AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: comments.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      'まだコメントなし',
                      style: TextStyle(
                        fontSize: AppFontSize.sm,
                        color: AppColors.textGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: comments.length,
                  itemBuilder: (context, i) {
                    final comment = comments[i];
                    return _CommentTile(
                      comment: comment,
                      compact: true,
                      canLike: isLoggedIn,
                      onLike: () => onLike(comment),
                      onDelete: () => onDelete(comment.id),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: canPost
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bodyController,
                        enabled: !posting,
                        minLines: 1,
                        maxLines: 3,
                        style: const TextStyle(fontSize: AppFontSize.sm),
                        decoration: InputDecoration(
                          hintText: 'コメント',
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.softGray,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    PandaButton(
                      label: posting ? '…' : '送',
                      width: 44,
                      onTap: posting ? null : onPost,
                    ),
                  ],
                )
              : hasAnswered
                  ? const SizedBox(height: 4)
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        isLoggedIn
                            ? '先に二択に回答してください'
                            : 'ログインしてコメント',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final DummyComment comment;
  final bool compact;
  final bool canLike;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    this.compact = false,
    required this.canLike,
    required this.onLike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 6 : 8),
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact && comment.isMine)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textGray,
                  size: 16,
                ),
              ),
            ),
          Text(
            comment.body,
            style: TextStyle(
              fontSize: compact ? AppFontSize.sm : AppFontSize.md,
              color: AppColors.black,
              height: 1.35,
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
          GestureDetector(
            onTap: canLike ? onLike : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  comment.likedByMe ? Icons.favorite : Icons.favorite_border,
                  size: compact ? 16 : 18,
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
