import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_tokens.dart';
import '../presentation/providers/auth_providers.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/login_required_gate.dart';
import 'home/question_feed_screen.dart';
import 'match/match_screen.dart';
import 'talk/talk_screen.dart';
import 'post/question_post_screen.dart';
import 'profile/profile_screen.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  int _currentIndex = 0;

  static const _matchIndex = 1;
  static const _postIndex = 2;
  static const _talkIndex = 3;
  static const _profileIndex = 4;

  bool get _isLoggedIn {
    final asyncUser = ref.watch(authUserProvider);
    return (asyncUser.valueOrNull ?? Supabase.instance.client.auth.currentUser) != null;
  }

  String _featureLabelForIndex(int index) {
    switch (index) {
      case _matchIndex:
        return 'マッチ';
      case _postIndex:
        return '投稿';
      case _talkIndex:
        return 'トーク';
      case _profileIndex:
        return 'プロフィール';
      default:
        return 'この機能';
    }
  }

  bool _requiresLogin(int index) =>
      index == _matchIndex ||
      index == _postIndex ||
      index == _talkIndex ||
      index == _profileIndex;

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return const QuestionFeedScreen();
      case _matchIndex:
        return const MatchScreen();
      case _postIndex:
        return const QuestionPostScreen();
      case _talkIndex:
        return const TalkScreen();
      case _profileIndex:
        return const ProfileScreen();
      default:
        return const QuestionFeedScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = !_isLoggedIn && _requiresLogin(_currentIndex)
        ? LoginRequiredGate(featureLabel: _featureLabelForIndex(_currentIndex))
        : _screenForIndex(_currentIndex);

    return Scaffold(
      backgroundColor: AppColors.softGray,
      body: body,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
