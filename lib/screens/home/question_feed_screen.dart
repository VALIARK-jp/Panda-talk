import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/category_poster_copy.dart';
import '../../core/feed_panda_picker.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../core/panda_type.dart';
import '../../core/oddball_score.dart';
import '../../core/question_stats_utils.dart';
import '../../core/share_utils.dart';
import '../../infrastructure/diagnosis_16_completion.dart';
import '../../infrastructure/diagnosis_16_store.dart';
import '../../infrastructure/diagnosis_16_sync.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/moderation_providers.dart';
import '../../presentation/providers/diagnosis_providers.dart';
import '../../presentation/providers/profile_providers.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/diagnosis_16_login_gate.dart';
import '../../widgets/diagnosis_16_result_modal.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/guest_login_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/share_action_sheet.dart';
import '../../widgets/poster_action_sheet.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/username_label.dart';
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
  bool _presentingDiagnosisResult = false;

  Timer? _feedSyncDebounce;
  String? _lastSyncedQuestionKey;
  String? _lastBuildFeedKey;
  String? _lastBuildStructureKey;
  bool _userHasNavigated = false;
  bool _pendingAdvanceAfterAnswer = false;
  int? _revealQuestionNumber;
  int? _lastAnsweredQuestionNumber;
  _AnswerRevealSnapshot? _revealSnapshot;

  bool get _isAnswerFlowLocked =>
      _pendingAdvanceAfterAnswer || _revealQuestionNumber != null;

  bool get _isGuest {
    final asyncUser = ref.read(authUserProvider);
    return (asyncUser.valueOrNull ??
            Supabase.instance.client.auth.currentUser) ==
        null;
  }

  PageController? _pageController;
  Timer? _nextQuestionTimer;
  int? _pendingJumpTarget;

  /// 回答オーバーレイ終了後、比率演出の余韻を残してから次の問へ。
  static const _advanceAfterRevealDelay = Duration(milliseconds: 300);

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
    resetFeedWindowNavigation(ref);
    final resetSerial = widget.homeOpenSerial;
    _nextQuestionTimer?.cancel();
    _feedSyncDebounce?.cancel();
    _lastSyncedQuestionKey = null;
    _lastBuildFeedKey = null;
    _lastBuildStructureKey = null;
    _userHasNavigated = false;
    _pendingAdvanceAfterAnswer = false;
    _lastAnsweredQuestionNumber = null;
    _clearReveal();
    _pageController?.dispose();
    _pageController = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.homeOpenSerial != resetSerial) return;
      ref.read(questionFeedControllerProvider.notifier).resetForTab();
      ref.invalidate(feedWindowControllerProvider);
    });
  }

  Future<void> _showHotComingSoonModal() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hot'),
        content: const Text('現在開発中です'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _onFeedTabChanged(int index) async {
    if (index == 1) {
      await _showHotComingSoonModal();
      return;
    }

    _nextQuestionTimer?.cancel();
    setState(() {
      _tabIndex = index;
    });
    ref.read(questionFeedControllerProvider.notifier).resetForTab();
    if (_pageController?.hasClients == true) {
      _pageController!.jumpToPage(0);
    }
  }

  Future<void> _onAnswer(
    DummyQuestion q,
    String selected,
    int total,
    List<DummyQuestion> questions,
  ) async {
    if (_isAnswerFlowLocked) return;

    final controller = ref.read(questionFeedControllerProvider.notifier);
    final feedState = ref.read(questionFeedControllerProvider);
    if (feedState.selectedOptionFor(q.number) != null || q.myAnswer != null) {
      return;
    }

    _pendingAdvanceAfterAnswer = true;
    _lastAnsweredQuestionNumber = q.number;
    _nextQuestionTimer?.cancel();
    final prevOddballScore = oddballScorePercent(
      minorityAnswerCount: feedState.minorityCount,
      totalAnswerCount: feedState.answeredCount,
    );

    try {
      await controller.answer(q, selected);
    } catch (_) {
      _pendingAdvanceAfterAnswer = false;
      _lastAnsweredQuestionNumber = null;
      rethrow;
    }
    if (!mounted) return;

    final afterAnswer = ref.read(questionFeedControllerProvider);
    if (afterAnswer.selectedOptionFor(q.number) == null) {
      _pendingAdvanceAfterAnswer = false;
      _lastAnsweredQuestionNumber = null;
      return;
    }

    final unlocked = await ref.read(diagnosis16UnlockedProvider.future);
    if (!unlocked && isDiagnosisQuestionNumber(q.number)) {
      await Diagnosis16Store.saveAnswer(q.number, selected == q.optionA);
    }

    if (q.number == kDiagnosisQuestionCount && !unlocked) {
      final updated = ref.read(questionFeedControllerProvider);
      if (_allDiagnosisQuestionsAnswered(updated)) {
        _nextQuestionTimer?.cancel();
        final result = await completeDiagnosis16FromFeed(
          ref: ref,
          diagnosisQuestions: questions,
          selectedOptionsByQuestion: updated.selectedOptionsByQuestion,
        );
        if (!mounted) return;
        if (_isGuest) {
          await showDiagnosis16LoginGate(context);
          return;
        }
        await _presentDiagnosisResult(result);
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

    // Let the ratio bar morph first, then start full-screen reveal.
    Future.delayed(const Duration(milliseconds: 520), () {
      if (!mounted) return;
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
      final latest = ref
          .read(feedWindowControllerProvider.notifier)
          .displayForDiagnosisTab();
      if (!mounted || latest.isEmpty) {
        _pendingAdvanceAfterAnswer = false;
        _lastAnsweredQuestionNumber = null;
        return;
      }
      final feedState = ref.read(questionFeedControllerProvider);
      final answeredNumber = _lastAnsweredQuestionNumber;
      final startIndex = answeredNumber == null
          ? feedState.questionIndex.clamp(0, latest.length - 1)
          : latest.indexWhere((q) => q.number == answeredNumber);
      final currentIndex = startIndex >= 0
          ? startIndex
          : feedState.questionIndex.clamp(0, latest.length - 1);
      final nextIndex = _nextPageIndexAfterAnswer(
        latest,
        feedState,
        currentIndex,
      );
      _animateToQuestion(nextIndex);
      _pendingAdvanceAfterAnswer = false;
      _lastAnsweredQuestionNumber = null;
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
    required String structureKey,
  }) {
    if (questions.isEmpty) return false;
    if (_isAnswerFlowLocked) return false;
    if (ref.read(feedJumpToQuestionNumberProvider) != null) return false;
    return !_userHasNavigated;
  }

  Future<void> _presentDiagnosisResult(PandaTypeResult result) async {
    await showDiagnosis16ResultModal(context, result);
    await Diagnosis16Store.markResultSeen();
    resetFeedWindowNavigation(ref);
    ref.invalidate(diagnosis16UnlockedProvider);
    ref.invalidate(feedWindowControllerProvider);
    ref.read(questionFeedControllerProvider.notifier).setQuestionIndex(0);
  }

  Future<void> _presentDiagnosisResultAfterLogin() async {
    if (_presentingDiagnosisResult) return;
    if (await Diagnosis16Store.isResultSeen()) return;
    _presentingDiagnosisResult = true;
    try {
      await Diagnosis16Store.migrateGuestScopeToCurrentUser();
      await syncDiagnosis16Result(ref);
      if (!mounted) return;
      if (!await Diagnosis16Store.isComplete()) return;
      if (await Diagnosis16Store.isResultSeen()) return;
      final result = await Diagnosis16Store.loadResult();
      if (result == null || !mounted) return;
      await _presentDiagnosisResult(result);
    } finally {
      _presentingDiagnosisResult = false;
    }
  }

  Future<void> _maybeShowPendingDiagnosisResult() async {
    if (_checkedPendingDiagnosisModal) return;
    _checkedPendingDiagnosisModal = true;

    final unlocked = await ref.read(diagnosis16UnlockedProvider.future);
    if (unlocked || !mounted) return;
    if (!await Diagnosis16Store.isComplete()) return;

    if (_isGuest) {
      if (!await Diagnosis16Store.isResultSeen()) {
        if (!mounted) return;
        await showDiagnosis16LoginGate(context);
      }
      return;
    }

    await _presentDiagnosisResultAfterLogin();
  }

  void _shareQuestion({
    required DummyQuestion question,
    required String? selected,
    required int percentA,
  }) {
    final hasAnswered = selected != null;
    final selectedA = selected == question.optionA;
    final feedState = ref.read(questionFeedControllerProvider);
    final isMinority = hasAnswered &&
        isMinorityFromSide(
          selectedA: selectedA,
          percentA: percentA,
          countA: feedState.countAFor(question),
          countB: feedState.countBFor(question),
        );

    // SNS向け共有文（[docs/18_share_growth_spec.md] §3-1）。
    showShareActionSheet(
      context,
      payload: SharePayload.text(
        ShareTexts.question(
          q: question,
          selected: selected,
          percentA: percentA,
          isMinority: isMinority,
        ),
      ),
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
    final pandaExpression = _pandaExpressionFor(selected, q, feedState);
    final feedPanda = FeedPandaChoice.forQuestion(q);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideLayout = constraints.maxWidth >= 700;
        final horizontalPadding = isWideLayout ? AppSpacing.xl : AppSpacing.md;
        final cardMaxWidth = isWideLayout ? 680.0 : double.infinity;
        final categoryColor = categoryAccentColor(q.category);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.md,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.10),
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
                                Expanded(
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => showPosterActionSheet(
                                          context,
                                          ref: ref,
                                          question: q,
                                        ),
                                        child: UserAvatar(
                                          size: 28,
                                          imageUrl: q.authorAvatarUrl,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              q.authorName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: AppFontSize.sm,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.black,
                                              ),
                                            ),
                                            UsernameLabel(
                                              username: q.authorUsername,
                                              style: const TextStyle(
                                                fontSize: AppFontSize.sm,
                                                color: AppColors.textGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Q.${q.number}',
                                      style: const TextStyle(
                                        fontSize: AppFontSize.sm,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TagChip(
                                      label: q.category,
                                      color: categoryColor,
                                    ),
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
                                  icon: const Icon(
                                    Icons.ios_share,
                                    color: AppColors.black,
                                  ),
                                ),
                                _EngagementIcon(
                                  icon: likedQuestion
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  count: feedState.likeCountFor(q),
                                  highlighted: likedQuestion,
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    try {
                                      await ref
                                          .read(
                                            questionFeedControllerProvider
                                                .notifier,
                                          )
                                          .toggleQuestionLike(q);
                                    } catch (_) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('いいねに失敗しました'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                _EngagementIcon(
                                  icon: Icons.mode_comment_outlined,
                                  count: feedState.commentCountFor(q),
                                  onTap: () async {
                                    final posted =
                                        await QuestionCommentsScreen.openFocus(
                                          context,
                                          question: q,
                                          percentA: percentA,
                                          selectedOption: selected,
                                        );
                                    if (posted && context.mounted) {
                                      ref
                                          .read(
                                            questionFeedControllerProvider
                                                .notifier,
                                          )
                                          .incrementCommentCount(q);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 160,
                                ),
                                child: QuestionPosterSection(
                                  question: q,
                                  feedPandaChoice: feedPanda,
                                  pandaExpression: pandaExpression,
                                  commentHint:
                                      CommentActivityHint.shouldShow(
                                        commentCount,
                                      )
                                      ? CommentActivityHint(
                                          commentCount: commentCount,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Hero(
                              tag: answerRatioBarHeroTag(q),
                              child: Material(
                                color: Colors.transparent,
                                child: AnswerRatioBar(
                                  question: q,
                                  percentA: percentA,
                                  selectedOption: selected,
                                  interactive: !_isAnswerFlowLocked,
                                  onSelect: _isAnswerFlowLocked
                                      ? null
                                      : (option) =>
                                            _onAnswer(q, option, total, questions),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _allDiagnosisQuestionsAnswered(QuestionFeedState feedState) {
    for (var n = 1; n <= kDiagnosisQuestionCount; n++) {
      if (feedState.selectedOptionFor(n) == null) return false;
    }
    return true;
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
          widget.onOpenPost != null ? '未解答はありません。二択を投稿してみよう →' : '未解答はありません',
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
                  PandaButton(label: '二択を投稿する', onTap: widget.onOpenPost),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyFeedJump(List<DummyQuestion> questions, int targetNumber) {
    final index = questions.indexWhere((q) => q.number == targetNumber);
    if (index < 0) return;

    _userHasNavigated = true;
    ref.read(questionFeedControllerProvider.notifier).setQuestionIndex(index);

    final controller = _pageController;
    if (controller != null && controller.hasClients) {
      final current = controller.page?.round() ?? 0;
      if (current != index) {
        controller.jumpToPage(index);
      }
    } else {
      _pageController?.dispose();
      _pageController = PageController(initialPage: index);
    }

    ref.read(feedJumpToQuestionNumberProvider.notifier).state = null;
    ref.read(feedWindowControllerProvider.notifier).clearJumpTarget();
    _pendingJumpTarget = null;
  }

  void _schedulePendingFeedJump(List<DummyQuestion> questions) {
    final targetNumber = ref.read(feedJumpToQuestionNumberProvider);
    if (targetNumber == null || questions.isEmpty) return;
    if (_pendingJumpTarget == targetNumber) return;
    _pendingJumpTarget = targetNumber;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final latestTarget = ref.read(feedJumpToQuestionNumberProvider);
      if (latestTarget == null) {
        _pendingJumpTarget = null;
        return;
      }

      final latestQuestions = _orderForTab(_questionsForCurrentTab());
      final index =
          latestQuestions.indexWhere((q) => q.number == latestTarget);
      if (index < 0) {
        _pendingJumpTarget = null;
        return;
      }

      _applyFeedJump(latestQuestions, latestTarget);
      if (mounted) setState(() {});
    });
  }

  void _ensurePageController(
    List<DummyQuestion> questions,
    QuestionFeedState feedState,
  ) {
    if (questions.isEmpty) return;
    if (_pageController != null) return;

    final frontier = _unansweredFrontierIndex(
      questions,
      feedState,
    ).clamp(0, questions.length - 1);
    final initial = _userHasNavigated
        ? feedState.questionIndex.clamp(0, questions.length - 1)
        : frontier;

    _pageController = PageController(initialPage: initial);
    // build 中に StateNotifier を更新しない（Riverpod の制約）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(questionFeedControllerProvider.notifier)
          .setQuestionIndex(initial);
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
                      onChanged: _onFeedTabChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: '更新',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
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
              child: Stack(
                children: [
                  PageView.builder(
                    controller: pageController,
                    scrollDirection: Axis.vertical,
                    physics: total > 1
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: total,
                    onPageChanged: (index) {
                      _userHasNavigated = true;
                      _nextQuestionTimer?.cancel();
                      // 回答後の演出中は onPageChanged で overlay を消さない（rebuild 由来の
                      // ページ通知でアニメが飛ぶのを防ぐ）。手動スワイプ時のみクリア。
                      if (_revealQuestionNumber != null &&
                          !_pendingAdvanceAfterAnswer) {
                        setState(_clearReveal);
                      }
                      final notifier = ref.read(
                        questionFeedControllerProvider.notifier,
                      );
                      final centerNumber = questions[index].number;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        ref
                            .read(questionFeedControllerProvider.notifier)
                            .setQuestionIndex(index);
                        unawaited(notifier.prefetchAround(questions, index));
                        unawaited(
                          ref
                              .read(feedWindowControllerProvider.notifier)
                              .onViewportCenter(centerNumber),
                        );
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildQuestionPage(
                        questions[index],
                        questions,
                        total,
                        feedState,
                      );
                    },
                  ),
                  if (_revealQuestionNumber != null && _revealSnapshot != null)
                    Positioned.fill(
                      child: AbsorbPointer(
                        child: AnswerRevealOverlay(
                        key: ValueKey('reveal-$_revealQuestionNumber'),
                        selectedPercent: _revealSnapshot!.selectedPercent,
                        isMinority: _revealSnapshot!.isMinority,
                        prevOddballScore: _revealSnapshot!.prevOddballScore,
                        newOddballScore: _revealSnapshot!.newOddballScore,
                        oddballBumpLabel: _revealSnapshot!.oddballBumpLabel,
                        mascotAssetPath:
                            FeedPandaChoice.forQuestion(
                              questions.firstWhere(
                                (q) => q.number == _revealQuestionNumber,
                                orElse: () =>
                                    questions[feedState.questionIndex.clamp(
                                      0,
                                      questions.length - 1,
                                    )],
                              ),
                            ).assetPathForExpression(
                              _revealSnapshot!.isMinority
                                  ? 'minority'
                                  : 'majority',
                            ),
                        onFinished: _onRevealFinished,
                        ),
                      ),
                    ),
                ],
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
    if (text.contains('Connection refused') ||
        text.contains('Failed host lookup')) {
      return 'API に接続できません。\n'
          '.env の PANDA_TALK_API_BASE_URL を確認してください。';
    }
    return '質問を読み込めませんでした。\n$text';
  }

  String _questionsSyncKey(List<DummyQuestion> questions) {
    return questions.map((q) => '${q.apiId}:${q.myAnswer ?? ""}').join('|');
  }

  String _feedStructureKey(List<DummyQuestion> questions) {
    return questions.map((q) => q.apiId ?? 'n${q.number}').join('|');
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
        final latestQuestions = _orderForTab(_questionsForCurrentTab());
        final feedState = ref.read(questionFeedControllerProvider);
        notifier.applyServerStats(latestQuestions);

        final snap = _shouldSnapToFrontier(
          latestQuestions,
          structureKey: _feedStructureKey(latestQuestions),
        );
        if (snap && !_pendingAdvanceAfterAnswer && _pageController != null) {
          final frontier = _unansweredFrontierIndex(latestQuestions, feedState);
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
    resetFeedWindowNavigation(ref);
    _lastSyncedQuestionKey = null;
    _lastBuildFeedKey = null;
    _lastBuildStructureKey = null;
    _userHasNavigated = false;
    _pendingAdvanceAfterAnswer = false;
    _lastAnsweredQuestionNumber = null;
    _clearReveal();
    _pageController?.dispose();
    _pageController = null;

    // 診断完了後も unlock 状態が古いと Q1–16 のまま再取得される
    ref.invalidate(diagnosis16UnlockedProvider);
    ref.invalidate(profileControllerProvider);
    ref.invalidate(questionFeedControllerProvider);
    ref.invalidate(feedWindowControllerProvider);
    ref.invalidate(feedBootstrapProvider);

    try {
      await ref.read(profileControllerProvider.future);
      var unlocked = await ref.read(diagnosis16UnlockedProvider.future);
      if (!unlocked) {
        _checkedPendingDiagnosisModal = false;
        await _maybeShowPendingDiagnosisResult();
        unlocked = await ref.read(diagnosis16UnlockedProvider.future);
      }
      await ref.read(feedWindowControllerProvider.future);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    }
  }

  List<DummyQuestion> _questionsForCurrentTab() {
    final notifier = ref.read(feedWindowControllerProvider.notifier);
    return _tabIndex == 1
        ? notifier.displayForHotTab()
        : notifier.displayForDiagnosisTab();
  }

  List<DummyQuestion> _orderForTab(List<DummyQuestion> questions) {
    final ordered = [...questions];
    if (_tabIndex == 1) {
      ordered.sort((a, b) => b.percentA.compareTo(a.percentA));
    }
    return ordered;
  }

  List<DummyQuestion> _filterBlockedAuthors(List<DummyQuestion> questions) {
    final blocked =
        ref.watch(moderationControllerProvider).valueOrNull?.blockedUserIds ??
        const {};
    if (blocked.isEmpty) return questions;
    return questions
        .where(
          (q) =>
              q.authorUserId == null || !blocked.contains(q.authorUserId),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authUserProvider, (previous, next) {
      final wasLoggedOut = previous?.valueOrNull == null;
      final nowLoggedIn = next.valueOrNull != null;
      if (wasLoggedOut && nowLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_presentDiagnosisResultAfterLogin());
        });
      }
    });

    final feedState = ref.watch(questionFeedControllerProvider);
    final bootstrap = ref.watch(feedBootstrapProvider);
    final windowAsync = ref.watch(feedWindowControllerProvider);
    final inDiagnosis16 =
        !(ref.watch(diagnosis16UnlockedProvider).valueOrNull ?? false);

    if (kDebugMode) {
      final bootstrapState = bootstrap.isLoading
          ? 'loading'
          : bootstrap.hasError
          ? 'error'
          : 'data';
      final windowState = windowAsync.isLoading
          ? 'loading'
          : windowAsync.hasError
          ? 'error'
          : 'data';
      debugPrint(
        '[QuestionFeed] bootstrap=$bootstrapState window=$windowState '
        'inDiagnosis16=$inDiagnosis16',
      );
    }

    if (!bootstrap.hasValue && bootstrap.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.softGray,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return windowAsync.when(
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
      data: (_) {
        final feedQuestions = _questionsForCurrentTab();
        if (feedQuestions.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowPendingDiagnosisResult();
          });
          return _buildNoQuestionsEmpty();
        }

        final ordered = _filterBlockedAuthors(_orderForTab(feedQuestions));
        final feedKey = _questionsSyncKey(ordered);
        final structureKey = _feedStructureKey(ordered);
        if (feedKey != _lastBuildFeedKey) {
          final prevStructureKey = _lastBuildStructureKey;
          _lastBuildFeedKey = feedKey;
          _lastBuildStructureKey = structureKey;
          if (prevStructureKey != null &&
              prevStructureKey != structureKey &&
              !_isAnswerFlowLocked) {
            _userHasNavigated = false;
          }
          if (_revealQuestionNumber == null && !_pendingAdvanceAfterAnswer) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_revealQuestionNumber != null || _pendingAdvanceAfterAnswer) {
                return;
              }
              _scheduleFeedSync(ordered);
            });
          }
        }

        if (inDiagnosis16) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowPendingDiagnosisResult();
          });
        }

        final allAnswered =
            !inDiagnosis16 && _feedIsAllAnswered(ordered, feedState);

        if (ref.read(feedJumpToQuestionNumberProvider) != null) {
          _schedulePendingFeedJump(ordered);
        }

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
