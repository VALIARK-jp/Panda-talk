import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_tokens.dart';
import '../../../../infrastructure/auth/auth_service.dart';
import '../../../../infrastructure/post_auth_flow.dart';
import '../../widgets/auth_app_bar.dart';

/// サインアップ確認メール送付後。メール内リンク（PKCE）でセッションが付いたらルートまで戻す。
class EmailSentScreen extends ConsumerStatefulWidget {
  const EmailSentScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailSentScreen> createState() => _EmailSentScreenState();
}

class _EmailSentScreenState extends ConsumerState<EmailSentScreen>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isResending = false;
  bool _resendSuccess = false;
  bool _poppedToRoot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.userUpdated:
          _popToRootIfSession();
          break;
        default:
          break;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _popToRootIfSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _popToRootIfSession();
    }
  }

  Future<void> _popToRootIfSession() async {
    if (_poppedToRoot || !mounted) return;
    if (Supabase.instance.client.auth.currentSession == null) return;
    _poppedToRoot = true;
    await PostAuthFlow.withLoading(context, () async {
      await PostAuthFlow.finishLogin(context: context);
    });
  }

  Future<void> _resend() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _resendSuccess = false;
    });
    try {
      await AuthService().resendEmailVerification();
      if (mounted) {
        setState(() => _resendSuccess = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('再送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.formScaffoldBg,
      appBar: const AuthAppBar(title: 'メール確認'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AuthFormBackButton(),
              const SizedBox(height: AppSpacing.md),
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AuthColors.chrome,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '確認メールを送信しました',
                style: TextStyle(
                  fontSize: AppFontSize.xl + 2,
                  fontWeight: FontWeight.w800,
                  color: AuthColors.bodyText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: AppFontSize.md + 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'に確認メールを送りました。\nメール内のリンクを開くと、パンダトークに戻ってそのまま続けられます。',
                style: TextStyle(
                  fontSize: AppFontSize.md,
                  height: 1.5,
                  color: AuthColors.mutedOnForm,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isResending ? null : _resend,
                  icon: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isResending ? '送信中...' : 'メールを再送信する'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AuthColors.chrome,
                    side: const BorderSide(color: AppColors.black, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              if (_resendSuccess) ...[
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'メールを再送信しました',
                      style: TextStyle(color: Colors.green, fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'メールが届かない場合',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: AppFontSize.md,
                        color: AuthColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '• 迷惑メール（スパム）フォルダをご確認ください\n'
                      '• プロモーションフォルダ（Gmail）をご確認ください\n'
                      '• メールアドレスに間違いがないか確認してください\n'
                      '• 数分待ってから再送信をお試しください',
                      style: TextStyle(
                        fontSize: AppFontSize.sm,
                        height: 1.45,
                        color: AuthColors.mutedOnForm,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'メール入力に戻る',
                  style: TextStyle(
                    color: AuthColors.mutedOnForm,
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
