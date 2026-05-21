import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';
import 'question_providers.dart';

class QuestionPostController extends StateNotifier<List<DummyQuestion>> {
  QuestionPostController(this._ref) : super(const []) {
    reload();
  }

  final Ref _ref;

  Future<void> reload() async {
    state = await _ref.read(questionRepositoryProvider).getMyQuestions();
  }

  Future<void> postQuestion({
    required String text,
    required String optionA,
    required String optionB,
    required String category,
  }) async {
    await _ref
        .read(questionRepositoryProvider)
        .postQuestion(
          text: text,
          optionA: optionA,
          optionB: optionB,
          category: category,
        );
    await reload();
    _ref.invalidate(feedQuestionsProvider);
    _ref.invalidate(questionHistoryProvider);
  }

  Future<void> editQuestion({
    required int number,
    required String text,
    required String optionA,
    required String optionB,
    required String category,
  }) async {
    await _ref
        .read(questionRepositoryProvider)
        .editQuestion(
          number: number,
          text: text,
          optionA: optionA,
          optionB: optionB,
          category: category,
        );
    await reload();
    _ref.invalidate(feedQuestionsProvider);
    _ref.invalidate(questionHistoryProvider);
  }

  Future<void> deleteQuestion(int number) async {
    await _ref.read(questionRepositoryProvider).deleteQuestion(number);
    await reload();
    _ref.invalidate(feedQuestionsProvider);
    _ref.invalidate(questionHistoryProvider);
  }
}

final questionPostControllerProvider =
    StateNotifierProvider<QuestionPostController, List<DummyQuestion>>((ref) {
      return QuestionPostController(ref);
    });
