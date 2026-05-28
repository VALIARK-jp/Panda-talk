import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_tokens.dart';
import '../presentation/providers/oddball_distribution_providers.dart';
import 'oddball_distribution_chart.dart';

Future<bool> showOddballScorePositionModal(
  BuildContext context, {
  required int score,
  required int answeredCount,
}) async {
  final shouldOpen = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: _OddballScorePositionModalBody(
        score: score,
        answeredCount: answeredCount,
      ),
    ),
  );
  return shouldOpen ?? false;
}

class _OddballScorePositionModalBody extends ConsumerWidget {
  const _OddballScorePositionModalBody({
    required this.score,
    required this.answeredCount,
  });

  final int score;
  final int answeredCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionAsync = ref.watch(oddballDistributionProvider(score));

    void openDetails() => Navigator.of(context).pop(true);

    return GestureDetector(
      onTap: openDetails,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Text(
                    '10問ごとのレポート',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: const Icon(Icons.close, color: AppColors.textGray),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'あなたの異端児スコアは $score%',
              style: const TextStyle(
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'みんなの中での位置はここ！\nタップして詳細を見る',
              style: TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            distributionAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: CircularProgressIndicator(color: AppColors.black),
                ),
              ),
              error: (_, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Text(
                  '分布の取得に失敗しました。タップして詳細画面で再読み込みできます。',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textGray,
                    height: 1.5,
                  ),
                ),
              ),
              data: (distribution) => OddballDistributionChart(
                distribution: distribution,
                compact: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$answeredCount問回答したので更新されました',
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: openDetails,
                child: const Text('詳細を見る'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
