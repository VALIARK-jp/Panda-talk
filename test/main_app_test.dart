import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panda_talk/infrastructure/mock/mock_question_repository.dart';
import 'package:panda_talk/infrastructure/providers/repositories.dart';
import 'package:panda_talk/presentation/providers/auth_providers.dart';
import 'package:panda_talk/screens/main_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('guest profile tab opens login instead of profile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var openedLogin = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserProvider.overrideWith((ref) => Stream<User?>.value(null)),
          guestModeProvider.overrideWith((ref) => true),
          questionRepositoryProvider.overrideWithValue(
            MockQuestionRepository(),
          ),
        ],
        child: MaterialApp(
          home: MainApp(onOpenLogin: () => openedLogin = true),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('プロフィール'));
    await tester.pump();

    expect(openedLogin, isTrue);
    expect(find.text('自己紹介'), findsNothing);
  });
}
