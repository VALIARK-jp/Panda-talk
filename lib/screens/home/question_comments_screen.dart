import 'package:flutter/material.dart';

import '../../core/dummy_data.dart';
import 'question_comment_focus_screen.dart';

/// コメント画面のエントリポイント。
class QuestionCommentsScreen {
  QuestionCommentsScreen._();

  /// 比率バーを上部へ飛ばし、質問 + A/B コメントのみの全画面を開く。
  static Future<bool> openFocus(
    BuildContext context, {
    required DummyQuestion question,
    required int percentA,
    required String? selectedOption,
  }) async {
    final posted = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => QuestionCommentFocusScreen(
          question: question,
          percentA: percentA,
          selectedOption: selectedOption,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
    return posted ?? false;
  }
}
