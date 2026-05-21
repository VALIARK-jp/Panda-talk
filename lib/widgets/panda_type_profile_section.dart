import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/dummy_data.dart';
import '../core/panda_character_assets.dart';
import '../core/panda_type_profile.dart';
import '../core/personality_axis.dart';
import 'personality_axis_bars.dart';

class PandaTypeProfileSection extends StatelessWidget {
  const PandaTypeProfileSection({super.key, required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final result = profile.pandaTypeResult;
    if (result == null) return const SizedBox.shrink();

    final imagePath = PandaCharacterAssets.imagePathForSlug(result.slug);
    final axisScores = PersonalityAxisRegistry.scoresFromPandaType(result.scores);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.softGray,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '16type',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textGray,
                ),
              ),
              if (imagePath != null) ...[
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.asset(
                    imagePath,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                result.displayName,
                style: const TextStyle(
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              if (result.tagline.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  result.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    height: 1.4,
                    color: AppColors.textGray,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: PersonalityAxisBars(scores: axisScores),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
