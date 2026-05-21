import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_tokens.dart';
import '../../../../infrastructure/auth/auth_service.dart';
import '../../../../infrastructure/post_auth_flow.dart';
import '../../../../infrastructure/profile_onboarding_store.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../widgets/terms_consent_footer.dart';
import '../../widgets/valiark_auth_notice_block.dart';
import 'email_sent_screen.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({
    super.key,
    this.initialTab = 0,
    this.showSignupTab = true,
    this.showLoginTab = true,
  });

  final int initialTab;
  final bool showSignupTab;
  final bool showLoginTab;

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription<AuthState> _authSubscription;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  bool _showLoginPassword = false;
  bool _showSignupPassword = false;
  bool _showConfirmPassword = false;
  String? _signupError;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        await PostAuthFlow.withLoading(context, () async {
          await PostAuthFlow.finishLogin(ref: ref, context: context);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authSubscription.cancel();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  AuthService get _auth => ref.read(authServiceProvider);

  InputDecoration _fieldDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AuthColors.mutedOnForm),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.black, width: 1.4),
      ),
      filled: true,
      fillColor: AppColors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTabs = widget.showSignupTab && widget.showLoginTab;

    return Scaffold(
      backgroundColor: AuthColors.formScaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          showTabs
              ? 'メール認証'
              : (widget.showLoginTab ? 'ログイン' : '新規登録'),
        ),
        backgroundColor: AuthColors.chrome,
        elevation: 0,
        foregroundColor: AppColors.white,
        bottom: showTabs
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.white,
                unselectedLabelColor:
                    AppColors.white.withValues(alpha: 0.68),
                indicatorColor: AppColors.white,
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'ログイン'),
                  Tab(text: '新規登録'),
                ],
              )
            : null,
      ),
      body: showTabs
          ? TabBarView(
              controller: _tabController,
              children: [_buildLoginForm(), _buildSignupForm()],
            )
          : (widget.showLoginTab ? _buildLoginForm() : _buildSignupForm()),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            TextFormField(
              controller: _loginEmailController,
              decoration: _fieldDecoration('メールアドレス', Icons.email),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'メールアドレスを入力してください';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return '正しいメールアドレスを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginPasswordController,
              decoration: _fieldDecoration(
                'パスワード',
                Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showLoginPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showLoginPassword = !_showLoginPassword;
                    });
                  },
                ),
              ),
              obscureText: !_showLoginPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'パスワードを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthColors.chrome,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'ログイン',
                        style: TextStyle(
                          fontSize: AppFontSize.lg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resetPassword,
              child: Text(
                'パスワードを忘れた場合',
                style: TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showEmailTroubleshoot,
              child: Text(
                'メール確認が届かない場合',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AuthColors.mutedOnForm,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const TermsConsentFooter(onLightBackground: true),
            const SizedBox(height: 16),
            const ValiarkAuthNoticeBlock(
              onLightBackground: true,
              showCreatedByHeader: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            TextFormField(
              controller: _displayNameController,
              decoration: _fieldDecoration('表示名', Icons.person),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '表示名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signupEmailController,
              decoration: _fieldDecoration('メールアドレス', Icons.email),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'メールアドレスを入力してください';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return '正しいメールアドレスを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signupPasswordController,
              decoration: _fieldDecoration(
                'パスワード',
                Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showSignupPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSignupPassword = !_showSignupPassword;
                    });
                  },
                ),
              ),
              obscureText: !_showSignupPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'パスワードを入力してください';
                }
                if (value.length < 6) {
                  return 'パスワードは6文字以上で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signupConfirmPasswordController,
              decoration: _fieldDecoration(
                'パスワード確認',
                Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: !_showConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'パスワード確認を入力してください';
                }
                if (value != _signupPasswordController.text) {
                  return 'パスワードが一致しません';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthColors.chrome,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        '新規登録',
                        style: TextStyle(
                          fontSize: AppFontSize.lg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            if (_signupError != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _signupError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            const TermsConsentFooter(onLightBackground: true),
            const SizedBox(height: 16),
            const ValiarkAuthNoticeBlock(
              onLightBackground: true,
              showCreatedByHeader: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmail(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      if (!mounted) return;
      await PostAuthFlow.withLoading(context, () async {
        await PostAuthFlow.finishLogin(ref: ref, context: context);
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _signupError = null;
    });

    try {
      final response = await _auth.signUpWithEmail(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text,
        displayName: _displayNameController.text.trim(),
      );

      if (!mounted) return;

      if (response.session != null) {
        final userId = response.user?.id;
        if (userId != null) {
          await ProfileOnboardingStore.requireSetup(userId);
        }
        if (!mounted) return;
        await PostAuthFlow.withLoading(context, () async {
          await PostAuthFlow.finishLogin(ref: ref, context: context);
        });
        return;
      }

      final sentTo = _signupEmailController.text.trim();
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EmailSentScreen(email: sentTo),
        ),
      );
    } on EmailAlreadyRegisteredException {
      if (mounted) {
        _showExistingAccountDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _signupError =
              e.toString().replaceFirst('Exception: ', '').trim().isEmpty
                  ? '登録に失敗しました。'
                  : e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showExistingAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('すでにアカウントがあります'),
        content: const Text(
          'このメールアドレスは、すでに登録されています。'
          '「ログイン」から同じメールアドレスとパスワードで続けてください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog('メールアドレスを入力してください');
      return;
    }

    try {
      await _auth.resetPassword(email);
      _showSuccessDialog(
        title: 'パスワードリセット',
        message: 'パスワードリセット用のメールを送信しました。メールをご確認ください。',
      );
    } catch (e) {
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _resendEmailVerificationFromDialog(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(trimmed)) {
      _showErrorDialog('有効なメールアドレスを入力してください');
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.email != null) {
        await _auth.resendEmailVerification();
      } else {
        await _auth.resendSignupEmail(trimmed);
      }
      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog(
          title: 'メール再送信',
          message: '確認メールを再送信しました。しばらく待っても届かない場合は迷惑メールフォルダをご確認ください。',
        );
      }
    } catch (e) {
      _showErrorDialog(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showEmailTroubleshoot() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('メールが届かない場合'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '以下をご確認ください：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. 迷惑メール（スパム）フォルダ'),
              Text('2. プロモーションフォルダ（Gmail）'),
              Text('3. メールアドレスの入力間違い'),
              Text('4. メールサーバーの受信制限'),
              SizedBox(height: 12),
              Text('対処法：', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• 5-10分程度お待ちください'),
              Text('• 異なるメールアドレスで試してください'),
              Text('• 携帯メールではなくGmailやYahooメールをお試しください'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _resendEmailVerificationFromDialog(
              _loginEmailController.text,
            ),
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

  void _showErrorDialog(String message) {
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

  void _showSuccessDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
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
