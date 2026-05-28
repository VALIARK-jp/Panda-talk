import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_tokens.dart';
import '../infrastructure/share/share_deeplink_handler.dart';
import '../infrastructure/post_auth_flow.dart';
import '../features/auth/screens/auth/login_screen.dart';
import '../features/auth/screens/auth/signup_screen.dart';
import '../screens/main_app.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import 'providers/auth_providers.dart';
import 'session_reset.dart';

/// Routes between onboarding, login (pushed), guest [MainApp], and signed-in [MainApp].
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  var _shareDeeplinkStarted = false;

  @override
  Widget build(BuildContext context) {
    if (!_shareDeeplinkStarted) {
      _shareDeeplinkStarted = true;
      ShareDeeplinkHandler.bind(ref);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShareDeeplinkHandler.handleOnce();
      });
    }

    final asyncUser = ref.watch(authUserProvider);
    final user = asyncUser.valueOrNull ?? Supabase.instance.client.auth.currentUser;
    final guest = ref.watch(guestModeProvider);
    final sessionEpoch = ref.watch(appSessionEpochProvider);

    if (user != null) {
      return _LoggedInShell(
        key: ValueKey('logged-in-${user.id}-$sessionEpoch'),
      );
    }
    if (guest) {
      return MainApp(key: ValueKey('guest-$sessionEpoch'));
    }

    return OnboardingScreen(
      onStartGuest: () {
        resetSessionScopedState(ref);
        ref.read(guestModeProvider.notifier).state = true;
      },
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
  const _LoggedInShell({super.key});

  @override
  ConsumerState<_LoggedInShell> createState() => _LoggedInShellState();
}

class _LoggedInShellState extends ConsumerState<_LoggedInShell> {
  bool? _routeResolved;
  bool _profileSetupDone = false;
  static const _resolveTimeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    if (kDebugMode) {
      debugPrint('[AuthGate] resolveRoute:start');
    }
    bool done = false;
    try {
      done = await PostAuthFlow.isProfileSetupComplete(ref).timeout(
        _resolveTimeout,
      );
      if (kDebugMode) {
        debugPrint('[AuthGate] resolveRoute:done=$done');
      }
    } catch (_) {
      // Fallback: if profile check hangs/fails on network, route to setup
      // instead of keeping an infinite spinner.
      done = false;
      if (kDebugMode) {
        debugPrint('[AuthGate] resolveRoute:fallback-to-setup');
      }
    }
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
    final sessionEpoch = ref.watch(appSessionEpochProvider);
    return MainApp(
      key: ValueKey(
        'user-${Supabase.instance.client.auth.currentUser!.id}-$sessionEpoch',
      ),
    );
  }
}
