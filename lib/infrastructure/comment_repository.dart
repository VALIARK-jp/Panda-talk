import '../core/dummy_data.dart';

abstract class CommentRepository {
  Future<List<DummyComment>> getComments(DummyQuestion question);
  Future<void> toggleLike({required int questionNumber, required String commentId, required bool isLike});
  Future<void> deleteComment({required int questionNumber, required String commentId});
  Future<void> postComment({required int questionNumber, required String option, required String body, String? apiQuestionId, DummyQuestion? question});
}
