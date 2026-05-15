import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/auth_providers.dart';
import '../widgets/bottom_nav_bar.dart';
import 'auth/login_screen.dart';
import 'home/question_feed_screen.dart';
import 'match/match_screen.dart';
import 'talk/talk_screen.dart';
import 'post/question_post_screen.dart';
import 'profile/profile_screen.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key, this.onOpenLogin});

  final VoidCallback? onOpenLogin;

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  static const _profileTabIndex = 4;

  int _currentIndex = 0;

  final _screens = const [
    QuestionFeedScreen(),
    MatchScreen(),
    QuestionPostScreen(),
    TalkScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authUserAsync = ref.watch(authUserProvider);
    final authUser = authUserAsync.valueOrNull;
    final guest = ref.watch(guestModeProvider);
    final canOpenProfile =
        authUser != null || (authUserAsync.isLoading && !guest);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => _handleTabTap(i, canOpenProfile: canOpenProfile),
      ),
    );
  }

  void _handleTabTap(int index, {required bool canOpenProfile}) {
    if (index == _profileTabIndex && !canOpenProfile) {
      _openLogin();
      return;
    }

    setState(() => _currentIndex = index);
  }

  void _openLogin() {
    final onOpenLogin = widget.onOpenLogin;
    if (onOpenLogin != null) {
      onOpenLogin();
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(initialMode: LoginScreenMode.login),
      ),
    );
  }
}
