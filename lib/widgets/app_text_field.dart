import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final int maxLines;
  final int? maxLength;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.maxLines = 1,
    this.maxLength,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
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
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: AppFontSize.lg,
            color: AppColors.black,
          ),
          decoration: InputDecoration(
            helperText: helperText,
            errorText: errorText,
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
