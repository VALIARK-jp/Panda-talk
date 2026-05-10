import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home/question_feed_screen.dart';
import 'match/match_screen.dart';
import 'talk/talk_screen.dart';
import 'post/question_post_screen.dart';
import 'profile/profile_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
