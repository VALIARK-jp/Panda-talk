import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dummy_data.dart';
import '../../infrastructure/diagnosis_16_store.dart';
import '../../infrastructure/providers/repositories.dart';
import 'diagnosis_providers.dart';
import 'question_providers.dart' show questionFeedControllerProvider;

/// 履歴から一気に飛ぶとき: その問を中心に前後どれだけ取るか（around）。
const kAnchorInitialRadius = 20;

/// 保持範囲の端からこの問数以内に入ったら、先読みで次の塊を取る。
const kEdgePrefetchDistance = 5;

/// 先読みで1回に足す問数（スクロール方向）。
const kPrefetchChunkSize = 15;

final feedJumpToQuestionNumberProvider = StateProvider<int?>((ref) => null);

class FeedWindowState {
  const FeedWindowState({
    this.loaded = const [],
    this.loadedMin = 1,
    this.loadedMax = 1,
    /// 直近の API 取得の基準点（ジャンプ地点や追加取得を始めた地点）。
    this.anchorQuestionNumber = 1,
    this.jumpToQuestionNumber,
  });

  final List<DummyQuestion> loaded;
  final int loadedMin;
  final int loadedMax;
  final int anchorQuestionNumber;
  final int? jumpToQuestionNumber;

  FeedWindowState copyWith({
    List<DummyQuestion>? loaded,
    int? loadedMin,
    int? loadedMax,
    int? anchorQuestionNumber,
    int? jumpToQuestionNumber,
    bool clearJump = false,
  }) {
    return FeedWindowState(
      loaded: loaded ?? this.loaded,
      loadedMin: loadedMin ?? this.loadedMin,
      loadedMax: loadedMax ?? this.loadedMax,
      anchorQuestionNumber: anchorQuestionNumber ?? this.anchorQuestionNumber,
      jumpToQuestionNumber: clearJump
          ? null
          : (jumpToQuestionNumber ?? this.jumpToQuestionNumber),
    );
  }
}

/// 表示: 回答済み + 未回答1問（取得済みデータのうちフロンティアより先は出さない）。
List<DummyQuestion> clipFeedProgressView(
  List<DummyQuestion> sortedByNumber,
  bool Function(DummyQuestion q) isAnswered,
) {
  if (sortedByNumber.isEmpty) return sortedByNumber;

  int? frontier;
  for (final q in sortedByNumber) {
    if (!isAnswered(q)) {
      frontier = q.number;
      break;
    }
  }
  if (frontier == null) return sortedByNumber;
  final maxVisible = frontier;
  return sortedByNumber.where((q) => q.number <= maxVisible).toList();
}

class FeedWindowController extends AsyncNotifier<FeedWindowState> {
  bool _prefetchInFlight = false;
  List<DummyQuestion> _cache = const [];
  int? _newerPrefetchFromLoadedMax;
  int? _olderPrefetchFromLoadedMin;

  @override
  Future<FeedWindowState> build() async {
    final jump = ref.read(feedJumpToQuestionNumberProvider);
    final next = jump != null
        ? await _establishAnchorAt(
            jump,
            radiusBefore: kAnchorInitialRadius,
            radiusAfter: kAnchorInitialRadius,
          )
        : await _loadFrontierWindow();
    _resetPrefetchGuards();
    _syncCache(next);
    return next;
  }

  void _syncCache(FeedWindowState next) {
    _cache = next.loaded;
  }

  void _resetPrefetchGuards() {
    _newerPrefetchFromLoadedMax = null;
    _olderPrefetchFromLoadedMin = null;
  }

  FeedWindowState _workingState() {
    if (_cache.isEmpty) {
      return state.valueOrNull ?? const FeedWindowState();
    }
    final sorted = [..._cache]..sort((a, b) => a.number.compareTo(b.number));
    return FeedWindowState(
      loaded: sorted,
      loadedMin: sorted.first.number,
      loadedMax: sorted.last.number,
      anchorQuestionNumber:
          state.valueOrNull?.anchorQuestionNumber ?? sorted.first.number,
      jumpToQuestionNumber: state.valueOrNull?.jumpToQuestionNumber,
    );
  }

  void _publish(FeedWindowState next) {
    _syncCache(next);
    state = AsyncData(next);
  }

  /// 先読みだけ更新。Riverpod の state は触らないので UI は rebuild しない。
  void _mergePrefetchOnly(FeedWindowState next) {
    _syncCache(next);
  }

  bool _cacheGrew(FeedWindowState before, FeedWindowState after) {
    return after.loaded.length > before.loaded.length ||
        after.loadedMax > before.loadedMax ||
        after.loadedMin < before.loadedMin;
  }

  /// ログイン直後など: サーバーの未回答フロンティア中心にまとめて取得。
  Future<FeedWindowState> _loadFrontierWindow() async {
    final repo = ref.read(questionRepositoryProvider);
    final batch = await repo.getFeedWindow(
      before: kAnchorInitialRadius,
      after: kAnchorInitialRadius,
    );
    final merged = await _mergeGuestAnswers(const [], batch);
    final sorted = [...merged]..sort((a, b) => a.number.compareTo(b.number));
    if (sorted.isEmpty) {
      return const FeedWindowState();
    }

    final anchor = _firstUnansweredNumber(sorted) ?? sorted.last.number;
    if (kDebugMode) {
      debugPrint(
        '[FeedWindow] GET /questions/window → Q${sorted.first.number}–'
        '${sorted.last.number}, anchor=Q$anchor',
      );
    }

    return FeedWindowState(
      loaded: sorted,
      loadedMin: sorted.first.number,
      loadedMax: sorted.last.number,
      anchorQuestionNumber: anchor,
    );
  }

  /// 履歴ジャンプ: その問をアンカーに前後 [radius] を around で取得。
  Future<FeedWindowState> _establishAnchorAt(
    int center, {
    required int radiusBefore,
    required int radiusAfter,
    String? questionId,
    FeedWindowState previous = const FeedWindowState(),
  }) async {
    final repo = ref.read(questionRepositoryProvider);
    final batch = await repo.getFeedWindowAround(
      before: radiusBefore,
      after: radiusAfter,
      questionNumber: center,
      questionId: questionId,
      currentQuestionNumber: center,
    );
    final merged = await _mergeGuestAnswers(previous.loaded, batch);
    final sorted = [...merged]..sort((a, b) => a.number.compareTo(b.number));
    if (sorted.isEmpty) {
      return previous.copyWith(
        anchorQuestionNumber: center,
        jumpToQuestionNumber: center,
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[FeedWindow] GET /questions/window/around anchor=Q$center '
        '(±$radiusBefore) → Q${sorted.first.number}–Q${sorted.last.number}',
      );
    }

    return FeedWindowState(
      loaded: sorted,
      loadedMin: sorted.first.number,
      loadedMax: sorted.last.number,
      anchorQuestionNumber: center,
      jumpToQuestionNumber: previous.jumpToQuestionNumber ?? center,
    );
  }

  Future<List<DummyQuestion>> _mergeGuestAnswers(
    List<DummyQuestion> existing,
    List<DummyQuestion> incoming,
  ) async {
    final guestDiag = await Diagnosis16Store.loadAnswers();
    final byNumber = <int, DummyQuestion>{
      for (final q in existing) q.number: q,
    };
    for (final q in incoming) {
      final guestChoice = guestDiag[q.number];
      if (guestChoice != null) {
        byNumber[q.number] = q.copyWith(
          myAnswer: guestChoice ? q.optionA : q.optionB,
        );
      } else {
        byNumber[q.number] = q;
      }
    }
    return byNumber.values.toList();
  }

  int? _firstUnansweredNumber(List<DummyQuestion> sorted) {
    for (final q in sorted) {
      if (!_isAnswered(q)) return q.number;
    }
    return null;
  }

  bool _isAnswered(DummyQuestion q) {
    final feed = ref.read(questionFeedControllerProvider);
    if (feed.selectedOptionFor(q.number) != null) return true;
    return q.myAnswer != null;
  }

  List<DummyQuestion> _sortedLoaded() {
    final raw = _cache.isNotEmpty
        ? _cache
        : (state.valueOrNull?.loaded ?? const []);
    return [...raw]..sort((a, b) => a.number.compareTo(b.number));
  }

  List<DummyQuestion> displayForDiagnosisTab() {
    return clipFeedProgressView(_sortedLoaded(), _isAnswered);
  }

  List<DummyQuestion> displayForHotTab() => _sortedLoaded();

  /// 保持 [loadedMin..loadedMax] の端から [kEdgePrefetchDistance] 問以内なら先読み。
  ///
  /// 例: 保持 Q40–62・PageView Q35 → 40−35=5 → ここで古い15問を足す。
  bool _needsOlderPrefetch(FeedWindowState s, int questionNumber) {
    if (s.loadedMin <= 1) return false;
    if (questionNumber < s.loadedMin) {
      return s.loadedMin - questionNumber <= kEdgePrefetchDistance;
    }
    return questionNumber - s.loadedMin <= kEdgePrefetchDistance;
  }

  bool _needsNewerPrefetch(FeedWindowState s, int questionNumber) {
    if (questionNumber > s.loadedMax) {
      return questionNumber - s.loadedMax <= kEdgePrefetchDistance;
    }
    return s.loadedMax - questionNumber <= kEdgePrefetchDistance;
  }

  Future<void> onViewportCenter(int questionNumber) async {
    if (state.valueOrNull == null || _prefetchInFlight) return;

    final current = _workingState();
    if (current.loaded.isEmpty) return;

    final needOlder = _needsOlderPrefetch(current, questionNumber);
    final needNewer = _needsNewerPrefetch(current, questionNumber);

    if (!needOlder && !needNewer) return;
    if (needOlder && _olderPrefetchFromLoadedMin == current.loadedMin) return;
    if (needNewer && _newerPrefetchFromLoadedMax == current.loadedMax) return;

    _prefetchInFlight = true;
    final previous = current;
    try {
      if (needOlder) _olderPrefetchFromLoadedMin = current.loadedMin;
      if (needNewer) _newerPrefetchFromLoadedMax = current.loadedMax;

      final next = needOlder
          ? await _prefetchOlder(previous, triggerAt: questionNumber)
          : await _prefetchNewer(previous, triggerAt: questionNumber);

      if (!_cacheGrew(previous, next)) return;

      _mergePrefetchOnly(next);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FeedWindow] prefetch failed: $e $st');
    } finally {
      _prefetchInFlight = false;
    }
  }

  Future<FeedWindowState> _prefetchOlder(
    FeedWindowState previous, {
    required int triggerAt,
  }) async {
    final repo = ref.read(questionRepositoryProvider);
    final edge = previous.loadedMin;
    final batch = await repo.getFeedWindowAround(
      before: kPrefetchChunkSize,
      after: 0,
      questionNumber: edge > 1 ? edge - 1 : 1,
      currentQuestionNumber: triggerAt,
    );
    return _afterChunkMerge(
      previous: previous,
      batch: batch,
      newAnchor: triggerAt,
      direction: 'older',
    );
  }

  Future<FeedWindowState> _prefetchNewer(
    FeedWindowState previous, {
    required int triggerAt,
  }) async {
    final repo = ref.read(questionRepositoryProvider);
    final batch = await repo.getFeedWindowAround(
      before: 0,
      after: kPrefetchChunkSize,
      questionNumber: previous.loadedMax + 1,
      currentQuestionNumber: triggerAt,
    );
    return _afterChunkMerge(
      previous: previous,
      batch: batch,
      newAnchor: triggerAt,
      direction: 'newer',
    );
  }

  Future<FeedWindowState> _afterChunkMerge({
    required FeedWindowState previous,
    required List<DummyQuestion> batch,
    required int newAnchor,
    required String direction,
  }) async {
    final merged = await _mergeGuestAnswers(previous.loaded, batch);
    final sorted = [...merged]..sort((a, b) => a.number.compareTo(b.number));
    if (sorted.isEmpty) return previous;

    if (kDebugMode) {
      debugPrint(
        '[FeedWindow] prefetch $direction +$kPrefetchChunkSize at Q$newAnchor '
        '→ Q${sorted.first.number}–Q${sorted.last.number}',
      );
    }

    return FeedWindowState(
      loaded: sorted,
      loadedMin: sorted.first.number,
      loadedMax: sorted.last.number,
      anchorQuestionNumber: newAnchor,
      jumpToQuestionNumber: previous.jumpToQuestionNumber,
    );
  }

  /// 履歴タップ: around(問番号, ±20) でまとめて取り、アンカーをジャンプ先に固定。
  Future<void> jumpTo({
    required int questionNumber,
    String? questionId,
  }) async {
    ref.read(feedJumpToQuestionNumberProvider.notifier).state = questionNumber;
    _resetPrefetchGuards();
    state = const AsyncLoading<FeedWindowState>();
    try {
      final next = await _establishAnchorAt(
        questionNumber,
        radiusBefore: kAnchorInitialRadius,
        radiusAfter: kAnchorInitialRadius,
        questionId: questionId,
        previous: const FeedWindowState(),
      );
      _publish(
        next.copyWith(
          anchorQuestionNumber: questionNumber,
          jumpToQuestionNumber: questionNumber,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reloadFromScratch() async {
    ref.read(feedJumpToQuestionNumberProvider.notifier).state = null;
    _resetPrefetchGuards();
    state = const AsyncLoading();
    final next = await build();
    _publish(next);
  }

  /// 回答直後: 既に保持している窓を更新するだけ。毎回 GET /window はしない。
  Future<void> recordAnswerLocally({
    required DummyQuestion question,
    required String selectedOption,
    required int percentA,
    required int countA,
    required int countB,
  }) async {
    final current = _workingState();
    if (current.loaded.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[FeedWindow] recordAnswerLocally: cache empty, skip (Q${question.number})',
        );
      }
      return;
    }

    final updated = question.copyWith(
      myAnswer: selectedOption,
      percentA: percentA,
      countA: countA,
      countB: countB,
    );
    final byNumber = <int, DummyQuestion>{
      for (final q in current.loaded) q.number: q,
    };
    byNumber[question.number] = updated;
    final sorted = byNumber.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final anchor = _firstUnansweredNumber(sorted) ?? sorted.last.number;

    if (kDebugMode) {
      debugPrint(
        '[FeedWindow] local answer Q${question.number} → anchor=Q$anchor '
        '(cache Q${sorted.first.number}–Q${sorted.last.number}, no refetch)',
      );
    }

    _mergePrefetchOnly(
      FeedWindowState(
        loaded: sorted,
        loadedMin: sorted.first.number,
        loadedMax: sorted.last.number,
        anchorQuestionNumber: anchor,
        jumpToQuestionNumber: state.valueOrNull?.jumpToQuestionNumber,
      ),
    );
  }

  void clearJumpTarget() {
    final current = state.valueOrNull;
    if (current == null) return;
    _publish(current.copyWith(clearJump: true));
    ref.read(feedJumpToQuestionNumberProvider.notifier).state = null;
  }
}

final feedWindowControllerProvider =
    AsyncNotifierProvider<FeedWindowController, FeedWindowState>(
  FeedWindowController.new,
);

Future<void> openQuestionInFeed(
  WidgetRef ref, {
  required int questionNumber,
  String? questionId,
}) async {
  await ref.read(feedWindowControllerProvider.notifier).jumpTo(
        questionNumber: questionNumber,
        questionId: questionId,
      );
}

void resetFeedWindowNavigation(WidgetRef ref) {
  ref.read(feedJumpToQuestionNumberProvider.notifier).state = null;
  ref.invalidate(feedWindowControllerProvider);
}

final feedBootstrapProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  await ref.watch(diagnosis16UnlockedProvider.future);
  ref.invalidate(feedWindowControllerProvider);
  await ref.read(feedWindowControllerProvider.future);
});

final feedQuestionsProvider = Provider<AsyncValue<List<DummyQuestion>>>((ref) {
  final window = ref.watch(feedWindowControllerProvider);
  return window.whenData(
    (_) => ref.read(feedWindowControllerProvider.notifier).displayForDiagnosisTab(),
  );
});
