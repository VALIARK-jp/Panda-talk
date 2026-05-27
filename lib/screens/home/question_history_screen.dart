import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/category_poster_copy.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../core/question_stats_utils.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/user_avatar.dart';

class QuestionHistoryScreen extends ConsumerStatefulWidget {
  const QuestionHistoryScreen({super.key});

  @override
  ConsumerState<QuestionHistoryScreen> createState() =>
      _QuestionHistoryScreenState();
}

class _QuestionHistoryScreenState extends ConsumerState<QuestionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(questionHistoryProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<DummyQuestion>>>(questionHistoryProvider, (
      _,
      next,
    ) {
      next.whenData((questions) {
        ref
            .read(questionFeedControllerProvider.notifier)
            .applyServerStats(questions);
        Future.microtask(
          () => ref
              .read(questionFeedControllerProvider.notifier)
              .refreshAnsweredStats(questions),
        );
      });
    });

    final historyAsync = ref.watch(questionHistoryProvider);
    final feedState = ref.watch(questionFeedControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.black),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'あなたの履歴',
                    style: TextStyle(
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (historyQuestions) {
                  final filtered =
                      historyQuestions.where((q) => q.myAnswer != null).toList()
                        ..sort((a, b) => a.number.compareTo(b.number));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final q = filtered[i];
                      final selected =
                          feedState.selectedOptionFor(q.number) ?? q.myAnswer!;
                      final percentA = feedState.percentAFor(q);
                      final isMinority = isMinorityAnswer(
                        selected: selected,
                        question: q,
                        countA: feedState.countAFor(q),
                        countB: feedState.countBFor(q),
                      );

                      final categoryColor = categoryAccentColor(q.category);

                      return GestureDetector(
                        onTap: () async {
                          await openQuestionInFeed(
                            ref,
                            questionNumber: q.number,
                            questionId: q.apiId,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: 0.45),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 6,
                                      color: categoryColor,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    22,
                                    14,
                                    16,
                                    14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _CategoryPill(
                                            label: q.category,
                                            color: categoryColor,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          UserAvatar(
                                            size: 20,
                                            imageUrl: q.authorAvatarUrl,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Q.${q.number}  @${q.authorUsername}',
                                              style: const TextStyle(
                                                fontSize: AppFontSize.sm,
                                                color: AppColors.textGray,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        q.text,
                                        style: const TextStyle(
                                          fontSize: AppFontSize.md,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.black,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _HistoryPositionBar(
                                        question: q,
                                        selected: selected,
                                        percentA: percentA,
                                        isMinority: isMinority,
                                        categoryColor: categoryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

class _HistoryPositionBar extends StatelessWidget {
  final int percentA;
  final String selected;
  final DummyQuestion question;
  final bool isMinority;
  final Color categoryColor;

  const _HistoryPositionBar({
    required this.percentA,
    required this.selected,
    required this.question,
    required this.isMinority,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final selectedA = selected == question.optionA;
    final selectedPercent = selectedA ? percentA : 100 - percentA;
    final resultLabel = isMinority ? '少数派' : '多数派';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fillWidth = width * selectedPercent.clamp(0, 100) / 100;
        final fillLeft = selectedA ? 0.0 : width - fillWidth;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.optionA,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: selectedA ? FontWeight.w900 : FontWeight.w700,
                      color: selectedA ? AppColors.black : AppColors.textGray,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.optionB,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: !selectedA
                          ? FontWeight.w900
                          : FontWeight.w700,
                      color: !selectedA ? AppColors.black : AppColors.textGray,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: selectedA
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: _YouResultBubble(
                percent: selectedPercent,
                resultLabel: resultLabel,
                isMinority: isMinority,
                color: categoryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.softGray,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.borderGray),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  Positioned(
                    left: fillLeft.clamp(0.0, width),
                    width: fillWidth.clamp(4.0, width),
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: categoryColor,
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.28),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 2,
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _YouResultBubble extends StatelessWidget {
  final int percent;
  final String resultLabel;
  final bool isMinority;
  final Color color;

  const _YouResultBubble({
    required this.percent,
    required this.resultLabel,
    required this.isMinority,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '${isMinority ? '⚡' : '✓'} あなたは$percent%の$resultLabel',
        softWrap: true,
        style: TextStyle(
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}
