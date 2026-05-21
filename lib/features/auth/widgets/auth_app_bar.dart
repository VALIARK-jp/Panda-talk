import 'package:flutter/material.dart';

import '../../../core/design_tokens.dart';

/// 認証系の黒 AppBar（グローバル [AppBarTheme] の黒アイコンを白で上書き）。
class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuthAppBar({
    super.key,
    required this.title,
    this.bottom,
  });

  final String title;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: AppColors.white,
        tooltip: '戻る',
        onPressed: () => Navigator.maybePop(context),
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
      foregroundColor: AppColors.white,
      title: Text(title),
      centerTitle: true,
      backgroundColor: AuthColors.chrome,
      elevation: 0,
      bottom: bottom,
    );
  }
}

/// フォーム内の戻る（AppBar 下の予備。暗い背景では [onDark]）。
class AuthFormBackButton extends StatelessWidget {
  const AuthFormBackButton({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? AppColors.white : AppColors.black;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => Navigator.maybePop(context),
        icon: Icon(Icons.arrow_back, size: 20, color: fg),
        label: Text(
          '戻る',
          style: TextStyle(
            fontSize: AppFontSize.md,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
