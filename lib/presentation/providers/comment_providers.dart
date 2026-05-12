import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

class CommentState {
  final DummyQuestion question;
  final List<DummyComment> comments;

  const CommentState({required this.question, required this.comments});
}

class CommentController extends StateNotifier<CommentState> {
  CommentController(this._ref, DummyQuestion question)
    : super(CommentState(question: question, comments: const [])) {
    _refresh();
  }

  final Ref _ref;

  void toggleLike(String commentId) {
    _ref
        .read(commentRepositoryProvider)
        .toggleLike(state.question.number, commentId);
    _refresh();
  }

  void deleteComment(String commentId) {
    _ref
        .read(commentRepositoryProvider)
        .deleteComment(state.question.number, commentId);
    _refresh();
  }

  void postComment(String option, String body) {
    _ref
        .read(commentRepositoryProvider)
        .postComment(state.question.number, option, body);
    _refresh();
  }

  void _refresh() {
    state = CommentState(
      question: state.question,
      comments: _ref
          .read(commentRepositoryProvider)
          .getComments(state.question),
    );
  }
}

final commentControllerProvider =
    StateNotifierProvider.family<
      CommentController,
      CommentState,
      DummyQuestion
    >((ref, question) {
      return CommentController(ref, question);
    });
