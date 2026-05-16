import 'package:flutter/material.dart';

class AppColors {
  static const black = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);
  static const softGray = Color(0xFFF5F5F5);
  static const borderGray = Color(0xFFE5E5E5);
  static const textGray = Color(0xFF777777);
}

class AppRadius {
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const full = 100.0;
}

class AppSpacing {
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppFontSize {
  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const xxxl = 40.0;
}

/// ログイン・登録フロー（メール / LINE / Apple のボタン配置など）用。パンダトークの白黒ベース。
class AuthColors {
  static const gradientTop = Color(0xFF4A4A4A);
  static const gradientBottom = AppColors.black;

  /// メールでログイン／登録（白ボタン＋黒ラベル）
  static const emailButtonBg = AppColors.white;
  static const emailButtonFg = AppColors.black;

  /// フォーム画面の AppBar・主ボタン
  static const chrome = AppColors.black;
  static const formScaffoldBg = AppColors.softGray;
  static const bodyText = AppColors.black;
  static const mutedOnForm = AppColors.textGray;
}
