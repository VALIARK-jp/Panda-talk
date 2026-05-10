import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class TagChip extends StatelessWidget {
  final String label;
  final bool filled;

  const TagChip({super.key, required this.label, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? AppColors.black : AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.sm,
          color: filled ? AppColors.white : AppColors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
