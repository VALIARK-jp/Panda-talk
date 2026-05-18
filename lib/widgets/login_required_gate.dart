import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../features/auth/screens/auth/login_screen.dart';
import '../features/auth/screens/auth/signup_screen.dart';
import 'panda_avatar.dart';
import 'panda_button.dart';

/// 未ログイン（ゲスト）向け。タブ本体の代わりにモーダル風カードを表示する。
class LoginRequiredGate extends StatelessWidget {
  const LoginRequiredGate({
    super.key,
    required this.featureLabel,
  });

  final String featureLabel;

  void _openLogin(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  void _openSignup(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.softGray,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Material(
              color: AppColors.white,
              elevation: 8,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PandaSleep(size: 72),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'ログインしてこの機能を\n解放しよう',
                      style: TextStyle(
                        fontSize: AppFontSize.xl,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$featureLabelはアカウント登録後に使えます。\n'
                      '診断はこのまま続けられます。',
                      style: const TextStyle(
                        fontSize: AppFontSize.md,
                        color: AppColors.textGray,
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PandaButton(
                      label: 'ログイン',
                      onTap: () => _openLogin(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PandaOutlinedButton(
                      label: '新規登録',
                      onTap: () => _openSignup(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
