import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_tokens.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../widgets/terms_consent_footer.dart';
import '../../widgets/valiark_auth_notice_block.dart';
import 'email_auth_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _logoAssetPath = 'assets/images/logo.jpg';

  bool _authInFlight = false;
  String? _authInFlightProvider;

  void _finishNativeAuth() {
    ref.invalidate(authUserProvider);
    // StreamProvider が 1 フレーム遅れても、AuthGate が currentUser で拾えるよう
    // 次フレームでスタックを畳む。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final loginTopInset = _calculateLoginContentTopInset(
              viewportHeight: constraints.maxHeight,
            );

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.black,
                              ),
                              onPressed: () => Navigator.maybePop(context),
                            ),
                          ),
                          SizedBox(height: loginTopInset),
                          _buildHeroHeader(),
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: _buildLoginButtons(context),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xl,
                          bottom: 4,
                        ),
                        child: _buildFooterSection(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _calculateLoginContentTopInset({required double viewportHeight}) {
    const outerVerticalPadding = 40.0;
    const headerBlockHeightEstimate = 200.0;
    const headerToButtonsGap = 20.0;
    const buttonHeight = 44.0;
    const buttonGap = 12.0;

    final innerViewportHeight = (viewportHeight - outerVerticalPadding).clamp(
      0.0,
      double.infinity,
    );

    final lineCenterFromLoginButtonsTop =
        buttonHeight + buttonGap + buttonHeight / 2;

    final estimatedLineCenterFromTop =
        headerBlockHeightEstimate +
        headerToButtonsGap +
        lineCenterFromLoginButtonsTop;

    final targetCenterY = innerViewportHeight / 2;
    final topInset = targetCenterY - estimatedLineCenterFromTop;

    return topInset.clamp(8.0, 48.0);
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        Image.asset(
          _logoAssetPath,
          width: 160,
          height: 160,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              width: 160,
              height: 160,
              child: Center(
                child: Icon(Icons.pets, size: 72, color: AppColors.black),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          'パンダトーク',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSize.xxl,
            fontWeight: FontWeight.w900,
            color: AppColors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '質問に答えて、タイプや相性を友だちと楽しもう',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w600,
            color: AppColors.textGray,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButtons(BuildContext context) {
    return Column(
      children: [
        _buildAuthButton(
          icon: Icons.email,
          label: 'メールアドレスでログイン',
          color: AppColors.softGray,
          textColor: AppColors.black,
          borderSide: const BorderSide(color: AppColors.borderGray, width: 1),
          providerKey: 'email',
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const EmailAuthScreen(showSignupTab: false),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        _buildAuthButton(
          icon: Icons.chat,
          label: 'LINEでログイン',
          color: const Color(0xFF00C300),
          textColor: Colors.white,
          borderSide: null,
          providerKey: 'line',
          onPressed: () => _signInWithLine(context),
        ),
        const SizedBox(height: AppSpacing.md),
        if (Theme.of(context).platform == TargetPlatform.iOS) ...[
          _buildAuthButton(
            icon: Icons.apple,
            label: 'Appleでログイン',
            color: Colors.black,
            textColor: Colors.white,
            borderSide: null,
            providerKey: 'apple',
            onPressed: () => _signInWithApple(context),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
            );
          },
          child: Text(
            '新規登録はこちら',
            style: TextStyle(
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.black.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ValiarkAuthNoticeBlock(
          onLightBackground: true,
          showCreatedByHeader: true,
        ),
        const SizedBox(height: 16),
        const TermsConsentFooter(onLightBackground: true),
      ],
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    BorderSide? borderSide,
    required String providerKey,
    required VoidCallback onPressed,
  }) {
    final isPressed = _authInFlight && _authInFlightProvider == providerKey;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Opacity(
        opacity: isPressed ? 0.55 : 1,
        child: ElevatedButton(
          onPressed: () {
            if (_authInFlight) return;
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: borderSide ?? BorderSide.none,
            ),
            elevation: borderSide != null ? 0 : 2,
            shadowColor: Colors.black.withValues(alpha: 0.12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithLine(BuildContext context) async {
    try {
      if (mounted) {
        setState(() {
          _authInFlight = true;
          _authInFlightProvider = 'line';
        });
      }

      await ref.read(authServiceProvider).signInWithLine();
      if (!context.mounted) return;
      _finishNativeAuth();
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, _formatError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _authInFlight = false;
          _authInFlightProvider = null;
        });
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      if (mounted) {
        setState(() {
          _authInFlight = true;
          _authInFlightProvider = 'apple';
        });
      }

      await ref.read(authServiceProvider).signInWithApple();
      if (!context.mounted) return;
      _finishNativeAuth();
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, _formatError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _authInFlight = false;
          _authInFlightProvider = null;
        });
      }
    }
  }

  String _formatError(Object e) {
    final s = e.toString();
    return s.replaceFirst('Exception: ', '');
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
