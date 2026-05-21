import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/dummy_data.dart';
import '../core/panda_character_assets.dart';
import '../core/panda_type_profile.dart';
import 'speech_bubble.dart';

class PandaTypeProfileSection extends StatelessWidget {
  const PandaTypeProfileSection({
    super.key,
    required this.profile,
    this.bio,
  });

  final DummyProfile profile;

  /// 同一枠内に表示する自己紹介（未設定時はプレースホルダー）。
  final String? bio;

  @override
  Widget build(BuildContext context) {
    final result = profile.pandaTypeResult;
    if (result == null) return const SizedBox.shrink();

    final imagePath = PandaCharacterAssets.imagePathForSlug(result.slug);
    final bioText = bio?.trim() ?? profile.bio.trim();
    final displayBio =
        bioText.isEmpty ? 'まだ自己紹介がありません' : bioText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: AppColors.softGray,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.asset(
                        imagePath,
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    const SizedBox(width: 72, height: 72),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '16type',
                          style: TextStyle(
                            fontSize: AppFontSize.sm,
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.displayName,
                          style: const TextStyle(
                            fontSize: AppFontSize.lg,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                            height: 1.2,
                          ),
                        ),
                        if (result.tagline.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            result.tagline,
                            style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              height: 1.35,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SpeechBubble(
                text: displayBio,
                variant: SpeechBubbleVariant.light,
                tail: SpeechBubbleTail.bottomLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                textStyle: TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600,
                  color: bioText.isEmpty
                      ? AppColors.textGray
                      : AppColors.black,
                  height: 1.4,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
