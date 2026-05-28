import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/username_rules.dart';

/// `@username` 表示。長いレガシー値でもレイアウトがはみ出さないようにする。
class UsernameLabel extends StatelessWidget {
  const UsernameLabel({
    super.key,
    required this.username,
    this.style,
    this.textAlign,
    this.maxLines = 1,
  });

  final String username;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      '@${UsernameRules.normalize(username)}',
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: style ??
          const TextStyle(
            fontSize: AppFontSize.md,
            color: AppColors.textGray,
          ),
    );

    if (textAlign == TextAlign.center) {
      return SizedBox(width: double.infinity, child: label);
    }

    return label;
  }
}
