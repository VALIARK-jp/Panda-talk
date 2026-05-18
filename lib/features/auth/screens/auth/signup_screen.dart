import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_tokens.dart';
import '../../../../infrastructure/auth/auth_service.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../widgets/terms_consent_footer.dart';
import '../../widgets/valiark_auth_notice_block.dart';
import 'email_auth_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _finishNativeAuth() {
    ref.invalidate(authUserProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AuthColors.gradientTop, AuthColors.gradientBottom],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.white),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '新規登録',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppFontSize.xxxl - 8,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '登録方法を選択してください',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppFontSize.lg,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl + AppSpacing.md),
                      _buildAuthButton(
                        icon: Icons.email,
                        label: 'メールアドレスで新規登録',
                        color: AuthColors.emailButtonBg,
                        textColor: AuthColors.emailButtonFg,
                        onPressed: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const EmailAuthScreen(showLoginTab: false),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildAuthButton(
                        icon: Icons.g_translate,
                        label: 'Googleで新規登録',
                        color: AppColors.white,
                        textColor: AppColors.black,
                        onPressed: () => _signUpWithGoogle(context),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildAuthButton(
                        icon: Icons.chat,
                        label: 'LINEで新規登録',
                        color: const Color(0xFF00C300),
                        textColor: Colors.white,
                        onPressed: () => _signUpWithLine(context),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                        _buildAuthButton(
                          icon: Icons.apple,
                          label: 'Appleで新規登録',
                          color: Colors.black,
                          textColor: Colors.white,
                          onPressed: () => _signUpWithApple(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      const ValiarkAuthNoticeBlock(
                        onLightBackground: false,
                        showCreatedByHeader: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const TermsConsentFooter(onLightBackground: false),
                      SizedBox(height: MediaQuery.paddingOf(context).bottom),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.25),
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
    );
  }

  Future<void> _signUpWithGoogle(BuildContext context) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      await ref.read(authServiceProvider).signInWithGoogle();

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _signUpWithLine(BuildContext context) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      await ref.read(authServiceProvider).signInWithLine(
            flow: NativeAuthFlow.signup,
          );

      if (context.mounted) Navigator.pop(context);
      if (!context.mounted) return;
      _finishNativeAuth();
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _signUpWithApple(BuildContext context) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      await ref.read(authServiceProvider).signInWithApple(
            flow: NativeAuthFlow.signup,
          );

      if (context.mounted) Navigator.pop(context);
      if (!context.mounted) return;
      _finishNativeAuth();
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
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
