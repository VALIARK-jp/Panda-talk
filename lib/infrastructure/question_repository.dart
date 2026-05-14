import '../core/dummy_data.dart';

abstract class QuestionRepository {
  Future<List<DummyQuestion>> getFeedQuestions();
  Future<DummyQuestion> getCurrentQuestion();
  Future<List<DummyQuestion>> getHistory();
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

  Future<int> answerQuestion({
    required DummyQuestion question,
    required String selectedOption,
  });
}
