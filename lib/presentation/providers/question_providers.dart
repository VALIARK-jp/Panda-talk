import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../infrastructure/providers/repositories.dart';
import '../../infrastructure/question_progress_store.dart';
import '../../core/dummy_data.dart';
import '../../core/question_stats_utils.dart';
import 'profile_providers.dart';

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
  final Map<int, int> likeCountByQuestion;
  final Map<int, int> commentCountByQuestion;
  final Set<int> likedQuestionNumbers;

  const QuestionFeedState({
    this.questionIndex = 0,
    this.answeredCount = 0,
    this.minorityCount = 0,
    this.selectedOptionsByQuestion = const {},
    this.percentAByQuestion = const {},
    this.likeCountByQuestion = const {},
    this.commentCountByQuestion = const {},
    this.likedQuestionNumbers = const {},
  });

  int likeCountFor(DummyQuestion question) {
    return likeCountByQuestion[question.number] ?? question.likeCount;
  }

  int commentCountFor(DummyQuestion question) {
    return commentCountByQuestion[question.number] ?? question.commentCount;
  }

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
    Map<int, int>? likeCountByQuestion,
    Map<int, int>? commentCountByQuestion,
    Set<int>? likedQuestionNumbers,
  }) {
    return QuestionFeedState(
      questionIndex: questionIndex ?? this.questionIndex,
      answeredCount: answeredCount ?? this.answeredCount,
      minorityCount: minorityCount ?? this.minorityCount,
      selectedOptionsByQuestion:
          selectedOptionsByQuestion ?? this.selectedOptionsByQuestion,
      percentAByQuestion: percentAByQuestion ?? this.percentAByQuestion,
      likeCountByQuestion: likeCountByQuestion ?? this.likeCountByQuestion,
      commentCountByQuestion:
          commentCountByQuestion ?? this.commentCountByQuestion,
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
    'likeCountByQuestion': likeCountByQuestion.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'commentCountByQuestion': commentCountByQuestion.map(
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
    final likeCountRaw =
        json['likeCountByQuestion'] as Map<String, dynamic>? ?? {};
    final commentCountRaw =
        json['commentCountByQuestion'] as Map<String, dynamic>? ?? {};

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
      likeCountByQuestion: {
        for (final e in likeCountRaw.entries)
          int.parse(e.key): e.value as int,
      },
      commentCountByQuestion: {
        for (final e in commentCountRaw.entries)
          int.parse(e.key): e.value as int,
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
  final Set<int> _answerInFlight = {};

  Future<void> _restoreProgress() async {
    final saved = await _loadProgressForCurrentSession();
    if (saved != null) {
      state = QuestionFeedState.fromJson(saved);
    }
  }

  Future<Map<String, dynamic>?> _loadProgressForCurrentSession() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      return QuestionProgressStore.loadForUser(userId);
    }
    return QuestionProgressStore.loadGuest();
  }

  void _persistProgress() {
    final json = state.toJson();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      QuestionProgressStore.saveForUser(userId, json);
    } else {
      QuestionProgressStore.saveGuest(json);
    }
  }

  Future<void> answer(DummyQuestion question, String selected) async {
    if (state.selectedOptionsByQuestion.containsKey(question.number)) return;
    if (!_answerInFlight.add(question.number)) return;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null || question.apiId == null) {
        if (kDebugMode) {
          debugPrint(
            'QuestionFeed: answer local-only (guest or missing apiId) '
            'Q${question.number}',
          );
        }
        _applyAnswerLocally(
          question,
          selected,
          question.percentA,
          countAsNew: true,
        );
        return;
      }

      final percentA = await _ref
          .read(questionRepositoryProvider)
          .answerQuestion(question: question, selectedOption: selected);
      _applyAnswerLocally(question, selected, percentA, countAsNew: true);
      _ref.invalidate(profileControllerProvider);
      _ref.invalidate(feedQuestionsProvider);
    } finally {
      _answerInFlight.remove(question.number);
    }
  }

  /// いいね数・コメント数を API の値で揃える。
  void syncEngagementFromQuestions(List<DummyQuestion> questions) {
    if (questions.isEmpty) return;
    final likeCounts = Map<int, int>.from(state.likeCountByQuestion);
    final commentCounts = Map<int, int>.from(state.commentCountByQuestion);
    var changed = false;

    for (final q in questions) {
      if (likeCounts[q.number] != q.likeCount) {
        likeCounts[q.number] = q.likeCount;
        changed = true;
      }
      if (commentCounts[q.number] != q.commentCount) {
        commentCounts[q.number] = q.commentCount;
        changed = true;
      }
    }

    if (!changed) return;
    state = state.copyWith(
      likeCountByQuestion: likeCounts,
      commentCountByQuestion: commentCounts,
    );
    _persistProgress();
  }

  /// API が返す `myAnswer` と端末キャッシュを揃える（再ログイン・ホットリスタート後）。
  void syncAnsweredFromServer(List<DummyQuestion> questions) {
    var changed = false;
    var selectedOptions = Map<int, String>.from(state.selectedOptionsByQuestion);
    var percentAByQuestion = Map<int, int>.from(state.percentAByQuestion);
    var answeredCount = state.answeredCount;

    for (final q in questions) {
      final existing = q.myAnswer;
      if (existing == null) continue;

      if (!selectedOptions.containsKey(q.number)) {
        selectedOptions[q.number] = existing;
        answeredCount += 1;
        changed = true;
      }
      if (percentAByQuestion[q.number] != q.percentA) {
        percentAByQuestion[q.number] = q.percentA;
        changed = true;
      }
    }

    if (changed) {
      final byNumber = {for (final q in questions) q.number: q};
      state = state.copyWith(
        selectedOptionsByQuestion: selectedOptions,
        percentAByQuestion: percentAByQuestion,
        answeredCount: answeredCount,
        minorityCount: _countMinority(selectedOptions, percentAByQuestion, byNumber),
      );
      _persistProgress();
    }
    syncEngagementFromQuestions(questions);
  }

  /// 履歴 API などで取った `percentA` を端末に反映し、少数派数を再計算する。
  void applyServerStats(List<DummyQuestion> questions) {
    if (questions.isEmpty) return;
    final selectedOptions = Map<int, String>.from(state.selectedOptionsByQuestion);
    final percentAByQuestion = Map<int, int>.from(state.percentAByQuestion);
    final byNumber = {for (final q in questions) q.number: q};
    var changed = false;

    for (final q in questions) {
      final selected = selectedOptions[q.number] ?? q.myAnswer;
      if (selected == null) continue;
      if (!selectedOptions.containsKey(q.number)) {
        selectedOptions[q.number] = selected;
        changed = true;
      }
      if (percentAByQuestion[q.number] != q.percentA) {
        percentAByQuestion[q.number] = q.percentA;
        changed = true;
      }
    }

    if (!changed) return;

    state = state.copyWith(
      selectedOptionsByQuestion: selectedOptions,
      percentAByQuestion: percentAByQuestion,
      minorityCount: _countMinority(selectedOptions, percentAByQuestion, byNumber),
    );
    _persistProgress();
  }

  /// 回答済み質問の最新集計を取得し、バー・多数派/少数派・異端児スコアを更新する。
  Future<void> refreshAnsweredStats(List<DummyQuestion> visibleQuestions) async {
    final selectedOptions = state.selectedOptionsByQuestion;
    final hasAnsweredInFeed = visibleQuestions.any(
      (q) => selectedOptions.containsKey(q.number) || q.myAnswer != null,
    );
    if (selectedOptions.isEmpty && !hasAnsweredInFeed) return;

    final repo = _ref.read(questionRepositoryProvider);
    final byNumber = {for (final q in visibleQuestions) q.number: q};

    if (Supabase.instance.client.auth.currentSession != null) {
      try {
        final history = await repo.getHistory();
        for (final q in history) {
          byNumber[q.number] = q;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('refreshAnsweredStats: history load failed: $e');
        }
      }
    }

    final numbersToRefresh = <int>{
      ...selectedOptions.keys,
      for (final q in visibleQuestions)
        if (selectedOptions.containsKey(q.number) || q.myAnswer != null) q.number,
    };

    var percentAByQuestion = Map<int, int>.from(state.percentAByQuestion);
    var changed = false;

    for (final number in numbersToRefresh) {
      final q = byNumber[number];
      if (q?.apiId == null) continue;
      try {
        final percentA = await repo.fetchQuestionPercentA(q!.apiId!);
        if (percentAByQuestion[number] != percentA) {
          percentAByQuestion[number] = percentA;
          changed = true;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('refreshAnsweredStats: Q$number failed: $e');
        }
      }
    }

    if (!changed) return;

    state = state.copyWith(
      percentAByQuestion: percentAByQuestion,
      minorityCount: _countMinority(selectedOptions, percentAByQuestion, byNumber),
    );
    _persistProgress();
  }

  int _countMinority(
    Map<int, String> selectedOptions,
    Map<int, int> percentAByQuestion,
    Map<int, DummyQuestion> byNumber,
  ) {
    var count = 0;
    for (final entry in selectedOptions.entries) {
      final q = byNumber[entry.key];
      if (q == null) continue;
      final percentA = percentAByQuestion[entry.key] ?? q.percentA;
      if (isMinorityAnswer(
        selected: entry.value,
        question: q,
        percentA: percentA,
      )) {
        count++;
      }
    }
    return count;
  }

  void _applyAnswerLocally(
    DummyQuestion question,
    String selected,
    int percentA, {
    required bool countAsNew,
  }) {
    final selectedOptions = Map<int, String>.from(state.selectedOptionsByQuestion);
    final percentAByQuestion = Map<int, int>.from(state.percentAByQuestion);
    final alreadyAnswered = selectedOptions.containsKey(question.number);
    final oldPercentA = percentAByQuestion[question.number] ?? question.percentA;
    final oldSelected = selectedOptions[question.number] ?? selected;

    var minorityCount = state.minorityCount;
    if (alreadyAnswered) {
      final wasMinority = isMinorityAnswer(
        selected: oldSelected,
        question: question,
        percentA: oldPercentA,
      );
      final nowMinority = isMinorityAnswer(
        selected: selected,
        question: question,
        percentA: percentA,
      );
      if (wasMinority && !nowMinority) minorityCount--;
      if (!wasMinority && nowMinority) minorityCount++;
    } else if (countAsNew &&
        isMinorityAnswer(selected: selected, question: question, percentA: percentA)) {
      minorityCount++;
    }

    selectedOptions[question.number] = selected;
    percentAByQuestion[question.number] = percentA;

    state = state.copyWith(
      selectedOptionsByQuestion: selectedOptions,
      percentAByQuestion: percentAByQuestion,
      answeredCount: countAsNew && !alreadyAnswered
          ? state.answeredCount + 1
          : state.answeredCount,
      minorityCount: minorityCount,
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

  void toggleQuestionLike(DummyQuestion question) {
    final number = question.number;
    final liked = {...state.likedQuestionNumbers};
    var likes = state.likeCountFor(question);
    if (liked.contains(number)) {
      liked.remove(number);
      likes = likes > 0 ? likes - 1 : 0;
    } else {
      liked.add(number);
      likes++;
    }
    final likeCounts = Map<int, int>.from(state.likeCountByQuestion);
    likeCounts[number] = likes;
    state = state.copyWith(
      likedQuestionNumbers: liked,
      likeCountByQuestion: likeCounts,
    );
    _persistProgress();
  }

  void incrementCommentCount(DummyQuestion question) {
    final counts = Map<int, int>.from(state.commentCountByQuestion);
    counts[question.number] = state.commentCountFor(question) + 1;
    state = state.copyWith(commentCountByQuestion: counts);
    _persistProgress();
  }
}

final questionFeedControllerProvider =
    StateNotifierProvider<QuestionFeedController, QuestionFeedState>((ref) {
      return QuestionFeedController(ref);
    });
