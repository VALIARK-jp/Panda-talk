import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../infrastructure/auth/auth_service.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';

enum LoginScreenMode { login, signup }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.initialMode = LoginScreenMode.login,
  });

  final LoginScreenMode initialMode;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  late LoginScreenMode _mode = widget.initialMode;
  bool _loading = false;
  String? _loadingProvider;
  bool _obscurePassword = true;
  StreamSubscription<AuthState>? _authSubscription;

  bool get _isLogin => _mode == LoginScreenMode.login;

  @override
  void initState() {
    super.initState();
    // pedal_share EmailAuthScreen: メールリンクで戻ったときにログインスタックを閉じる
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: AppColors.black),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const PandaSleep(size: 96),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _isLogin ? 'ログイン' : '新規登録',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _isLogin
                  ? '前に使ったアカウントで続きから再開できます。'
                  : '回答履歴や合致度を保存して、友達と比べられるようになります。'
                      'ほかのアプリですでに同じメールを使っている場合は、下の「ログインはこちら」から続けてください。',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.textGray,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildEmailForm(),
            const SizedBox(height: AppSpacing.lg),
            _buildDivider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'LINE / Apple は Valiark のアプリ（例: Panda Talk と Who eats）で共通のアカウントです。'
              'ほかのアプリで使ったことがあってもこのボタンで入れます。はじめての方も同じボタンです。'
              'メール・パスワードとは別の登録方法です。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textGray.withValues(alpha: 0.95),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildAuthButton(
              icon: Icons.chat_bubble,
              label: 'LINEで続ける',
              color: const Color(0xFF00C300),
              textColor: AppColors.white,
              provider: 'line',
              onTap: () => _runNativeAuth('line'),
            ),
            const SizedBox(height: AppSpacing.md),
            if (Theme.of(context).platform == TargetPlatform.iOS)
              _buildAuthButton(
                icon: Icons.apple,
                label: 'Appleで続ける',
                color: AppColors.black,
                textColor: AppColors.white,
                provider: 'apple',
                onTap: () => _runNativeAuth('apple'),
              ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _loading ? null : _toggleMode,
              child: Text(
                _isLogin ? '新規登録はこちら' : 'ログインはこちら',
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            TextFormField(
              controller: _displayNameController,
              decoration: _inputDecoration('ユーザーネーム', Icons.person),
              validator: (value) {
                if (_isLogin) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'ユーザーネームを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('メールアドレス', Icons.email),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'メールアドレスを入力してください';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return '正しいメールアドレスを入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration('パスワード', Icons.lock).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'パスワードを入力してください';
              }
              if (!_isLogin && value.length < 6) {
                return 'パスワードは6文字以上で入力してください';
              }
              return null;
            },
          ),
          if (!_isLogin) ...[
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: _inputDecoration('パスワード確認', Icons.lock_outline),
              validator: (value) {
                if (_isLogin) return null;
                if (value != _passwordController.text) {
                  return 'パスワードが一致しません';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PandaButton(
            label: _isLogin ? 'メールアドレスでログイン' : 'メールアドレスで新規登録',
            onTap: _loading ? null : _submitEmail,
          ),
          if (_isLogin) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _loading ? null : _requestPasswordReset,
              child: const Text(
                'パスワードを忘れた場合',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
            ),
          ],
          TextButton(
            onPressed: _loading ? null : _showEmailDeliveryHelp,
            child: Text(
              _isLogin ? '確認メールが届かない場合' : '登録用メールが届かない場合',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderGray)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'または',
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderGray)),
      ],
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required String provider,
    required VoidCallback onTap,
  }) {
    final pressed = _loading && _loadingProvider == provider;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withValues(alpha: 0.55),
          disabledForegroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          elevation: 0,
        ),
        child: pressed
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.softGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.black, width: 1.4),
      ),
    );
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showError('メールアドレスを入力してください');
      return;
    }
    try {
      await ref.read(authServiceProvider).requestPasswordReset(email);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('メールを送信しました'),
          content: const Text(
            'パスワード再設定用のメールを送信しました。届いたリンクをタップしてアプリに戻り、新しいパスワードを設定してください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _showEmailDeliveryHelp() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('メールが届かない場合'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '以下をご確認ください：',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text('• 迷惑メール（スパム）フォルダ'),
              const Text('• プロモーションフォルダ（Gmail など）'),
              const Text('• メールアドレスの入力間違い'),
              const SizedBox(height: 12),
              Text(
                '上の欄にメールアドレスを入れたうえで「再送信」を試してください。',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              if (email.isEmpty ||
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                Navigator.pop(dialogContext);
                _showError('メールアドレスを入力してください');
                return;
              }
              try {
                await ref.read(authServiceProvider).resendSignupEmail(email);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('確認メールを再送信しました')),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  _showError(e.toString().replaceFirst('Exception: ', ''));
                }
              }
            },
            child: const Text('再送信'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;

    await _run(
      'email',
      () async {
        final service = ref.read(authServiceProvider);
        if (_isLogin) {
          await service.signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          await service.signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
          );
        }
      },
      onSuccess: _isLogin
          ? null
          : () {
              if (!mounted) return;
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('確認メールを送信しました'),
                  content: const Text(
                    '届いたメール内のリンクをタップして、メールアドレスの確認を完了してください。'
                    '確認後、この画面からメールアドレスとパスワードでログインできます。',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
    );
  }

  Future<void> _runNativeAuth(String provider) async {
    await _run(provider, () async {
      final service = ref.read(authServiceProvider);
      if (provider == 'line') {
        await service.signInWithLine();
      } else {
        await service.signInWithApple();
      }
    });
  }

  Future<void> _run(
    String provider,
    Future<void> Function() action, {
    VoidCallback? onSuccess,
  }) async {
    setState(() {
      _loading = true;
      _loadingProvider = provider;
    });

    try {
      await action();
      onSuccess?.call();
      ref.invalidate(authUserProvider);
    } on EmailAlreadyRegisteredException {
      if (mounted) _showExistingAccountDialog();
    } catch (error) {
      if (mounted) _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _mode = _isLogin ? LoginScreenMode.signup : LoginScreenMode.login;
      _formKey.currentState?.reset();
    });
  }

  void _showExistingAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('すでにアカウントがあります'),
        content: const Text(
          'このメールアドレスは、ほかの Valiark アプリですでに登録されています。'
          '「ログイン」から同じメールアドレスとパスワードで続けてください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _mode = LoginScreenMode.login;
                _passwordController.clear();
                _confirmPasswordController.clear();
              });
            },
            child: const Text('ログインへ'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
