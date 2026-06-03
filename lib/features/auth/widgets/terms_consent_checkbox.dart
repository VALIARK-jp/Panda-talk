import 'package:flutter/material.dart';

import '../../../core/design_tokens.dart';
class TermsConsentCheckbox extends StatelessWidget {
  const TermsConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onLightBackground,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool onLightBackground;

  Color get _body =>
      onLightBackground ? AppColors.textGray : AppColors.white.withValues(alpha: 0.82);

  Color get _title =>
      onLightBackground ? AppColors.black : AppColors.white;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: onLightBackground ? AppColors.black : AppColors.white,
            checkColor: onLightBackground ? AppColors.white : AppColors.black,
            side: BorderSide(
              color: onLightBackground
                  ? AppColors.borderGray
                  : AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  height: 1.45,
                  color: _body,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '利用規約',
                    style: TextStyle(
                      color: _title,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' と '),
                  TextSpan(
                    text: 'プライバシーポリシー',
                    style: TextStyle(
                      color: _title,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: ' に同意します（VALIARK合同会社）',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
