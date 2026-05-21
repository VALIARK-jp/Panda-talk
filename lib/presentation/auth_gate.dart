import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_tokens.dart';
import '../infrastructure/auth/valiark_deeplink_handler.dart';
import '../infrastructure/post_auth_flow.dart';
import '../features/auth/screens/auth/login_screen.dart';
import '../features/auth/screens/auth/signup_screen.dart';
import '../screens/main_app.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import 'providers/auth_providers.dart';

/// Routes between onboarding, login (pushed), guest [MainApp], and signed-in [MainApp].
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

/// ログイン済み: プロフィール未入力ならセットアップ → [MainApp]。
class _LoggedInShell extends ConsumerStatefulWidget {
  const _LoggedInShell();

  @override
  ConsumerState<_LoggedInShell> createState() => _LoggedInShellState();
}

class _LoggedInShellState extends ConsumerState<_LoggedInShell> {
  bool? _routeResolved;
  bool _profileSetupDone = false;

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    final done = await PostAuthFlow.isProfileSetupComplete(ref);
    if (mounted) {
      setState(() {
        _profileSetupDone = done;
        _routeResolved = true;
      });
    }
  }

  Future<void> _completeProfileSetup() async {
    ref.read(guestModeProvider.notifier).state = false;
    if (mounted) {
      setState(() => _profileSetupDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_routeResolved != true) {
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
