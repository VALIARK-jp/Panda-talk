import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../infrastructure/auth/valiark_deeplink_handler.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_app.dart';
import '../screens/onboarding_screen.dart';
import 'providers/auth_providers.dart';

/// Routes between onboarding, login (pushed), guest [MainApp], and signed-in [MainApp].
/// Starts [ValiarkDeeplinkHandler] once (pedal_share-style explicit auth deep links).
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
      return const MainApp();
    }
    if (guest) {
      return const MainApp();
    }

    return OnboardingScreen(
      onStartGuest: () => ref.read(guestModeProvider.notifier).state = true,
      onOpenLogin: (mode) {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => LoginScreen(initialMode: mode),
          ),
        );
      },
    );
  }
}
