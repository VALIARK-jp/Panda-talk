import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final String? hintText;
  final int maxLines;
  final int? maxLength;
  final TextEditingController? controller;

  const AppTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSize.md,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(
            fontSize: AppFontSize.lg,
            color: AppColors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: AppFontSize.lg,
              color: AppColors.textGray,
            ),
            filled: true,
            fillColor: AppColors.softGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
