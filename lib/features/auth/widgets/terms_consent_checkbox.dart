import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../core/design_tokens.dart';
import 'legal_url_launcher.dart';

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
          child: _TermsConsentLabel(
            bodyColor: _body,
            linkColor: _title,
            onToggle: () => onChanged(!value),
          ),
        ),
      ],
    );
  }
}

class _TermsConsentLabel extends StatefulWidget {
  const _TermsConsentLabel({
    required this.bodyColor,
    required this.linkColor,
    required this.onToggle,
  });

  final Color bodyColor;
  final Color linkColor;
  final VoidCallback onToggle;

  @override
  State<_TermsConsentLabel> createState() => _TermsConsentLabelState();
}

class _TermsConsentLabelState extends State<_TermsConsentLabel> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _bodyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => openLegalUrl(
            context,
            AppConfig.termsOfServiceUrl,
            '利用規約',
          );
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => openLegalUrl(
            context,
            AppConfig.privacyPolicyUrl,
            'プライバシーポリシー',
          );
    _bodyRecognizer = TapGestureRecognizer()..onTap = widget.onToggle;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _bodyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: widget.linkColor,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: AppFontSize.sm,
          height: 1.45,
          color: widget.bodyColor,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: '利用規約', style: linkStyle, recognizer: _termsRecognizer),
          const TextSpan(text: ' と '),
          TextSpan(
            text: 'プライバシーポリシー',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          TextSpan(
            text: ' に同意します（VALIARK合同会社）',
            recognizer: _bodyRecognizer,
          ),
        ],
      ),
    );
  }
}
