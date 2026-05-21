import 'package:flutter/material.dart';

import '../core/personality_axis.dart';
import 'tag_chip.dart';

/// 4軸の過半数側を「刺激 61%」形式のチップで並べる。
class PersonalityTendencyChips extends StatelessWidget {
  const PersonalityTendencyChips({super.key, required this.scores});

  final List<PersonalityAxisScore> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final score in scores)
          TagChip(
            label: '${score.majorityPoleLabel} ${score.majorityPolePercent}%',
            filled: true,
          ),
      ],
    );
  }
}
