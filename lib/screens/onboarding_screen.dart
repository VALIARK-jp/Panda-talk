import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../core/design_tokens.dart';
import '../features/auth/widgets/valiark_auth_notice_block.dart';
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
            _buildLegalLinks(),
            const SizedBox(height: AppSpacing.lg),
            const ValiarkAuthNoticeBlock(
              onLightBackground: true,
              compact: true,
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

  Widget _buildLegalLinks() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        _buildLegalLink(label: '利用規約', url: AppConfig.termsOfServiceUrl),
        const Text(
          '・',
          style: TextStyle(fontSize: AppFontSize.sm, color: AppColors.textGray),
        ),
        _buildLegalLink(label: 'プライバシーポリシー', url: AppConfig.privacyPolicyUrl),
      ],
    );
  }

  Widget _buildLegalLink({required String label, required String url}) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.textGray,
      ),
      onPressed: () => _openUrl(url, label),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppFontSize.sm,
          color: AppColors.textGray,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _openUrl(String url, String label) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('$label の掲載準備中です。')));
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('リンク URL が未設定または不正です。')));
      return;
    }

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('ブラウザを開けませんでした')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('ブラウザを開けませんでした: $e')));
    }
  }
}
