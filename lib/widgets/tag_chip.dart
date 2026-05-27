import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class TagChip extends StatelessWidget {
  final String label;
  final bool filled;
  final Color? color;

  const TagChip({
    super.key,
    required this.label,
    this.filled = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color;
    final backgroundColor = filled
        ? (accentColor ?? AppColors.black)
        : (accentColor?.withValues(alpha: 0.12) ?? AppColors.softGray);
    final foregroundColor = filled
        ? AppColors.white
        : (accentColor ?? AppColors.black);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: accentColor == null || filled
            ? null
            : Border.all(color: accentColor.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.sm,
          color: foregroundColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
