import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../presentation/providers/oddball_distribution_providers.dart';
import '../../widgets/oddball_distribution_chart.dart';

class OddballScorePositionScreen extends ConsumerWidget {
  const OddballScorePositionScreen({
    super.key,
    required this.score,
    required this.answeredCount,
  });

  final int score;
  final int answeredCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionAsync = ref.watch(oddballDistributionProvider(score));
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.black),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'あなたの立ち位置',
                      style: TextStyle(
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'あなたの異端児スコア',
                      style: TextStyle(
                        fontSize: AppFontSize.md,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$score%',
                      style: const TextStyle(
                        fontSize: AppFontSize.xxxl,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$answeredCount問回答した時点での立ち位置です。',
                      style: const TextStyle(
                        fontSize: AppFontSize.md,
                        color: AppColors.textGray,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: distributionAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.black),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      '分布を読み込めませんでした\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (distribution) => SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'みんなの異端児スコア分布',
                            style: TextStyle(
                              fontSize: AppFontSize.lg,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '回答者 ${distribution.totalUsers}人中、あなたは下から ${distribution.percentile}% 地点です。',
                            style: const TextStyle(
                              fontSize: AppFontSize.md,
                              color: AppColors.textGray,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OddballDistributionChart(distribution: distribution),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
