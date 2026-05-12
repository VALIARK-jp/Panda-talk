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
  final Set<int> likedQuestionNumbers;

  const QuestionFeedState({
    this.questionIndex = 0,
    this.answeredCount = 0,
    this.minorityCount = 0,
    this.selectedOptionsByQuestion = const {},
    this.likedQuestionNumbers = const {},
  });

  String? selectedOptionFor(int questionNumber) {
    return selectedOptionsByQuestion[questionNumber];
  }

  QuestionFeedState copyWith({
    int? questionIndex,
    int? answeredCount,
    int? minorityCount,
    Map<int, String>? selectedOptionsByQuestion,
    Set<int>? likedQuestionNumbers,
  }) {
    return QuestionFeedState(
      questionIndex: questionIndex ?? this.questionIndex,
      answeredCount: answeredCount ?? this.answeredCount,
      minorityCount: minorityCount ?? this.minorityCount,
      selectedOptionsByQuestion:
          selectedOptionsByQuestion ?? this.selectedOptionsByQuestion,
      likedQuestionNumbers: likedQuestionNumbers ?? this.likedQuestionNumbers,
    );
  }
}

class QuestionFeedController extends StateNotifier<QuestionFeedState> {
  QuestionFeedController() : super(const QuestionFeedState());

  void answer(DummyQuestion question, String selected) {
    if (state.selectedOptionsByQuestion.containsKey(question.number)) return;

    final selectedA = selected == question.optionA;
    final selectedPercent = selectedA
        ? question.percentA
        : (100 - question.percentA);
    final isMinority = selectedPercent < 50;

    final selectedOptions = {...state.selectedOptionsByQuestion};
    selectedOptions[question.number] = selected;

    state = state.copyWith(
      selectedOptionsByQuestion: selectedOptions,
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
      return QuestionFeedController();
    });
