import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../widgets/panda_avatar.dart';
import '../widgets/panda_button.dart';

/// ログイン直後の初回のみ（端末に保存）。メインタブへ進む前のささやかな導入。
class PostLoginWelcomeScreen extends StatelessWidget {
  const PostLoginWelcomeScreen({
    super.key,
    required this.onContinue,
  });

  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xl),
            const Center(child: PandaSleep(size: 100)),
            const SizedBox(height: AppSpacing.lg),
            Image.asset(
              'assets/images/logo.jpg',
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'ようこそ、パンダトークへ',
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'ログインありがとうございます。\n'
              '診断に答えたり、マッチやトークで仲良くなったり——\n'
              '白黒つけるほど、仲良くなるSNSを楽しんでください。',
              style: TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.textGray,
                height: 1.65,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl + AppSpacing.md),
            PandaButton(
              label: 'アプリに入る',
              onTap: () => onContinue(),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
          ],
        ),
      ),
    );
  }
}
