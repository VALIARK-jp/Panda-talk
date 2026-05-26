import '../core/dummy_data.dart';
import '../core/oddball_score.dart';

abstract class QuestionRepository {
  Future<List<DummyQuestion>> getDiagnosis16Questions();

  /// 未回答フィード（[cursor] は直前ページ末尾の質問 id）。
  Future<List<DummyQuestion>> getFeedQuestions({
    int limit = 200,
    String? cursor,
  });

  /// 最小の未回答番号をフロンティアに、前後 [before]/[after] 問をまとめて取得。
  /// [maxQuestionNumber] 指定時は 16type 診断レンジ（Q1–16）に限定。
  Future<List<DummyQuestion>> getFeedWindow({
    int before = 10,
    int after = 10,
    int? maxQuestionNumber,
  });

  /// 指定した質問の前後（履歴タップ・過去へのジャンプ用）。
  Future<List<DummyQuestion>> getFeedWindowAround({
    int before = 15,
    int after = 15,
    int? questionNumber,
    String? questionId,
    int? currentQuestionNumber,
  });
  Future<DummyQuestion> getCurrentQuestion();
  /// [limit] / [cursor] はバックエンドの `/questions/history` にそのまま渡す。
  Future<List<DummyQuestion>> getHistory({int limit = 20, String? cursor});
  Future<List<DummyQuestion>> search(String keyword);
  Future<List<DummyQuestion>> getMyQuestions();

  Future<void> postQuestion({
    required String text,
    required String optionA,
    required String optionB,
    required String category,
  });

  Future<void> editQuestion({
    required int number,
    required String text,
    required String optionA,
    required String optionB,
    required String category,
  });

  Future<void> deleteQuestion(int number);

  Future<QuestionVoteStats> answerQuestion({
    required DummyQuestion question,
    required String selectedOption,
  });

  /// 質問ごとの最新集計（A 側の割合 0–100）。
  Future<int> fetchQuestionPercentA(String questionId);

  Future<void> toggleQuestionLike({
    required String questionId,
    required bool isLike,
  });
}
