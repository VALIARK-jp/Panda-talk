import 'package:flutter/material.dart';
import '../core/design_tokens.dart';
import '../widgets/panda_avatar.dart';
import '../widgets/panda_button.dart';
import 'main_app.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              const PandaSleep(size: 160),
              const SizedBox(height: AppSpacing.lg),
              Image.asset('assets/images/logo.jpg', height: 180, fit: BoxFit.contain),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                '白黒つけるほど、仲良くなるSNS。',
                style: TextStyle(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'いろんな「どっち派？」に答えて、\n自分のタイプを見つけよう。\n合う人、真逆な人とつながって、\n新しい友達をつくれるアプリ。',
                style: TextStyle(fontSize: AppFontSize.md, color: AppColors.textGray, height: 1.7),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PandaButton(
                label: 'はじめる',
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainApp())),
              ),
              const SizedBox(height: AppSpacing.md),
              PandaOutlinedButton(
                label: 'ログイン',
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainApp())),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('利用規約・プライバシーポリシー', style: TextStyle(fontSize: AppFontSize.sm, color: AppColors.textGray)),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
