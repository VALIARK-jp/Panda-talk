import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

class CommentState {
  final DummyQuestion question;
  final List<DummyComment> comments;

  const CommentState({required this.question, required this.comments});
}

class CommentController
    extends AutoDisposeFamilyAsyncNotifier<CommentState, DummyQuestion> {
  @override
  Future<CommentState> build(DummyQuestion arg) async {
    final comments =
        await ref.read(commentRepositoryProvider).getComments(arg);
    return CommentState(question: arg, comments: comments);
  }

  Future<void> toggleLike(DummyComment comment) async {
    if (Supabase.instance.client.auth.currentSession == null) {
      throw StateError('いいねするにはログインが必要です');
    }

    final prev = state;
    final current = prev.value;
    if (current == null) return;

    final newLiked = !comment.likedByMe;
    final updatedComments = current.comments.map((c) {
      if (c.id != comment.id) return c;
      final likes = newLiked
          ? c.likes + 1
          : (c.likes > 0 ? c.likes - 1 : 0);
      return c.copyWith(likedByMe: newLiked, likes: likes);
    }).toList();

    state = AsyncValue.data(
      CommentState(question: arg, comments: updatedComments),
    );

    try {
      await ref.read(commentRepositoryProvider).toggleLike(
            questionNumber: arg.number,
            commentId: comment.id,
            isLike: newLiked,
          );
      ref.invalidateSelf();
    } catch (e, st) {
      final message = e.toString();
      final alreadyLiked = newLiked &&
          (message.contains('CONFLICT') || message.contains('409'));
      final alreadyUnliked = !newLiked &&
          (message.contains('NOT_FOUND') || message.contains('404'));
      if (alreadyLiked || alreadyUnliked) {
        ref.invalidateSelf();
        return;
      }
      state = prev;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteComment(String commentId) async {
    final prev = state;
    if (prev.value == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(commentRepositoryProvider).deleteComment(
            questionNumber: arg.number,
            commentId: commentId,
          );
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.invalidateSelf();
    }
  }

  Future<void> postComment(String option, String body) async {
    final prev = state;
    if (prev.value == null) return;

    try {
      await ref.read(commentRepositoryProvider).postComment(
            questionNumber: arg.number,
            option: option,
            body: body,
            question: arg,
          );
      ref.invalidateSelf();
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }
}

final commentControllerProvider = AsyncNotifierProvider.family.autoDispose<
    CommentController, CommentState, DummyQuestion>(
  CommentController.new,
);
