import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_tokens.dart';
import '../infrastructure/auth/valiark_deeplink_handler.dart';
import '../infrastructure/profile_onboarding_store.dart';
import '../infrastructure/providers/repositories.dart';
import '../features/auth/screens/auth/login_screen.dart';
import '../features/auth/screens/auth/signup_screen.dart';
import '../screens/main_app.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import 'providers/auth_providers.dart';

/// Routes between onboarding, login (pushed), guest [MainApp], and signed-in [MainApp].
/// Starts [ValiarkDeeplinkHandler] once for email confirmation / password-reset deep links.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ValiarkDeeplinkHandler.handleOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authUserProvider, (previous, next) {
      final nextUser = next.valueOrNull ?? Supabase.instance.client.auth.currentUser;
      if (nextUser == null) return;
      final prevUser = previous?.valueOrNull;
      if (prevUser != null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final nav = Navigator.maybeOf(context, rootNavigator: true);
        nav?.popUntil((route) => route.isFirst);
      });
    });

    final asyncUser = ref.watch(authUserProvider);
    final user = asyncUser.valueOrNull ?? Supabase.instance.client.auth.currentUser;
    final guest = ref.watch(guestModeProvider);

    if (user != null) {
      return const _LoggedInShell();
    }
    if (guest) {
      return const MainApp();
    }

    return OnboardingScreen(
      onStartGuest: () => ref.read(guestModeProvider.notifier).state = true,
      onOpenAuth: ({required bool openSignup}) {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                openSignup ? const SignupScreen() : const LoginScreen(),
          ),
        );
      },
    );
  }
}

/// ログイン済み: 初回のみプロフィール入力 → [MainApp]（質問フィード）。
class _LoggedInShell extends ConsumerStatefulWidget {
  const _LoggedInShell();

  @override
  ConsumerState<_LoggedInShell> createState() => _LoggedInShellState();
}

class _LoggedInShellState extends ConsumerState<_LoggedInShell> {
  bool? _prefsLoaded;
  bool _profileSetupDone = false;

  @override
  void initState() {
    super.initState();
    _loadProfileSetupState();
  }

  Future<void> _loadProfileSetupState() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) {
      if (mounted) setState(() => _prefsLoaded = true);
      return;
    }
    try {
      await Supabase.instance.client.auth.refreshSession();
    } catch (_) {}

    // 既存プロフィール（DB）を先に見て、ログインし直しで毎回セットアップにならないようにする。
    var done = await ProfileOnboardingStore.isCompleted(userId);
    if (!done) {
      try {
        final profile = await ref.read(profileRepositoryProvider).getProfile();
        done = await ProfileOnboardingStore.syncCompletedFromProfile(
          userId: userId,
          username: profile.username,
        );
      } catch (_) {}
    }

    if (!done) {
      await ProfileOnboardingStore.applyPendingEmailSignup(
        userId: userId,
        email: user?.email,
      );
      done = await ProfileOnboardingStore.isCompleted(userId);
    }

    if (mounted) {
      setState(() {
        _profileSetupDone = done;
        _prefsLoaded = true;
      });
    }
  }

  Future<void> _completeProfileSetup() async {
    ref.read(guestModeProvider.notifier).state = false;
    if (mounted) setState(() => _profileSetupDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_prefsLoaded != true) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_profileSetupDone) {
      return ProfileSetupScreen(onComplete: _completeProfileSetup);
    }
    return const MainApp();
  }
}
