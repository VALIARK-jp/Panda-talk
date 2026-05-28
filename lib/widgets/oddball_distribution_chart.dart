import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/oddball_distribution.dart';

class OddballDistributionChart extends StatelessWidget {
  const OddballDistributionChart({
    super.key,
    required this.distribution,
    this.compact = false,
  });

  final OddballScoreDistribution distribution;
  final bool compact;

  static const _palette = <Color>[
    Color(0xFFE85D9E),
    Color(0xFF8E5BE8),
    Color(0xFF3478F6),
    Color(0xFF14B8A6),
    Color(0xFF28A86B),
    Color(0xFFE0A800),
    Color(0xFFFF8A3D),
    Color(0xFFEF4444),
    Color(0xFF0D9488),
    Color(0xFF6B7280),
  ];

  @override
  Widget build(BuildContext context) {
    final bins = distribution.bins;
    if (bins.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCount = bins.fold<int>(1, (max, bin) => bin.count > max ? bin.count : max);
    final highlightedIndex = distribution.highlightedBinIndex;
    final chartHeight = compact ? 120.0 : 168.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < bins.length; i++) ...[
                Expanded(
                  child: _DistributionBar(
                    color: _palette[i % _palette.length],
                    bin: bins[i],
                    isHighlighted: i == highlightedIndex,
                    maxCount: maxCount,
                    compact: compact,
                  ),
                ),
                if (i != bins.length - 1) SizedBox(width: compact ? 4 : 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Text(
              '0%',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textGray,
              ),
            ),
            const Spacer(),
            Text(
              'あなたの位置: ${distribution.score}%',
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const Spacer(),
            const Text(
              '100%',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.color,
    required this.bin,
    required this.isHighlighted,
    required this.maxCount,
    required this.compact,
  });

  final Color color;
  final OddballDistributionBin bin;
  final bool isHighlighted;
  final int maxCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount == 0 ? 0.0 : (bin.count / maxCount).clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isHighlighted)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Text(
              'あなた',
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          const SizedBox(height: 30),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              height: (compact ? 76.0 : 110.0) * ratio + 14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.72),
                    color,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isHighlighted ? AppColors.black : color.withValues(alpha: 0.35),
                  width: isHighlighted ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isHighlighted ? 0.28 : 0.14),
                    blurRadius: isHighlighted ? 16 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  '${bin.count}',
                  style: TextStyle(
                    fontSize: compact ? 10 : AppFontSize.sm,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bin.start == 90 ? '90+' : '${bin.start}',
          style: TextStyle(
            fontSize: compact ? 10 : AppFontSize.sm,
            color: isHighlighted ? AppColors.black : AppColors.textGray,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
