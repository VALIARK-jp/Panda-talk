import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'core/design_tokens.dart';

void main() {
  runApp(const PandaTalkApp());
}

class PandaTalkApp extends StatelessWidget {
  const PandaTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'パンダトーク',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.black),
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.black),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
