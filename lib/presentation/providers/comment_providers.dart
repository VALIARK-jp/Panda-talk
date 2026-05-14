import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> toggleLike(String commentId, bool currentIsLiked) async {
    final prev = state;
    if (prev.value == null) return;
    
    // Optimsitic UI update could be done here, but we will rely on refresh for now to ensure consistency, 
    // or just await and refresh. Let's do simple await and refresh.
    state = const AsyncValue.loading();
    try {
      await ref.read(commentRepositoryProvider).toggleLike(
            questionNumber: arg.number,
            commentId: commentId,
            isLike: !currentIsLiked,
          );
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Fallback
      ref.invalidateSelf();
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
    
    state = const AsyncValue.loading();
    try {
      await ref.read(commentRepositoryProvider).postComment(
            questionNumber: arg.number,
            option: option,
            body: body,
            question: arg,
          );
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.invalidateSelf();
    }
  }
}

final commentControllerProvider = AsyncNotifierProvider.family.autoDispose<
    CommentController, CommentState, DummyQuestion>(
  CommentController.new,
);
