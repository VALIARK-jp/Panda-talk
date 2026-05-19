import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../widgets/panda_avatar.dart';
import '../widgets/panda_button.dart';

enum _OnboardingMode { start, login, signup }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onStartGuest,
    required this.onOpenAuth,
  });

  final VoidCallback onStartGuest;
  final void Function({required bool openSignup}) onOpenAuth;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  _OnboardingMode _mode = _OnboardingMode.start;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            if (_mode != _OnboardingMode.start)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _mode = _OnboardingMode.start),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('戻る'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: AppSpacing.lg),
            const PandaSleep(size: 120),
            const SizedBox(height: AppSpacing.md),
            Image.asset(
              'assets/images/logo.jpg',
              height: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              _title,
              style: const TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _body,
              style: const TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.textGray,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._buildActions(),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '利用規約・プライバシーポリシー',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  String get _title {
    switch (_mode) {
      case _OnboardingMode.login:
        return 'ログイン';
      case _OnboardingMode.signup:
        return '新規登録';
      case _OnboardingMode.start:
        return 'まずはどっち派に答えてみよう。';
    }
  }

  String get _body {
    switch (_mode) {
      case _OnboardingMode.login:
        return '前に使ったアカウントで続きから再開できます。';
      case _OnboardingMode.signup:
        return '回答履歴や合致度を保存して、友達と比べられるようになります。';
      case _OnboardingMode.start:
        return '登録しなくても質問に答えられます。\nみんなの回答比率や少数派判定を見ながら、\n自分のタイプを見つけよう。';
    }
  }

  List<Widget> _buildActions() {
    switch (_mode) {
      case _OnboardingMode.login:
        return [
          PandaButton(
            label: 'ログイン画面へ',
            onTap: () => widget.onOpenAuth(openSignup: false),
          ),
        ];
      case _OnboardingMode.signup:
        return [
          PandaButton(
            label: '新規登録画面へ',
            onTap: () => widget.onOpenAuth(openSignup: true),
          ),
        ];
      case _OnboardingMode.start:
        return [
          PandaButton(label: '始めよう', onTap: widget.onStartGuest),
          const SizedBox(height: AppSpacing.md),
          PandaOutlinedButton(
            label: 'ログイン',
            onTap: () => widget.onOpenAuth(openSignup: false),
          ),
        ];
    }
  }
}
