import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../infrastructure/diagnosis_16_store.dart';
import '../session_reset.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../infrastructure/question_progress_store.dart';
import '../../infrastructure/question_repository.dart';
import '../../core/dummy_data.dart';
import '../../core/oddball_score.dart';
import 'feed_window_controller.dart';
import 'profile_providers.dart';

export 'feed_window_controller.dart';

const kDiagnosisQuestionCount = 16;

/// 未回答フィードを cursor で最後まで取得する（ゲスト等のフォールバック）。
Future<List<DummyQuestion>> loadAllUnansweredFeed(
  QuestionRepository repo, {
  int pageSize = 50,
}) async {
  final all = <DummyQuestion>[];
  String? cursor;
  for (var page = 0; page < 40; page++) {
    final chunk = await repo.getFeedQuestions(limit: pageSize, cursor: cursor);
    if (chunk.isEmpty) break;
    all.addAll(chunk);
    if (chunk.length < pageSize) break;
    final lastId = chunk.last.apiId;
    if (lastId == null) break;
    cursor = lastId;
  }
  return all;
}

/// 回答済み履歴を API から取得する（最大 [maxPages] ページまで）。
Future<List<DummyQuestion>> loadAnsweredHistory(
  QuestionRepository repo, {
  int pageSize = 50,
  int maxPages = 4,
}) async {
  final all = <DummyQuestion>[];
  String? cursor;
  for (var page = 0; page < maxPages; page++) {
    final chunk = await repo.getHistory(limit: pageSize, cursor: cursor);
    if (chunk.isEmpty) break;
    all.addAll(chunk);
    if (chunk.length < pageSize) break;
    final lastId = chunk.last.apiId;
    if (lastId == null) break;
    cursor = lastId;
  }
  return all;
}

@Deprecated('Use loadAnsweredHistory with maxPages')
Future<List<DummyQuestion>> loadAllAnsweredHistory(QuestionRepository repo) =>
    loadAnsweredHistory(repo, pageSize: 200, maxPages: 20);

bool isDiagnosisQuestionNumber(int number) =>
    number >= 1 && number <= kDiagnosisQuestionCount;

bool isDiagnosis16QuestionList(List<DummyQuestion> questions) {
  if (questions.isEmpty) return false;
  return questions.every((q) => isDiagnosisQuestionNumber(q.number));
}

/// サーバーに既に保存済みの質問 ID（診断16用は diagnosis16 API の myAnswer から）。
Future<Set<String>> loadAnsweredQuestionIdsOnServer(
  QuestionRepository repo, {
  Set<String>? onlyQuestionIds,
}) async {
  if (Supabase.instance.client.auth.currentSession == null) {
    return const {};
  }
  if (onlyQuestionIds != null && onlyQuestionIds.isNotEmpty) {
    try {
      final diagnosis = await repo.getFeedWindow(
        before: 0,
        after: 0,
        maxQuestionNumber: kDiagnosisQuestionCount,
      );
      return diagnosis
          .where((q) => q.myAnswer != null && q.apiId != null)
          .map((q) => q.apiId!)
          .where(onlyQuestionIds.contains)
          .toSet();
    } catch (_) {
      return const {};
    }
  }
  try {
    final history = await loadAnsweredHistory(repo, maxPages: 2);
    return history.map((q) => q.apiId).whereType<String>().toSet();
  } catch (_) {
    return const {};
  }
}

final currentQuestionProvider = FutureProvider<DummyQuestion>((ref) {
  return ref.watch(questionRepositoryProvider).getCurrentQuestion();
});

bool hasCompletedDiagnosisQuestions(List<DummyQuestion> questions) {
  final answeredNumbers = <int>{};
  for (final q in questions) {
    if (!isDiagnosisQuestionNumber(q.number)) continue;
    if (q.myAnswer != null) answeredNumbers.add(q.number);
  }
  for (var n = 1; n <= kDiagnosisQuestionCount; n++) {
    if (!answeredNumbers.contains(n)) return false;
  }
  return true;
}

final questionHistoryProvider = FutureProvider<List<DummyQuestion>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(questionRepositoryProvider);
  if (Supabase.instance.client.auth.currentSession == null) {
    return repo.getHistory(limit: 50);
  }
  return loadAnsweredHistory(repo, pageSize: 50, maxPages: 4);
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
  /// 選択が A 側か（表示窓外の回答でも少数派数を再計算するため保持）。
  final Map<int, bool> selectedSideAByQuestion;
  final Map<int, int> percentAByQuestion;
  final Map<int, int> countAByQuestion;
  final Map<int, int> countBByQuestion;
  final Map<int, int> likeCountByQuestion;
  final Map<int, int> commentCountByQuestion;
  final Set<int> likedQuestionNumbers;

  const QuestionFeedState({
    this.questionIndex = 0,
    this.answeredCount = 0,
    this.minorityCount = 0,
    this.selectedOptionsByQuestion = const {},
    this.selectedSideAByQuestion = const {},
    this.percentAByQuestion = const {},
    this.countAByQuestion = const {},
    this.countBByQuestion = const {},
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

  int countAFor(DummyQuestion question) {
    return countAByQuestion[question.number] ?? question.countA;
  }

  int countBFor(DummyQuestion question) {
    return countBByQuestion[question.number] ?? question.countB;
  }

  QuestionFeedState copyWith({
    int? questionIndex,
    int? answeredCount,
    int? minorityCount,
    Map<int, String>? selectedOptionsByQuestion,
    Map<int, bool>? selectedSideAByQuestion,
    Map<int, int>? percentAByQuestion,
    Map<int, int>? countAByQuestion,
    Map<int, int>? countBByQuestion,
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
      selectedSideAByQuestion:
          selectedSideAByQuestion ?? this.selectedSideAByQuestion,
      percentAByQuestion: percentAByQuestion ?? this.percentAByQuestion,
      countAByQuestion: countAByQuestion ?? this.countAByQuestion,
      countBByQuestion: countBByQuestion ?? this.countBByQuestion,
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
    'selectedSideAByQuestion': selectedSideAByQuestion.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'percentAByQuestion': percentAByQuestion.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'countAByQuestion': countAByQuestion.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'countBByQuestion': countBByQuestion.map(
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
    final sideRaw =
        json['selectedSideAByQuestion'] as Map<String, dynamic>? ?? {};
    final percentRaw =
        json['percentAByQuestion'] as Map<String, dynamic>? ?? {};
    final countARaw = json['countAByQuestion'] as Map<String, dynamic>? ?? {};
    final countBRaw = json['countBByQuestion'] as Map<String, dynamic>? ?? {};
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
      selectedSideAByQuestion: {
        for (final e in sideRaw.entries)
          int.parse(e.key): e.value as bool,
      },
      percentAByQuestion: {
        for (final e in percentRaw.entries) int.parse(e.key): e.value as int,
      },
      countAByQuestion: {
        for (final e in countARaw.entries) int.parse(e.key): e.value as int,
      },
      countBByQuestion: {
        for (final e in countBRaw.entries) int.parse(e.key): e.value as int,
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
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final saved = await _loadProgressForCurrentSession();
    var next = saved != null
        ? QuestionFeedState.fromJson(saved)
        : const QuestionFeedState();

    if (userId != null) {
      // ログイン中の回答は DB 同期が正。端末に残った 1–16 のゴーストで全問回答済みに見えるのを防ぐ。
      next = next.copyWith(
        selectedOptionsByQuestion: const {},
        selectedSideAByQuestion: const {},
        percentAByQuestion: const {},
        countAByQuestion: const {},
        countBByQuestion: const {},
        answeredCount: 0,
        minorityCount: 0,
        questionIndex: 0,
      );
    } else {
      final guestDiag = await Diagnosis16Store.loadAnswers();
      if (guestDiag.isNotEmpty) {
        try {
          final qs = await _ref.read(questionRepositoryProvider).getFeedWindow(
            before: 0,
            after: 0,
            maxQuestionNumber: kDiagnosisQuestionCount,
          );
          final byNum = {for (final q in qs) q.number: q};
          final selected =
              Map<int, String>.from(next.selectedOptionsByQuestion);
          final sideA = Map<int, bool>.from(next.selectedSideAByQuestion);
          final percentA = Map<int, int>.from(next.percentAByQuestion);
          final countA = Map<int, int>.from(next.countAByQuestion);
          final countB = Map<int, int>.from(next.countBByQuestion);
          for (final entry in guestDiag.entries) {
            final q = byNum[entry.key];
            if (q == null) continue;
            selected[entry.key] = entry.value ? q.optionA : q.optionB;
            sideA[entry.key] = entry.value;
            percentA[entry.key] = q.percentA;
            countA[entry.key] = q.countA;
            countB[entry.key] = q.countB;
          }
          next = next.copyWith(
            selectedOptionsByQuestion: selected,
            selectedSideAByQuestion: sideA,
            percentAByQuestion: percentA,
            countAByQuestion: countA,
            countBByQuestion: countB,
            answeredCount: selected.length,
            minorityCount: countMinorityAnswers(
              selectedSideAByQuestion: sideA,
              countAByQuestion: countA,
              countBByQuestion: countB,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('_restoreProgress: guest diagnosis hydrate failed: $e');
          }
        }
      }
    }
    state = next;
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
    if (userId == null) {
      // 診断 Q1–16 は Diagnosis16Store のみ。ゲスト進捗に入れるとログイン時に一括 POST される。
      final selectedRaw =
          json['selectedOptionsByQuestion'] as Map<String, dynamic>? ?? {};
      final percentRaw =
          json['percentAByQuestion'] as Map<String, dynamic>? ?? {};
      json['selectedOptionsByQuestion'] = {
        for (final e in selectedRaw.entries)
          if (!isDiagnosisQuestionNumber(int.parse(e.key))) e.key: e.value,
      };
      json['percentAByQuestion'] = {
        for (final e in percentRaw.entries)
          if (!isDiagnosisQuestionNumber(int.parse(e.key))) e.key: e.value,
      };
      final selectedCount =
          (json['selectedOptionsByQuestion'] as Map).length;
      json['answeredCount'] = selectedCount;
    }
    if (userId != null) {
      QuestionProgressStore.saveForUser(userId, json);
    } else {
      QuestionProgressStore.saveGuest(json);
    }
  }

  QuestionVoteStats _optimisticVoteStats(
    DummyQuestion question,
    String selected,
  ) {
    final choseA = selected == question.optionA;
    final base = voteCountsForQuestion(
      percentA: question.percentA,
      countA: question.countA,
      countB: question.countB,
    );
    final after = voteCountsAfterGuestAnswer(
      choseA: choseA,
      baseCountA: base.$1,
      baseCountB: base.$2,
    );
    final total = after.$1 + after.$2;
    final percentA =
        total == 0 ? question.percentA : (after.$1 / total * 100).round();
    return QuestionVoteStats(
      percentA: percentA,
      countA: after.$1,
      countB: after.$2,
    );
  }

  Future<void> _recordAnswerInFeedWindow(
    DummyQuestion question,
    String selected,
    QuestionVoteStats stats,
  ) async {
    await _ref.read(feedWindowControllerProvider.notifier).recordAnswerLocally(
          question: question,
          selectedOption: selected,
          percentA: stats.percentA,
          countA: stats.countA,
          countB: stats.countB,
        );
  }

  Future<void> _syncAnswerToServer(
    DummyQuestion question,
    String selected,
  ) async {
    try {
      final stats = await _ref
          .read(questionRepositoryProvider)
          .answerQuestion(question: question, selectedOption: selected);
      _applyAnswerLocally(question, selected, stats, countAsNew: false);
      await _recordAnswerInFeedWindow(question, selected, stats);
      _ref.invalidate(profileControllerProvider);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QuestionFeed: answer sync failed Q${question.number}: $e $st');
      }
    }
  }

  Future<void> answer(DummyQuestion question, String selected) async {
    if (state.selectedOptionsByQuestion.containsKey(question.number)) return;
    if (!_answerInFlight.add(question.number)) return;

    try {
      final optimistic = _optimisticVoteStats(question, selected);
      _applyAnswerLocally(question, selected, optimistic, countAsNew: true);
      await _recordAnswerInFeedWindow(question, selected, optimistic);

      if (!hasValidAuthSession() || question.apiId == null) {
        if (kDebugMode) {
          debugPrint(
            'QuestionFeed: answer local-only (guest or missing apiId) '
            'Q${question.number}',
          );
        }
        return;
      }

      unawaited(_syncAnswerToServer(question, selected));
    } finally {
      _answerInFlight.remove(question.number);
    }
  }

  /// いいね数・コメント数を API の値で揃える（楽観更新中のいいね数は上書きしない）。
  void syncEngagementFromQuestions(List<DummyQuestion> questions) {
    if (questions.isEmpty) return;
    final likeCounts = Map<int, int>.from(state.likeCountByQuestion);
    final commentCounts = Map<int, int>.from(state.commentCountByQuestion);
    var changed = false;

    for (final q in questions) {
      final likedLocally = state.likedQuestionNumbers.contains(q.number);
      final targetLikes = likedLocally
          ? (likeCounts[q.number] ?? q.likeCount)
          : q.likeCount;
      if (likeCounts[q.number] != targetLikes) {
        likeCounts[q.number] = targetLikes;
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

  /// 表示中の質問（API 付き myAnswer）だけで端末状態を揃える。履歴 API は叩かない。
  Future<void> reconcileWithServer(List<DummyQuestion> visibleQuestions) async {
    if (Supabase.instance.client.auth.currentSession == null) {
      _reconcileGuestAnswersAgainstVisible(visibleQuestions);
      return;
    }

    final isDiagnosis = isDiagnosis16QuestionList(visibleQuestions);
    final selectedOptions =
        Map<int, String>.from(state.selectedOptionsByQuestion);
    final selectedSideA =
        Map<int, bool>.from(state.selectedSideAByQuestion);
    final percentAByQuestion = Map<int, int>.from(state.percentAByQuestion);
    final countAByQuestion = Map<int, int>.from(state.countAByQuestion);
    final countBByQuestion = Map<int, int>.from(state.countBByQuestion);
    var changed = false;

    for (final q in visibleQuestions) {
      if (isDiagnosis && !isDiagnosisQuestionNumber(q.number)) continue;
      final ans = q.myAnswer ?? selectedOptions[q.number];
      if (ans == null) continue;

      final sideA = q.myAnswer != null
          ? ans == q.optionA
          : (selectedSideA[q.number] ?? ans == q.optionA);
      final label = q.myAnswer ?? ans;
      final percentA = q.percentA;
      final counts = voteCountsForQuestion(
        percentA: q.percentA,
        countA: q.countA,
        countB: q.countB,
      );

      if (selectedOptions[q.number] != label) {
        selectedOptions[q.number] = label;
        changed = true;
      }
      if (selectedSideA[q.number] != sideA) {
        selectedSideA[q.number] = sideA;
        changed = true;
      }
      if (percentAByQuestion[q.number] != percentA) {
        percentAByQuestion[q.number] = percentA;
        changed = true;
      }
      if (countAByQuestion[q.number] != counts.$1) {
        countAByQuestion[q.number] = counts.$1;
        changed = true;
      }
      if (countBByQuestion[q.number] != counts.$2) {
        countBByQuestion[q.number] = counts.$2;
        changed = true;
      }
    }

    if (!changed &&
        selectedOptions.length == state.selectedOptionsByQuestion.length) {
      syncEngagementFromQuestions(visibleQuestions);
      return;
    }

    state = state.copyWith(
      selectedOptionsByQuestion: selectedOptions,
      selectedSideAByQuestion: selectedSideA,
      percentAByQuestion: percentAByQuestion,
      countAByQuestion: countAByQuestion,
      countBByQuestion: countBByQuestion,
      answeredCount: selectedOptions.length,
      minorityCount: countMinorityAnswers(
        selectedSideAByQuestion: selectedSideA,
        countAByQuestion: countAByQuestion,
        countBByQuestion: countBByQuestion,
      ),
    );
    _persistProgress();
    syncEngagementFromQuestions(visibleQuestions);
  }

  void _reconcileGuestAnswersAgainstVisible(List<DummyQuestion> visibleQuestions) {
    if (visibleQuestions.isEmpty) {
      syncEngagementFromQuestions(visibleQuestions);
      return;
    }

    var selectedOptions = Map<int, String>.from(state.selectedOptionsByQuestion);
    var selectedSideA = Map<int, bool>.from(state.selectedSideAByQuestion);
    var percentAByQuestion = Map<int, int>.from(state.percentAByQuestion);
    var countAByQuestion = Map<int, int>.from(state.countAByQuestion);
    var countBByQuestion = Map<int, int>.from(state.countBByQuestion);
    var changed = false;

    for (final q in visibleQuestions) {
      final counts = voteCountsForQuestion(
        percentA: q.percentA,
        countA: q.countA,
        countB: q.countB,
      );
      final server = q.myAnswer;
      if (server != null) {
        final sideA = server == q.optionA;
        if (selectedOptions[q.number] != server) {
          selectedOptions[q.number] = server;
          changed = true;
        }
        if (selectedSideA[q.number] != sideA) {
          selectedSideA[q.number] = sideA;
          changed = true;
        }
        if (percentAByQuestion[q.number] != q.percentA) {
          percentAByQuestion[q.number] = q.percentA;
          changed = true;
        }
        if (countAByQuestion[q.number] != counts.$1) {
          countAByQuestion[q.number] = counts.$1;
          changed = true;
        }
        if (countBByQuestion[q.number] != counts.$2) {
          countBByQuestion[q.number] = counts.$2;
          changed = true;
        }
      } else if (selectedOptions.containsKey(q.number)) {
        final sideA = selectedOptions[q.number] == q.optionA;
        if (selectedSideA[q.number] != sideA) {
          selectedSideA[q.number] = sideA;
          changed = true;
        }
        if (percentAByQuestion[q.number] != q.percentA) {
          percentAByQuestion[q.number] = q.percentA;
          changed = true;
        }
        if (countAByQuestion[q.number] != counts.$1) {
          countAByQuestion[q.number] = counts.$1;
          changed = true;
        }
        if (countBByQuestion[q.number] != counts.$2) {
          countBByQuestion[q.number] = counts.$2;
          changed = true;
        }
      }
    }

    if (changed) {
      state = state.copyWith(
        selectedOptionsByQuestion: selectedOptions,
        selectedSideAByQuestion: selectedSideA,
        percentAByQuestion: percentAByQuestion,
        countAByQuestion: countAByQuestion,
        countBByQuestion: countBByQuestion,
        answeredCount: selectedOptions.length,
        minorityCount: countMinorityAnswers(
          selectedSideAByQuestion: selectedSideA,
          countAByQuestion: countAByQuestion,
          countBByQuestion: countBByQuestion,
        ),
      );
      _persistProgress();
    }
    syncEngagementFromQuestions(visibleQuestions);
  }

  /// 履歴 API などで取った `percentA` を端末に反映し、少数派数を再計算する。
  void applyServerStats(List<DummyQuestion> questions) {
    if (questions.isEmpty) return;
    final selectedOptions = Map<int, String>.from(state.selectedOptionsByQuestion);
    final selectedSideA = Map<int, bool>.from(state.selectedSideAByQuestion);
    final percentAByQuestion = Map<int, int>.from(state.percentAByQuestion);
    final countAByQuestion = Map<int, int>.from(state.countAByQuestion);
    final countBByQuestion = Map<int, int>.from(state.countBByQuestion);
    var changed = false;

    for (final q in questions) {
      final selected = selectedOptions[q.number] ?? q.myAnswer;
      if (selected == null) continue;
      final sideA = selected == q.optionA;
      final counts = voteCountsForQuestion(
        percentA: q.percentA,
        countA: q.countA,
        countB: q.countB,
      );
      if (!selectedOptions.containsKey(q.number)) {
        selectedOptions[q.number] = selected;
        selectedSideA[q.number] = sideA;
        changed = true;
      }
      if (percentAByQuestion[q.number] != q.percentA) {
        percentAByQuestion[q.number] = q.percentA;
        changed = true;
      }
      if (countAByQuestion[q.number] != counts.$1) {
        countAByQuestion[q.number] = counts.$1;
        changed = true;
      }
      if (countBByQuestion[q.number] != counts.$2) {
        countBByQuestion[q.number] = counts.$2;
        changed = true;
      }
    }

    if (!changed) return;

    state = state.copyWith(
      selectedOptionsByQuestion: selectedOptions,
      selectedSideAByQuestion: selectedSideA,
      percentAByQuestion: percentAByQuestion,
      countAByQuestion: countAByQuestion,
      countBByQuestion: countBByQuestion,
      answeredCount: selectedOptions.length,
      minorityCount: countMinorityAnswers(
        selectedSideAByQuestion: selectedSideA,
        countAByQuestion: countAByQuestion,
        countBByQuestion: countBByQuestion,
      ),
    );
    _persistProgress();
  }

  /// 表示位置の前後の質問データを先読み（集計・エンゲージメント）。
  Future<void> prefetchAround(
    List<DummyQuestion> questions,
    int centerIndex, {
    int before = 2,
    int after = 1,
  }) async {
    if (questions.isEmpty) return;
    final picked = <DummyQuestion>[];
    for (var offset = -before; offset <= after; offset++) {
      final i = centerIndex + offset;
      if (i < 0 || i >= questions.length) continue;
      picked.add(questions[i]);
    }
    syncEngagementFromQuestions(picked);
    applyServerStats(picked);
  }

  /// 表示中の質問について、API 付きの `percentA` を端末状態に反映する。
  Future<void> refreshAnsweredStats(List<DummyQuestion> visibleQuestions) async {
    applyServerStats(visibleQuestions);
  }

  void _applyAnswerLocally(
    DummyQuestion question,
    String selected,
    QuestionVoteStats stats, {
    required bool countAsNew,
  }) {
    final selectedOptions = Map<int, String>.from(state.selectedOptionsByQuestion);
    final selectedSideA = Map<int, bool>.from(state.selectedSideAByQuestion);
    final percentAByQuestion = Map<int, int>.from(state.percentAByQuestion);
    final countAByQuestion = Map<int, int>.from(state.countAByQuestion);
    final countBByQuestion = Map<int, int>.from(state.countBByQuestion);
    final alreadyAnswered = selectedOptions.containsKey(question.number);
    final sideA = selected == question.optionA;

    selectedOptions[question.number] = selected;
    selectedSideA[question.number] = sideA;
    percentAByQuestion[question.number] = stats.percentA;
    countAByQuestion[question.number] = stats.countA;
    countBByQuestion[question.number] = stats.countB;

    state = state.copyWith(
      selectedOptionsByQuestion: selectedOptions,
      selectedSideAByQuestion: selectedSideA,
      percentAByQuestion: percentAByQuestion,
      countAByQuestion: countAByQuestion,
      countBByQuestion: countBByQuestion,
      answeredCount: countAsNew && !alreadyAnswered
          ? state.answeredCount + 1
          : state.answeredCount,
      minorityCount: countMinorityAnswers(
        selectedSideAByQuestion: selectedSideA,
        countAByQuestion: countAByQuestion,
        countBByQuestion: countBByQuestion,
      ),
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

  Future<void> toggleQuestionLike(DummyQuestion question) async {
    final number = question.number;
    final prev = state;
    final liked = {...state.likedQuestionNumbers};
    final willLike = !liked.contains(number);
    var likes = state.likeCountFor(question);
    if (willLike) {
      liked.add(number);
      likes++;
    } else {
      liked.remove(number);
      likes = likes > 0 ? likes - 1 : 0;
    }
    final likeCounts = Map<int, int>.from(state.likeCountByQuestion);
    likeCounts[number] = likes;
    state = state.copyWith(
      likedQuestionNumbers: liked,
      likeCountByQuestion: likeCounts,
    );
    _persistProgress();

    final questionId = question.apiId;
    if (questionId == null) return;
    if (!hasValidAuthSession()) return;

    try {
      await _ref.read(questionRepositoryProvider).toggleQuestionLike(
            questionId: questionId,
            isLike: willLike,
          );
    } catch (e, st) {
      state = prev;
      _persistProgress();
      Error.throwWithStackTrace(e, st);
    }
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
