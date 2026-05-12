import 'package:flutter/material.dart';
import '../core/design_tokens.dart';
import '../widgets/panda_avatar.dart';
import '../widgets/panda_button.dart';
import 'main_app.dart';

enum _OnboardingMode { start, login, signup }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  _OnboardingMode _mode = _OnboardingMode.start;

  void _enterApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainApp()),
    );
  }

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
                child: IconButton(
                  onPressed: () =>
                      setState(() => _mode = _OnboardingMode.start),
                  icon: const Icon(Icons.arrow_back, color: AppColors.black),
                ),
              )
            else
              const SizedBox(height: AppSpacing.lg),
            const PandaSleep(size: 120),
            const SizedBox(height: AppSpacing.md),
            Image.asset(
              'assets/images/logo.jpg',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'パンダトーク',
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
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
          PandaButton(label: 'Googleでログイン', onTap: _enterApp),
          const SizedBox(height: AppSpacing.md),
          PandaOutlinedButton(label: 'Appleでログイン', onTap: _enterApp),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => setState(() => _mode = _OnboardingMode.signup),
            child: const Text(
              '新規登録はこちら',
              style: TextStyle(
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
          ),
        ];
      case _OnboardingMode.signup:
        return [
          PandaButton(label: 'Googleで新規登録', onTap: _enterApp),
          const SizedBox(height: AppSpacing.md),
          PandaOutlinedButton(label: 'Appleで新規登録', onTap: _enterApp),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => setState(() => _mode = _OnboardingMode.login),
            child: const Text(
              'ログインはこちら',
              style: TextStyle(
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
          ),
        ];
      case _OnboardingMode.start:
        return [
          PandaButton(label: '始めよう', onTap: _enterApp),
          const SizedBox(height: AppSpacing.md),
          PandaOutlinedButton(
            label: 'ログイン',
            onTap: () => setState(() => _mode = _OnboardingMode.login),
          ),
        ];
    }
  }
}
