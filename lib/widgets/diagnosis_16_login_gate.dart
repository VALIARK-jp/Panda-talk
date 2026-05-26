import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_tokens.dart';
import '../features/auth/screens/auth/login_screen.dart';
import '../features/auth/screens/auth/signup_screen.dart';
import 'panda_avatar.dart';
import 'panda_button.dart';

/// 16問完了後（未ログイン）に診断結果を見るためのログイン誘導。閉じられない。
Future<void> showDiagnosis16LoginGate(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const Diagnosis16LoginGateScreen(),
    ),
  );
}

class Diagnosis16LoginGateScreen extends ConsumerWidget {
  const Diagnosis16LoginGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const PandaAvatar(size: 120),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'ログインして\n診断結果を見よう！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppFontSize.xxl,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  '16問の回答はこの端末に保存済みです。\n'
                  'ログインすると、あなたのパンダタイプが表示されます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    color: AppColors.textGray,
                    height: 1.55,
                  ),
                ),
                const Spacer(flex: 3),
                PandaButton(
                  label: 'ログインして結果を見る',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const SignupScreen(),
                    ),
                  ),
                  child: const Text(
                    'はじめての方は新規登録',
                    style: TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
