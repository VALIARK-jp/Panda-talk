import '../../core/dummy_data.dart';
import '../comment_repository.dart';

class MockCommentRepository implements CommentRepository {
  final Map<int, List<DummyComment>> _commentsByQuestion = {
    1256: [
      const DummyComment(
        id: 'c_1256_1',
        option: '外出派',
        body: '外に出た方がちゃんと休日感ある。',
        likes: 18,
        isMine: false,
        likedByMe: true,
      ),
      const DummyComment(
        id: 'c_1256_2',
        option: '家派',
        body: '予定がない日に家で回復するのが最高。',
        likes: 12,
        isMine: true,
      ),
      const DummyComment(
        id: 'c_1256_3',
        option: '外出派',
        body: '散歩だけでも気分が変わる。',
        likes: 7,
        isMine: false,
      ),
    ],
  };

  @override
  Future<List<DummyComment>> getComments(DummyQuestion question) async {
    return List.unmodifiable(
      _commentsByQuestion[question.number] ?? _fallbackComments(question),
    );
  }

  @override
  Future<void> toggleLike({required int questionNumber, required String commentId, required bool isLike}) async {
    final comments = _commentsByQuestion[questionNumber];
    if (comments == null) return;
    final index = comments.indexWhere((comment) => comment.id == commentId);
    if (index == -1) return;
    final comment = comments[index];
    comments[index] = comment.copyWith(
      likedByMe: isLike,
      likes: comment.likes + (isLike ? 1 : -1),
    );
  }

  @override
  Future<void> deleteComment({required int questionNumber, required String commentId}) async {
    _commentsByQuestion[questionNumber]?.removeWhere(
      (comment) => comment.id == commentId && comment.isMine,
    );
  }

  @override
  Future<void> postComment({required int questionNumber, required String option, required String body, String? apiQuestionId, DummyQuestion? question}) async {
    final comments = _commentsByQuestion.putIfAbsent(questionNumber, () => []);
    comments.insert(
      0,
      DummyComment(
        id: 'c_${questionNumber}_${DateTime.now().millisecondsSinceEpoch}',
        option: option,
        body: body,
        likes: 0,
        isMine: true,
      ),
    );
  }

  List<DummyComment> _fallbackComments(DummyQuestion question) {
    final comments = [
      DummyComment(
        id: 'c_${question.number}_1',
        option: question.optionA,
        body: '${question.optionA}の方が自分らしい。',
        likes: 8,
        isMine: false,
      ),
      DummyComment(
        id: 'c_${question.number}_2',
        option: question.optionB,
        body: '${question.optionB}もわかるけど今日はこっち。',
        likes: 5,
        isMine: true,
      ),
    ];
    _commentsByQuestion[question.number] = comments;
    return comments;
  }
}
