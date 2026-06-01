import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/panda_character_assets.dart';
import '../core/panda_type.dart';
import '../core/personality_axis.dart';
import '../core/share_utils.dart';
import 'panda_button.dart';
import 'personality_axis_bars.dart';
import 'share_action_sheet.dart';

/// 16問完了後に「君のキャラはこれ！」を表示するモーダル。
Future<void> showDiagnosis16ResultModal(
  BuildContext context,
  PandaTypeResult result,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (ctx) => _Diagnosis16ResultSheet(result: result),
  );
}

class _Diagnosis16ResultSheet extends StatelessWidget {
  const _Diagnosis16ResultSheet({required this.result});

  final PandaTypeResult result;

  @override
  Widget build(BuildContext context) {
    final imagePath = PandaCharacterAssets.imagePathForSlug(result.slug);
    final axisScores = PersonalityAxisRegistry.scoresFromPandaType(result.scores);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                '君のキャラはこれ！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (imagePath != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.asset(
                      imagePath,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                result.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              if (result.tagline.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSize.md,
                    height: 1.5,
                    color: AppColors.textGray,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'あなたの傾向',
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PersonalityAxisBars(scores: axisScores),
              const SizedBox(height: AppSpacing.lg),
              PandaButton(
                label: '共有しよう！',
                onTap: () => _share(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              PandaOutlinedButton(
                label: '診断を続ける',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _share(BuildContext context) {
    // 数値列ではなく「人格をネタ化」。詳細は [docs/18_share_growth_spec.md] §3-2。
    showShareActionSheet(
      context,
      payload: SharePayload.diagnosis(result: result),
    );
  }
}
