import 'package:flutter/material.dart';
import '../core/design_tokens.dart';
import 'panda_avatar.dart';

class MatchUserTile extends StatelessWidget {
  final int rank;
  final String name;
  final int matchRate;
  final VoidCallback? onTap;

  const MatchUserTile({
    super.key,
    required this.rank,
    required this.name,
    required this.matchRate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            PandaAvatar(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            Text(
              '合致度 $matchRate%',
              style: const TextStyle(fontSize: AppFontSize.md, color: AppColors.textGray),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textGray, size: 20),
          ],
        ),
      ),
    );
  }
}
