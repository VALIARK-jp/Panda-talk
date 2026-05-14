import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/guest_login_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/tag_chip.dart';
import 'question_comments_screen.dart';
import 'question_history_screen.dart';

class QuestionFeedScreen extends ConsumerStatefulWidget {
  const QuestionFeedScreen({super.key});

  @override
  ConsumerState<QuestionFeedScreen> createState() => _QuestionFeedScreenState();
}

class _QuestionFeedScreenState extends ConsumerState<QuestionFeedScreen> {
  int _tabIndex = 0; // 0=診断 1=Hot
  final bool _isGuest = true; // ゲストモードフラグ（ダミー）
  final _pageController = PageController();
  Timer? _nextQuestionTimer;

  static const _nudgeMessages = {
    10: '10問答えたね！\n登録すると合致度が見られるよ。',
    20: 'あなたと合う人、\nもう見つかってるかも。',
    30: '異端児スコアが本格的になってきた。\n記録しておこう。',
  };

  @override
  void dispose() {
    _nextQuestionTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onAnswer(DummyQuestion q, String selected, int total) async {
    final controller = ref.read(questionFeedControllerProvider.notifier);
    if (ref.read(questionFeedControllerProvider).selectedOptionFor(q.number) !=
        null) {
      return;
    }
    await controller.answer(q, selected);
    if (!mounted) return;

    _nextQuestionTimer?.cancel();
    _nextQuestionTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      final answeredCount = ref
          .read(questionFeedControllerProvider)
          .answeredCount;
      _goToNextQuestion(total);
      if (_isGuest && _nudgeMessages.containsKey(answeredCount)) {
        _showNudgeModal(answeredCount);
      }
    });
  }

  void _goToNextQuestion(int total) {
    _nextQuestionTimer?.cancel();
    final currentIndex = ref.read(questionFeedControllerProvider).questionIndex;
    final nextIndex = (currentIndex + 1) % total;
    _animateToQuestion(nextIndex);
  }

  void _handleManualSwipe(
    DragEndDetails details,
    List<DummyQuestion> questions,
    QuestionFeedState feedState,
  ) {
    final velocity = details.primaryVelocity;
    if (velocity == null) return;

    final total = questions.length;
    final currentIndex = feedState.questionIndex % total;
    final currentQuestion = questions[currentIndex];
    final currentAnswered =
        feedState.selectedOptionFor(currentQuestion.number) != null ||
        currentQuestion.myAnswer != null;

    if (velocity < -200) {
      if (currentAnswered) _goToNextQuestion(total);
      return;
    }

    if (velocity > 200) {
      for (var index = currentIndex - 1; index >= 0; index--) {
        final question = questions[index];
        if (feedState.selectedOptionFor(question.number) != null ||
            question.myAnswer != null) {
          _nextQuestionTimer?.cancel();
          _animateToQuestion(index);
          return;
        }
      }
    }
  }

  void _animateToQuestion(int index) {
    if (!_pageController.hasClients) {
      ref.read(questionFeedControllerProvider.notifier).setQuestionIndex(index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _showNudgeModal(int count) {
    final message = _nudgeMessages[count]!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NudgeCard(message: message),
    );
  }

  Widget _buildQuestionPage(
    DummyQuestion q,
    List<DummyQuestion> questions,
    int total,
    QuestionFeedState feedState,
  ) {
    final selected = feedState.selectedOptionFor(q.number) ?? q.myAnswer;
    final hasAnswered = selected != null;
    final percentA = feedState.percentAFor(q);
    final selectedA = selected == q.optionA;
    final selectedPercent = selectedA ? percentA : (100 - percentA);
    final isMinority = hasAnswered && selectedPercent < 50;
    final oddballScore = feedState.answeredCount > 0
        ? (feedState.minorityCount / feedState.answeredCount * 100).round()
        : 0;
    final likedQuestion = feedState.likedQuestionNumbers.contains(q.number);

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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
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
                    onPressed: () => ref
                        .read(questionFeedControllerProvider.notifier)
                        .toggleQuestionLike(q.number),
                    icon: Icon(
                      likedQuestion ? Icons.favorite : Icons.favorite_border,
                      color: AppColors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuestionCommentsScreen(question: q),
                      ),
                    ),
                    icon: const Icon(
                      Icons.mode_comment_outlined,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: hasAnswered
                    ? Column(
                        key: ValueKey('result-${q.number}'),
                        children: [
                          const Text(
                            'あなたは...',
                            style: TextStyle(
                              fontSize: AppFontSize.lg,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '$selected！',
                            style: const TextStyle(
                              fontSize: AppFontSize.xxxl,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMinority
                                  ? AppColors.black
                                  : AppColors.softGray,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              '${isMinority ? '少数派' : '多数派'} $selectedPercent%',
                              style: TextStyle(
                                fontSize: AppFontSize.sm,
                                fontWeight: FontWeight.w800,
                                color: isMinority
                                    ? AppColors.white
                                    : AppColors.black,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        key: ValueKey('question-${q.number}'),
                        children: [
                          PandaMascot(size: 72),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            q.text,
                            style: const TextStyle(
                              fontSize: AppFontSize.xl,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
              const Spacer(),
              SizedBox(
                height: 118,
                child: AnimatedOpacity(
                  opacity: hasAnswered ? 1 : 0,
                  duration: const Duration(milliseconds: 240),
                  child: hasAnswered
                      ? _OddballScoreCard(
                          key: ValueKey('score-${q.number}'),
                          score: oddballScore,
                          answeredCount: feedState.answeredCount,
                          minorityCount: feedState.minorityCount,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _AnswerRatioBar(
                question: q,
                percentA: percentA,
                selectedOption: selected,
                onSelect: (option) => _onAnswer(q, option, total),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(
    List<DummyQuestion> questions,
    QuestionFeedState feedState,
  ) {
    final total = questions.length;
    final showingAnsweredHistory =
        questions.isNotEmpty && questions.every((q) => q.myAnswer != null);
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
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(0);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
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
            if (showingAnsweredHistory)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: const Text(
                  '未回答の質問はありません',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragEnd: (details) =>
                    _handleManualSwipe(details, questions, feedState),
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: total,
                  onPageChanged: (index) {
                    _nextQuestionTimer?.cancel();
                    ref
                        .read(questionFeedControllerProvider.notifier)
                        .setQuestionIndex(index);
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(feedQuestionsProvider);
    final feedState = ref.watch(questionFeedControllerProvider);
    return questionsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('エラー: $e'))),
      data: (questions) {
        if (questions.isEmpty) {
          return const Scaffold(body: Center(child: Text('まだ表示できる質問がありません')));
        }
        final orderedQuestions = [...questions];
        if (_tabIndex == 1) {
          orderedQuestions.sort((a, b) => b.percentA.compareTo(a.percentA));
        }
        return _buildScreen(orderedQuestions, feedState);
      },
    );
  }
}

class _AnswerRatioBar extends StatelessWidget {
  final DummyQuestion question;
  final int percentA;
  final String? selectedOption;
  final ValueChanged<String> onSelect;

  const _AnswerRatioBar({
    required this.question,
    required this.percentA,
    required this.selectedOption,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnswered = selectedOption != null;
    final leftPercent = hasAnswered ? percentA : 50;
    final rightPercent = hasAnswered ? 100 - percentA : 50;
    final selectedA = selectedOption == question.optionA;
    final selectedB = selectedOption == question.optionB;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedOpacity(
          opacity: hasAnswered ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Text(
            'みんなの回答',
            style: TextStyle(
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: 64,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: hasAnswered
                            ? null
                            : () => onSelect(question.optionA),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          width: width * leftPercent / 100,
                          color: AppColors.white,
                          alignment: Alignment.center,
                          child: _RatioLabel(
                            label: hasAnswered
                                ? '${question.optionA} $leftPercent%'
                                : question.optionA,
                            selected: selectedA,
                            dark: false,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: hasAnswered
                            ? null
                            : () => onSelect(question.optionB),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          width: width * rightPercent / 100,
                          color: AppColors.black,
                          alignment: Alignment.center,
                          child: _RatioLabel(
                            label: hasAnswered
                                ? '${question.optionB} $rightPercent%'
                                : question.optionB,
                            selected: selectedB,
                            dark: true,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatioLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dark;

  const _RatioLabel({
    required this.label,
    required this.selected,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(
                Icons.check_circle,
                size: 16,
                color: dark ? AppColors.white : AppColors.black,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w800,
                color: dark ? AppColors.white : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OddballScoreCard extends StatelessWidget {
  final int score;
  final int answeredCount;
  final int minorityCount;

  const _OddballScoreCard({
    super.key,
    required this.score,
    required this.answeredCount,
    required this.minorityCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'あなたの異端児スコア',
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              Text(
                '$score%',
                style: const TextStyle(
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 10,
              backgroundColor: AppColors.borderGray,
              valueColor: const AlwaysStoppedAnimation(AppColors.black),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '凡人',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textGray,
                ),
              ),
              Text(
                '$answeredCount問中$minorityCount問で少数派',
                style: const TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textGray,
                ),
              ),
              const Text(
                '異端児',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
          // ハンドル
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
