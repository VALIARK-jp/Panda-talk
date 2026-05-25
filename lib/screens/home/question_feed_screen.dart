import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/category_poster_copy.dart';
import '../../core/feed_panda_picker.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../core/oddball_score.dart';
import '../../core/question_stats_utils.dart';
import '../../core/share_utils.dart';
import '../../infrastructure/diagnosis_16_completion.dart';
import '../../infrastructure/diagnosis_16_store.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/diagnosis_providers.dart';
import '../../presentation/providers/profile_providers.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/diagnosis_16_result_modal.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/guest_login_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/answer_ratio_bar.dart';
import '../../widgets/answer_reveal_overlay.dart';
import '../../widgets/comment_activity_hint.dart';
import '../../widgets/question_poster_section.dart';
import 'question_comments_screen.dart';
import 'question_history_screen.dart';

class QuestionFeedScreen extends ConsumerStatefulWidget {
  const QuestionFeedScreen({
    super.key,
    this.onOpenPost,
    this.homeOpenSerial = 0,
  });

  /// 未回答がなくなったとき、投稿タブへ誘導する。
  final VoidCallback? onOpenPost;
  final int homeOpenSerial;

  @override
  ConsumerState<QuestionFeedScreen> createState() => _QuestionFeedScreenState();
}

class _QuestionFeedScreenState extends ConsumerState<QuestionFeedScreen> {
  int _tabIndex = 0; // 0=診断 1=Hot
  bool _checkedPendingDiagnosisModal = false;

  Timer? _feedSyncDebounce;
  String? _lastSyncedQuestionKey;
  String? _lastBuildFeedKey;
  String? _activeFeedKey;
  int _lastFeedQuestionCount = 0;
  bool _userHasNavigated = false;
  bool _pendingAdvanceAfterAnswer = false;
  int? _revealQuestionNumber;
  _AnswerRevealSnapshot? _revealSnapshot;

  bool get _isGuest {
    final asyncUser = ref.read(authUserProvider);
    return (asyncUser.valueOrNull ??
            Supabase.instance.client.auth.currentUser) ==
        null;
  }

  PageController? _pageController;
  Timer? _nextQuestionTimer;

  /// 回答オーバーレイ終了後、すぐ次の問へ（余白なし）。
  static const _advanceAfterRevealDelay = Duration.zero;
  static const _nudgeMessages = {
    10: '10問答えたね！\n登録すると合致度が見られるよ。',
    20: 'あなたと合う人、\nもう見つかってるかも。',
    30: '異端児スコアが本格的になってきた。\n記録しておこう。',
  };

  @override
  void dispose() {
    _nextQuestionTimer?.cancel();
    _feedSyncDebounce?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuestionFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.homeOpenSerial != widget.homeOpenSerial) {
      _resetHomeFeed();
    }
  }

  void _resetHomeFeed() {
    final resetSerial = widget.homeOpenSerial;
    _nextQuestionTimer?.cancel();
    _feedSyncDebounce?.cancel();
    _lastSyncedQuestionKey = null;
    _lastBuildFeedKey = null;
    _activeFeedKey = null;
    _lastFeedQuestionCount = 0;
    _userHasNavigated = false;
    _pendingAdvanceAfterAnswer = false;
    _clearReveal();
    _pageController?.dispose();
    _pageController = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.homeOpenSerial != resetSerial) return;
      ref.read(questionFeedControllerProvider.notifier).resetForTab();
      ref.invalidate(feedQuestionsProvider);
    });
  }

  Future<void> _onAnswer(
    DummyQuestion q,
    String selected,
    int total,
    List<DummyQuestion> questions,
  ) async {
    final controller = ref.read(questionFeedControllerProvider.notifier);
    final feedState = ref.read(questionFeedControllerProvider);
    if (feedState.selectedOptionFor(q.number) != null || q.myAnswer != null) {
      return;
    }
    final prevOddballScore = oddballScorePercent(
      minorityAnswerCount: feedState.minorityCount,
      totalAnswerCount: feedState.answeredCount,
    );

    await controller.answer(q, selected);
    if (!mounted) return;

    final unlocked = await ref.read(diagnosis16UnlockedProvider.future);
    if (!unlocked && isDiagnosisQuestionNumber(q.number)) {
      final choseA = selected == q.optionA;
      await Diagnosis16Store.saveAnswer(q.number, choseA);

      if (q.number == kDiagnosisQuestionCount) {
        _nextQuestionTimer?.cancel();
        final updated = ref.read(questionFeedControllerProvider);
        final result = await completeDiagnosis16FromFeed(
          ref: ref,
          diagnosisQuestions: questions,
          selectedOptionsByQuestion: updated.selectedOptionsByQuestion,
        );
        if (!mounted) return;
        await showDiagnosis16ResultModal(context, result);
        await Diagnosis16Store.markResultSeen();
        ref.invalidate(diagnosis16UnlockedProvider);
        ref.invalidate(feedQuestionsProvider);
        ref.read(questionFeedControllerProvider.notifier).setQuestionIndex(0);
        return;
      }
    }

    final after = ref.read(questionFeedControllerProvider);
    final percentA = after.percentAFor(q);
    final isMinority = isMinorityAnswer(
      selected: selected,
      question: q,
      countA: after.countAFor(q),
      countB: after.countBFor(q),
    );
    final selectedPercent = selectedSidePercent(
      selected: selected,
      question: q,
      percentA: percentA,
    );
    final newOddballScore = oddballScorePercent(
      minorityAnswerCount: after.minorityCount,
      totalAnswerCount: after.answeredCount,
    );

    _pendingAdvanceAfterAnswer = true;
    ref.invalidate(feedQuestionsProvider);
    _nextQuestionTimer?.cancel();
    setState(() {
      _revealQuestionNumber = q.number;
      _revealSnapshot = _AnswerRevealSnapshot(
        selectedPercent: selectedPercent,
        isMinority: isMinority,
        prevOddballScore: prevOddballScore,
        newOddballScore: newOddballScore,
        oddballBumpLabel: oddballBumpCopy(
          prevScore: prevOddballScore,
          newScore: newOddballScore,
          wasMinorityThisAnswer: isMinority,
        ),
      );
    });
  }

  void _onRevealFinished() {
    if (!mounted) return;
    setState(() {
      _revealQuestionNumber = null;
      _revealSnapshot = null;
    });
    _scheduleAdvanceAfterReveal();
  }

  void _scheduleAdvanceAfterReveal() {
    _nextQuestionTimer?.cancel();
    _nextQuestionTimer = Timer(_advanceAfterRevealDelay, () async {
      if (!mounted) return;
      _pendingAdvanceAfterAnswer = false;
      final answeredCount = ref
          .read(questionFeedControllerProvider)
          .answeredCount;
      final latest = await ref.read(feedQuestionsProvider.future);
      if (!mounted || latest.isEmpty) return;
      final feedState = ref.read(questionFeedControllerProvider);
      final currentIndex = feedState.questionIndex.clamp(0, latest.length - 1);
      final nextIndex = _nextPageIndexAfterAnswer(latest, feedState, currentIndex);
      _animateToQuestion(nextIndex);
      if (_isGuest && _nudgeMessages.containsKey(answeredCount)) {
        _showNudgeModal(answeredCount);
      }
    });
  }

  void _clearReveal() {
    _revealQuestionNumber = null;
    _revealSnapshot = null;
  }

  String _pandaExpressionFor(
    String? selected,
    DummyQuestion q,
    QuestionFeedState feedState,
  ) {
    if (selected == null) return 'normal';
    if (isMinorityAnswer(
      selected: selected,
      question: q,
      countA: feedState.countAFor(q),
      countB: feedState.countBFor(q),
    )) {
      return 'minority';
    }
    return 'majority';
  }

  bool _isQuestionAnswered(DummyQuestion q, QuestionFeedState feedState) {
    return feedState.selectedOptionFor(q.number) != null || q.myAnswer != null;
  }

  /// 回答直後: ひとつ新しい未回答へ。なければフロンティア。
  int _nextPageIndexAfterAnswer(
    List<DummyQuestion> questions,
    QuestionFeedState feedState,
    int currentIndex,
  ) {
    for (var i = currentIndex + 1; i < questions.length; i++) {
      if (!_isQuestionAnswered(questions[i], feedState)) return i;
    }
    return _unansweredFrontierIndex(questions, feedState);
  }

  void _animateToQuestion(int index) {
    if (index < 0) return;
    _userHasNavigated = true;
    _nextQuestionTimer?.cancel();
    final controller = _pageController;
    if (controller == null || !controller.hasClients) {
      ref.read(questionFeedControllerProvider.notifier).setQuestionIndex(index);
      return;
    }
    final current = controller.page?.round() ?? 0;
    if (current == index) {
      ref.read(questionFeedControllerProvider.notifier).setQuestionIndex(index);
      return;
    }
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  /// 未回答のうち番号が最小の問（リスト先頭側）。古い順＝上が古い・下が最新。
  int _unansweredFrontierIndex(
    List<DummyQuestion> questions,
    QuestionFeedState feedState,
  ) {
    for (var i = 0; i < questions.length; i++) {
      if (!_isQuestionAnswered(questions[i], feedState)) return i;
    }
    return questions.length - 1;
  }

  bool _shouldSnapToFrontier(
    List<DummyQuestion> questions, {
    required String feedKey,
  }) {
    if (questions.isEmpty) return false;
    if (!_userHasNavigated || _activeFeedKey != feedKey) return true;
    if (questions.length > _lastFeedQuestionCount) return true;
    final idx = ref.read(questionFeedControllerProvider).questionIndex;
    if (idx >= questions.length) return true;
    return false;
  }

  Future<void> _maybeShowPendingDiagnosisResult() async {
    if (_checkedPendingDiagnosisModal) return;
    _checkedPendingDiagnosisModal = true;

    final unlocked = await ref.read(diagnosis16UnlockedProvider.future);
    if (unlocked || !mounted) return;
    if (!await Diagnosis16Store.isComplete()) return;

    final result = await Diagnosis16Store.loadResult();
    if (result == null || !mounted) return;

    await showDiagnosis16ResultModal(context, result);
    await Diagnosis16Store.markResultSeen();
    ref.invalidate(diagnosis16UnlockedProvider);
    ref.invalidate(feedQuestionsProvider);
  }

  void _showNudgeModal(int count) {
    final message = _nudgeMessages[count]!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NudgeCard(message: message),
    );
  }

  void _shareQuestion({
    required DummyQuestion question,
    required String? selected,
    required int percentA,
  }) {
    final hasAnswered = selected != null;
    final selectedA = selected == question.optionA;
    final feedState = ref.read(questionFeedControllerProvider);
    final selectedPercent = selectedSidePercent(
      selected: selected ?? question.optionA,
      question: question,
      percentA: percentA,
    );
    final isMinority = hasAnswered &&
        isMinorityFromSide(
          selectedA: selectedA,
          percentA: percentA,
          countA: feedState.countAFor(question),
          countB: feedState.countBFor(question),
        );
    final resultText = hasAnswered
        ? '\n私は$selected派（${isMinority ? '少数派 ' : ''}$selectedPercent%）'
        : '';

    AppShare.text(
      context,
      'Q.${question.number} ${question.text}\n'
      'A: ${question.optionA}\n'
      'B: ${question.optionB}'
      '$resultText\n'
      'あなたはどっち？\n'
      '#パンダトーク',
    );
  }

  Widget _buildQuestionPage(
    DummyQuestion q,
    List<DummyQuestion> questions,
    int total,
    QuestionFeedState feedState,
  ) {
    final selected = feedState.selectedOptionFor(q.number) ?? q.myAnswer;
    final percentA = feedState.percentAFor(q);
    final likedQuestion = feedState.likedQuestionNumbers.contains(q.number);
    final commentCount = feedState.commentCountFor(q);
    final showingReveal =
        _revealQuestionNumber == q.number && _revealSnapshot != null;
    final reveal = _revealSnapshot;
    final pandaExpression = _pandaExpressionFor(selected, q, feedState);
    final feedPanda = FeedPandaChoice.forQuestion(q);
    final revealExpression =
        reveal?.isMinority == true ? 'minority' : 'majority';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Stack(
              children: [
                Column(
                  children: [
                    // 投稿者 + 番号 + カテゴリ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      PandaAvatar(size: 28),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.authorName,
                            style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            '@${q.authorUsername}',
                            style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Q.${q.number}',
                        style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TagChip(label: q.category),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: '共有',
                    onPressed: () => _shareQuestion(
                      question: q,
                      selected: selected,
                      percentA: percentA,
                    ),
                    icon: const Icon(Icons.ios_share, color: AppColors.black),
                  ),
                  _EngagementIcon(
                    icon: likedQuestion
                        ? Icons.favorite
                        : Icons.favorite_border,
                    count: feedState.likeCountFor(q),
                    highlighted: likedQuestion,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(questionFeedControllerProvider.notifier)
                            .toggleQuestionLike(q);
                      } catch (_) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('いいねに失敗しました')),
                        );
                      }
                    },
                  ),
                  _EngagementIcon(
                    icon: Icons.mode_comment_outlined,
                    count: feedState.commentCountFor(q),
                    onTap: () async {
                      final posted = await QuestionCommentsScreen.openFocus(
                        context,
                        question: q,
                        percentA: percentA,
                        selectedOption: selected,
                      );
                      if (posted && context.mounted) {
                        ref
                            .read(questionFeedControllerProvider.notifier)
                            .incrementCommentCount(q);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: QuestionPosterSection(
                  question: q,
                  feedPandaChoice: feedPanda,
                  pandaExpression: pandaExpression,
                  commentHint: CommentActivityHint.shouldShow(commentCount)
                      ? CommentActivityHint(commentCount: commentCount)
                      : null,
                ),
              ),
              Hero(
                tag: answerRatioBarHeroTag(q),
                child: Material(
                  color: Colors.transparent,
                  child: AnswerRatioBar(
                    question: q,
                    percentA: percentA,
                    selectedOption: selected,
                    onSelect: (option) =>
                        _onAnswer(q, option, total, questions),
                  ),
                ),
              ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
                if (showingReveal && reveal != null)
                  Positioned.fill(
                    child: AnswerRevealOverlay(
                      selectedPercent: reveal.selectedPercent,
                      isMinority: reveal.isMinority,
                      prevOddballScore: reveal.prevOddballScore,
                      newOddballScore: reveal.newOddballScore,
                      oddballBumpLabel: reveal.oddballBumpLabel,
                      mascotAssetPath: feedPanda.assetPathForExpression(
                        revealExpression,
                      ),
                      onFinished: _onRevealFinished,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _diagnosisAnsweredCount(
    List<DummyQuestion> questions,
    QuestionFeedState feedState,
  ) {
    var count = 0;
    for (final q in questions) {
      if (!isDiagnosisQuestionNumber(q.number)) continue;
      if (feedState.selectedOptionFor(q.number) != null || q.myAnswer != null) {
        count++;
      }
    }
    return count;
  }

  Widget _buildDiagnosisProgressBar(int answered) {
    const total = kDiagnosisQuestionCount;
    final done = answered >= total;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '初回診断',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
              Text(
                done ? '診断完了' : '$answered / $total',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w700,
                  color: done ? AppColors.black : AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: answered / total,
              minHeight: 8,
              backgroundColor: AppColors.softGray,
              valueColor: const AlwaysStoppedAnimation(AppColors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAnsweredBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: GestureDetector(
        onTap: widget.onOpenPost,
        behavior: HitTestBehavior.opaque,
        child: Text(
          widget.onOpenPost != null
              ? '未解答はありません。二択を投稿してみよう →'
              : '未解答はありません',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppFontSize.sm,
            color: AppColors.textGray,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildNoQuestionsEmpty() {
    return Scaffold(
      backgroundColor: AppColors.softGray,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PandaMascot(size: 72),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'まだ質問がありません',
                  style: TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  '最初の二択を投稿してみよう！',
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    color: AppColors.textGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.onOpenPost != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  PandaButton(
                    label: '二択を投稿する',
                    onTap: widget.onOpenPost,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _ensurePageController(
    List<DummyQuestion> questions,
    QuestionFeedState feedState,
  ) {
    if (questions.isEmpty) return;
    if (_pageController != null) return;

    final frontier = _unansweredFrontierIndex(questions, feedState)
        .clamp(0, questions.length - 1);
    final initial = _userHasNavigated
        ? feedState.questionIndex.clamp(0, questions.length - 1)
        : frontier;

    _pageController = PageController(initialPage: initial);
    // build 中に StateNotifier を更新しない（Riverpod の制約）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(questionFeedControllerProvider.notifier).setQuestionIndex(initial);
    });
  }

  Widget _buildScreen(
    List<DummyQuestion> questions,
    QuestionFeedState feedState, {
    required bool showDiagnosisProgress,
    bool showAllAnsweredBanner = false,
  }) {
    final total = questions.length;
    _ensurePageController(questions, feedState);
    final diagnosisAnswered = showDiagnosisProgress
        ? _diagnosisAnsweredCount(questions, feedState)
        : 0;
    final pageController = _pageController;
    if (pageController == null) {
      return const Scaffold(
        backgroundColor: AppColors.softGray,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.softGray,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedTabs(
                      tabs: const ['診断', 'Hot'],
                      selectedIndex: _tabIndex,
                      onChanged: (i) {
                        _nextQuestionTimer?.cancel();
                        setState(() {
                          _tabIndex = i;
                        });
                        ref
                            .read(questionFeedControllerProvider.notifier)
                            .resetForTab();
                        if (_pageController?.hasClients == true) {
                          _pageController!.jumpToPage(0);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: '更新',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: _refreshFromServer,
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.black,
                      size: 24,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuestionHistoryScreen(),
                      ),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: AppColors.black,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const GuestLoginButton(),
                ],
              ),
            ),
            if (showDiagnosisProgress)
              _buildDiagnosisProgressBar(diagnosisAnswered),
            if (showAllAnsweredBanner) _buildAllAnsweredBanner(),
            Expanded(
              child: PageView.builder(
                  controller: pageController,
                  scrollDirection: Axis.vertical,
                  physics: total > 1
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: total,
                  onPageChanged: (index) {
                    _userHasNavigated = true;
                    _nextQuestionTimer?.cancel();
                    if (_revealQuestionNumber != null) {
                      setState(_clearReveal);
                      if (_pendingAdvanceAfterAnswer) {
                        _scheduleAdvanceAfterReveal();
                      }
                    }
                    final notifier = ref.read(
                      questionFeedControllerProvider.notifier,
                    );
                    notifier.setQuestionIndex(index);
                    Future.microtask(
                      () => notifier.prefetchAround(questions, index),
                    );
                  },
                  itemBuilder: (context, index) {
                    final currentFeed = ref.watch(questionFeedControllerProvider);
                    return _buildQuestionPage(
                      questions[index],
                      questions,
                      total,
                      currentFeed,
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }

  bool _feedIsAllAnswered(
    List<DummyQuestion> questions,
    QuestionFeedState feedState,
  ) {
    if (questions.isEmpty) return false;
    return questions.every((q) {
      return feedState.selectedOptionFor(q.number) != null ||
          q.myAnswer != null;
    });
  }

  String _feedErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('Connection refused') && AppConfig.usesLocalApiHost) {
      return 'API（${AppConfig.apiBaseUrl}）に接続できません。\n\n'
          '別ターミナルで次を実行してください:\n'
          'cd backend && npm run dev:db\n\n'
          'または .env の PANDA_TALK_API_BASE_URL を '
          'deploy 済みの https://….workers.dev に変更してください。';
    }
    if (text.contains('Connection refused') || text.contains('Failed host lookup')) {
      return 'API に接続できません。\n'
          '.env の PANDA_TALK_API_BASE_URL を確認してください。';
    }
    return '質問を読み込めませんでした。\n$text';
  }

  String _questionsSyncKey(List<DummyQuestion> questions) {
    return questions.map((q) => '${q.apiId}:${q.myAnswer ?? ""}').join('|');
  }

  void _scheduleFeedSync(List<DummyQuestion> questions) {
    if (questions.isEmpty) return;
    final bootstrap = ref.read(feedBootstrapProvider);
    if (!bootstrap.hasValue) return;

    final key = _questionsSyncKey(questions);
    if (key == _lastSyncedQuestionKey) return;

    _feedSyncDebounce?.cancel();
    _feedSyncDebounce = Timer(Duration.zero, () {
      if (!mounted) return;
      _lastSyncedQuestionKey = key;
      final notifier = ref.read(questionFeedControllerProvider.notifier);
      Future.microtask(() async {
        await notifier.reconcileWithServer(questions);
        if (!mounted) return;
        final feedState = ref.read(questionFeedControllerProvider);
        notifier.applyServerStats(questions);

        final snap = _shouldSnapToFrontier(questions, feedKey: key);
        _lastFeedQuestionCount = questions.length;
        _activeFeedKey = key;
        if (snap && !_pendingAdvanceAfterAnswer && _pageController != null) {
          final frontier = _unansweredFrontierIndex(questions, feedState);
          final current = _pageController!.hasClients
              ? (_pageController!.page?.round() ?? 0)
              : feedState.questionIndex;
          if (current != frontier) {
            _pageController!.jumpToPage(frontier);
            notifier.setQuestionIndex(frontier);
          }
        }
      });
    });
  }

  Future<void> _refreshFromServer() async {
    _lastSyncedQuestionKey = null;
    _lastBuildFeedKey = null;
    _userHasNavigated = false;
    _activeFeedKey = null;
    _pageController?.dispose();
    _pageController = null;

    // 診断完了後も unlock 状態が古いと Q1–16 のまま再取得される
    ref.invalidate(diagnosis16UnlockedProvider);
    ref.invalidate(profileControllerProvider);
    ref.invalidate(questionFeedControllerProvider);
    ref.invalidate(feedQuestionsProvider);
    ref.invalidate(feedBootstrapProvider);

    try {
      await ref.read(profileControllerProvider.future);
      var unlocked = await ref.read(diagnosis16UnlockedProvider.future);
      if (!unlocked) {
        _checkedPendingDiagnosisModal = false;
        await _maybeShowPendingDiagnosisResult();
        unlocked = await ref.read(diagnosis16UnlockedProvider.future);
      }
      await ref.read(feedQuestionsProvider.future);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    }
  }

  List<DummyQuestion> _orderForTab(List<DummyQuestion> questions) {
    final ordered = [...questions];
    if (_tabIndex == 1) {
      ordered.sort((a, b) => b.percentA.compareTo(a.percentA));
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(questionFeedControllerProvider);
    final bootstrap = ref.watch(feedBootstrapProvider);
    final feedAsync = ref.watch(feedQuestionsProvider);
    final inDiagnosis16 = !(ref.watch(diagnosis16UnlockedProvider).valueOrNull ??
        false);

    if (!bootstrap.hasValue && bootstrap.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.softGray,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return feedAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              _feedErrorMessage(e),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
      data: (feedQuestions) {
        if (feedQuestions.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowPendingDiagnosisResult();
          });
          return _buildNoQuestionsEmpty();
        }

        final ordered = _orderForTab(feedQuestions);
        final feedKey = _questionsSyncKey(ordered);
        if (feedKey != _lastBuildFeedKey) {
          final prevKey = _lastBuildFeedKey;
          _lastBuildFeedKey = feedKey;
          if (_activeFeedKey != feedKey) {
            _userHasNavigated = false;
          }
          if (inDiagnosis16 &&
              prevKey != null &&
              prevKey != feedKey &&
              ordered.length != _lastFeedQuestionCount) {
            _pageController?.dispose();
            _pageController = null;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scheduleFeedSync(ordered);
          });
        }

        if (inDiagnosis16) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowPendingDiagnosisResult();
          });
        }

        final allAnswered = !inDiagnosis16 &&
            _feedIsAllAnswered(ordered, feedState);

        return _buildScreen(
          ordered,
          feedState,
          showDiagnosisProgress: inDiagnosis16,
          showAllAnsweredBanner: allAnswered,
        );
      },
    );
  }
}

class _EngagementIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool highlighted;
  final VoidCallback? onTap;

  const _EngagementIcon({
    required this.icon,
    required this.count,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.likeRed : AppColors.black;
    return SizedBox(
      width: 48,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w700,
                color: highlighted ? AppColors.likeRed : AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerRevealSnapshot {
  final int selectedPercent;
  final bool isMinority;
  final int prevOddballScore;
  final int newOddballScore;
  final String? oddballBumpLabel;

  const _AnswerRevealSnapshot({
    required this.selectedPercent,
    required this.isMinority,
    required this.prevOddballScore,
    required this.newOddballScore,
    this.oddballBumpLabel,
  });
}

class _NudgeCard extends StatelessWidget {
  final String message;

  const _NudgeCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PandaMascot(size: 72, expression: 'default'),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: const TextStyle(
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          PandaButton(label: '登録する', onTap: () => Navigator.pop(context)),
          const SizedBox(height: AppSpacing.sm),
          PandaOutlinedButton(
            label: '続ける',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
