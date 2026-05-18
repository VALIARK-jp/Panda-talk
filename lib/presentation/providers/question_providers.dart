import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../infrastructure/question_progress_store.dart';
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

  Map<String, dynamic> toJson() => {
    'questionIndex': questionIndex,
    'answeredCount': answeredCount,
    'minorityCount': minorityCount,
    'selectedOptionsByQuestion': selectedOptionsByQuestion.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'percentAByQuestion': percentAByQuestion.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'likedQuestionNumbers': likedQuestionNumbers.map((n) => n.toString()).toList(),
  };

  static QuestionFeedState fromJson(Map<String, dynamic> json) {
    final selectedRaw =
        json['selectedOptionsByQuestion'] as Map<String, dynamic>? ?? {};
    final percentRaw =
        json['percentAByQuestion'] as Map<String, dynamic>? ?? {};
    final likedRaw = json['likedQuestionNumbers'] as List<dynamic>? ?? [];

    return QuestionFeedState(
      questionIndex: json['questionIndex'] as int? ?? 0,
      answeredCount: json['answeredCount'] as int? ?? 0,
      minorityCount: json['minorityCount'] as int? ?? 0,
      selectedOptionsByQuestion: {
        for (final e in selectedRaw.entries)
          int.parse(e.key): e.value as String,
      },
      percentAByQuestion: {
        for (final e in percentRaw.entries) int.parse(e.key): e.value as int,
      },
      likedQuestionNumbers: likedRaw.map((e) => int.parse(e as String)).toSet(),
    );
  }
}

class QuestionFeedController extends StateNotifier<QuestionFeedState> {
  QuestionFeedController(this._ref) : super(const QuestionFeedState()) {
    _restoreProgress();
  }

  final Ref _ref;

  Future<void> _restoreProgress() async {
    final saved = await QuestionProgressStore.load();
    if (saved != null) {
      state = QuestionFeedState.fromJson(saved);
    }
  }

  void _persistProgress() {
    QuestionProgressStore.save(state.toJson());
  }

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
    _persistProgress();
  }

  void nextQuestion(int total) {
    state = state.copyWith(questionIndex: (state.questionIndex + 1) % total);
    _persistProgress();
  }

  void previousQuestion(int total) {
    state = state.copyWith(
      questionIndex: (state.questionIndex - 1 + total) % total,
    );
    _persistProgress();
  }

  void setQuestionIndex(int index) {
    state = state.copyWith(questionIndex: index);
    _persistProgress();
  }

  void resetForTab() {
    state = state.copyWith(questionIndex: 0);
    _persistProgress();
  }

  void toggleQuestionLike(int questionNumber) {
    final liked = {...state.likedQuestionNumbers};
    if (liked.contains(questionNumber)) {
      liked.remove(questionNumber);
    } else {
      liked.add(questionNumber);
    }
    state = state.copyWith(likedQuestionNumbers: liked);
    _persistProgress();
  }
}

final questionFeedControllerProvider =
    StateNotifierProvider<QuestionFeedController, QuestionFeedState>((ref) {
      return QuestionFeedController(ref);
    });
