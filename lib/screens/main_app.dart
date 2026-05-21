import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/feature_flags.dart';
import '../core/design_tokens.dart';
import '../presentation/providers/auth_providers.dart';
import '../presentation/providers/profile_providers.dart';
import '../presentation/providers/question_providers.dart';
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
  int _currentNavIndex = 0;

  static const _matchIndex = 1;
  static const _postIndex = 2;
  static const _talkIndex = 3;
  static const _profileIndex = 4;

  /// ボトムナビの index → 画面 index（トーク非表示時はプロフィールが nav 3 → screen 4）。
  int _screenIndexForNav(int navIndex) {
    if (kTalkNavTabEnabled) return navIndex;
    if (navIndex >= 3) return _profileIndex;
    return navIndex;
  }

  int _profileNavIndex() => kTalkNavTabEnabled ? _profileIndex : 3;

  bool get _isLoggedIn {
    final asyncUser = ref.watch(authUserProvider);
    return (asyncUser.valueOrNull ??
            Supabase.instance.client.auth.currentUser) !=
        null;
  }

  String _featureLabelForScreen(int screenIndex) {
    switch (screenIndex) {
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

  bool _requiresLoginScreen(int screenIndex) =>
      screenIndex == _matchIndex ||
      screenIndex == _postIndex ||
      screenIndex == _talkIndex ||
      screenIndex == _profileIndex;

  Widget _screenForIndex(int screenIndex) {
    switch (screenIndex) {
      case 0:
        return QuestionFeedScreen(
          onOpenPost: () => setState(() => _currentNavIndex = _postIndex),
        );
      case _matchIndex:
        return MatchScreen(
          onOpenDiagnosis: () => setState(() => _currentNavIndex = 0),
        );
      case _postIndex:
        return const QuestionPostScreen();
      case _talkIndex:
        return TalkScreen(
          onOpenMatch: () => setState(() => _currentNavIndex = _matchIndex),
        );
      case _profileIndex:
        return const ProfileScreen();
      default:
        return QuestionFeedScreen(
          onOpenPost: () => setState(() => _currentNavIndex = _postIndex),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 起動直後に診断フィードを先読み（タブ復帰時の古い一覧＋ページずれを防ぐ）
    ref.watch(feedBootstrapProvider);

    final screenIndex = _screenIndexForNav(_currentNavIndex);
    final body = !_isLoggedIn && _requiresLoginScreen(screenIndex)
        ? LoginRequiredGate(
            featureLabel: _featureLabelForScreen(screenIndex),
          )
        : _screenForIndex(screenIndex);

    return Scaffold(
      backgroundColor: AppColors.softGray,
      body: body,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (navIndex) {
          setState(() => _currentNavIndex = navIndex);
          if (navIndex == _profileNavIndex() && _isLoggedIn) {
            ref.invalidate(profileControllerProvider);
          }
        },
      ),
    );
  }
}
