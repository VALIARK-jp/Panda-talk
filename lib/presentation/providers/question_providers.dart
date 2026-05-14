import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../core/dummy_data.dart';

final currentQuestionProvider = FutureProvider<DummyQuestion>((ref) {
  return ref.watch(questionRepositoryProvider).getCurrentQuestion();
});

final feedQuestionsProvider = FutureProvider<List<DummyQuestion>>((ref) {
  return ref.watch(questionRepositoryProvider).getFeedQuestions();
});

final questionHistoryProvider = FutureProvider<List<DummyQuestion>>((ref) {
  return ref.watch(questionRepositoryProvider).getHistory();
});

final questionSearchProvider =
    FutureProvider.family<List<DummyQuestion>, String>((ref, keyword) {
      return ref.watch(questionRepositoryProvider).search(keyword);
    });

class QuestionFeedState {
  final int questionIndex;
  final int answeredCount;
  final int minorityCount;
  final Map<int, String> selectedOptionsByQuestion;
  final Map<int, int> percentAByQuestion;
  final Set<int> likedQuestionNumbers;

  const QuestionFeedState({
    this.questionIndex = 0,
    this.answeredCount = 0,
    this.minorityCount = 0,
    this.selectedOptionsByQuestion = const {},
    this.percentAByQuestion = const {},
    this.likedQuestionNumbers = const {},
  });

  String? selectedOptionFor(int questionNumber) {
    return selectedOptionsByQuestion[questionNumber];
  }

  int percentAFor(DummyQuestion question) {
    return percentAByQuestion[question.number] ?? question.percentA;
  }

  QuestionFeedState copyWith({
    int? questionIndex,
    int? answeredCount,
    int? minorityCount,
    Map<int, String>? selectedOptionsByQuestion,
    Map<int, int>? percentAByQuestion,
    Set<int>? likedQuestionNumbers,
  }) {
    return QuestionFeedState(
      questionIndex: questionIndex ?? this.questionIndex,
      answeredCount: answeredCount ?? this.answeredCount,
      minorityCount: minorityCount ?? this.minorityCount,
      selectedOptionsByQuestion:
          selectedOptionsByQuestion ?? this.selectedOptionsByQuestion,
      percentAByQuestion: percentAByQuestion ?? this.percentAByQuestion,
      likedQuestionNumbers: likedQuestionNumbers ?? this.likedQuestionNumbers,
    );
  }
}

class QuestionFeedController extends StateNotifier<QuestionFeedState> {
  QuestionFeedController(this._ref) : super(const QuestionFeedState());

  final Ref _ref;

  Future<void> answer(DummyQuestion question, String selected) async {
    if (state.selectedOptionsByQuestion.containsKey(question.number)) return;

    final percentA = await _ref
        .read(questionRepositoryProvider)
        .answerQuestion(question: question, selectedOption: selected);
    final selectedA = selected == question.optionA;
    final selectedPercent = selectedA ? percentA : (100 - percentA);
    final isMinority = selectedPercent < 50;

    final selectedOptions = {...state.selectedOptionsByQuestion};
    selectedOptions[question.number] = selected;
    final percentAByQuestion = {...state.percentAByQuestion};
    percentAByQuestion[question.number] = percentA;

    state = state.copyWith(
      selectedOptionsByQuestion: selectedOptions,
      percentAByQuestion: percentAByQuestion,
      answeredCount: state.answeredCount + 1,
      minorityCount: state.minorityCount + (isMinority ? 1 : 0),
    );
  }

  void nextQuestion(int total) {
    state = state.copyWith(questionIndex: (state.questionIndex + 1) % total);
  }

  void previousQuestion(int total) {
    state = state.copyWith(
      questionIndex: (state.questionIndex - 1 + total) % total,
    );
  }

  void setQuestionIndex(int index) {
    state = state.copyWith(questionIndex: index);
  }

  void resetForTab() {
    state = state.copyWith(questionIndex: 0);
  }

  void toggleQuestionLike(int questionNumber) {
    final liked = {...state.likedQuestionNumbers};
    if (liked.contains(questionNumber)) {
      liked.remove(questionNumber);
    } else {
      liked.add(questionNumber);
    }
    state = state.copyWith(likedQuestionNumbers: liked);
  }
}

final questionFeedControllerProvider =
    StateNotifierProvider<QuestionFeedController, QuestionFeedState>((ref) {
      return QuestionFeedController(ref);
    });
