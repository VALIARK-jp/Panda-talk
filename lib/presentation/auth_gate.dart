import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_tokens.dart';
import '../infrastructure/auth/valiark_deeplink_handler.dart';
import '../infrastructure/post_login_onboarding_store.dart';
import '../features/auth/screens/auth/login_screen.dart';
import '../features/auth/screens/auth/signup_screen.dart';
import '../screens/main_app.dart';
import '../screens/onboarding_screen.dart';
import '../screens/post_login_welcome_screen.dart';
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

/// ログイン済み: 初回のみウェルカム → [MainApp]。ゲストは従来どおり直接 MainApp。
class _LoggedInShell extends StatefulWidget {
  const _LoggedInShell();

  @override
  State<_LoggedInShell> createState() => _LoggedInShellState();
}

class _LoggedInShellState extends State<_LoggedInShell> {
  bool? _prefsLoaded;
  bool _welcomeDone = false;

  @override
  void initState() {
    super.initState();
    PostLoginOnboardingStore.isWelcomeCompleted().then((done) {
      if (mounted) {
        setState(() {
          _welcomeDone = done;
          _prefsLoaded = true;
        });
      }
    });
  }

  Future<void> _completeWelcome() async {
    await PostLoginOnboardingStore.setWelcomeCompleted();
    if (mounted) setState(() => _welcomeDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_prefsLoaded != true) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_welcomeDone) {
      return PostLoginWelcomeScreen(onContinue: _completeWelcome);
    }
    return const MainApp();
  }
}
