import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:panda_talk/screens/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onStartGuest: () {},
          onOpenLogin: (_) {},
        ),
      ),
    );

    expect(find.text('パンダトーク'), findsOneWidget);
  });
}
