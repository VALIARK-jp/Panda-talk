import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../core/question_stats_utils.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/tag_chip.dart';

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
        ref.read(questionFeedControllerProvider.notifier).applyServerStats(
          questions,
        );
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
                  final filtered = historyQuestions
                      .where((q) => q.myAnswer != null)
                      .toList();

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
                      final selectedPercent = selectedSidePercent(
                        selected: selected,
                        question: q,
                        percentA: percentA,
                      );
                      final isMinority = isMinorityAnswer(
                        selected: selected,
                        question: q,
                        countA: feedState.countAFor(q),
                        countB: feedState.countBFor(q),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const PandaAvatar(size: 20),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '@${q.authorUsername}',
                                              style: const TextStyle(
                                                fontSize: AppFontSize.sm,
                                                color: AppColors.textGray,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Q.${q.number}',
                                        style: const TextStyle(
                                          fontSize: AppFontSize.sm,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        q.text,
                                        style: const TextStyle(
                                          fontSize: AppFontSize.md,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TagChip(label: selected, filled: true),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (isMinority) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.black,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.full,
                                      ),
                                    ),
                                    child: Text(
                                      '少数派 $selectedPercent%',
                                      style: const TextStyle(
                                        fontSize: AppFontSize.sm,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: _MiniRatioBar(
                                    percentA: percentA,
                                    selected: selected,
                                    question: q,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _MiniRatioBar extends StatelessWidget {
  final int percentA;
  final String selected;
  final DummyQuestion question;

  const _MiniRatioBar({
    required this.percentA,
    required this.selected,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final leftPercent = percentA;
    final rightPercent = 100 - percentA;
    final selectedA = selected == question.optionA;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Expanded(
              flex: leftPercent.clamp(1, 99),
              child: Container(
                color: selectedA ? AppColors.black : AppColors.softGray,
              ),
            ),
            Expanded(
              flex: rightPercent.clamp(1, 99),
              child: Container(
                color: !selectedA ? AppColors.black : AppColors.softGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
