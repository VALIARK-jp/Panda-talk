import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/personality_axis.dart';

/// 性格軸スコアのバー表示（軸の数は [scores] に依存）。
class PersonalityAxisBars extends StatelessWidget {
  const PersonalityAxisBars({super.key, required this.scores});

  final List<PersonalityAxisScore> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < scores.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _AxisBar(score: scores[i]),
        ],
      ],
    );
  }
}

class _AxisBar extends StatelessWidget {
  const _AxisBar({required this.score});

  final PersonalityAxisScore score;

  @override
  Widget build(BuildContext context) {
    final def = score.definition;
    final firstPct = score.firstPolePercent;
    final secondPct = score.secondPolePercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          def.displayName,
          style: const TextStyle(
            fontSize: AppFontSize.sm,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '$firstPct%',
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
            const Spacer(),
            Text(
              '$secondPct%',
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: firstPct.clamp(1, 100),
                  child: const ColoredBox(color: AppColors.black),
                ),
                Expanded(
                  flex: secondPct.clamp(1, 100),
                  child: const ColoredBox(color: AppColors.borderGray),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              def.firstPoleLabel,
              style: const TextStyle(fontSize: AppFontSize.sm, color: AppColors.black),
            ),
            Text(
              def.secondPoleLabel,
              style: const TextStyle(fontSize: AppFontSize.sm, color: AppColors.textGray),
            ),
          ],
        ),
      ],
    );
  }
}
