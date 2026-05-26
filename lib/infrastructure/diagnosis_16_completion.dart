import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dummy_data.dart';
import '../core/panda_type.dart';
import '../domain/panda_type_calculator.dart';
import '../infrastructure/providers/repositories.dart';
import '../presentation/providers/diagnosis_providers.dart';
import '../presentation/providers/profile_providers.dart';
import '../presentation/providers/feed_window_controller.dart';
import '../presentation/providers/question_providers.dart';
import 'diagnosis_16_store.dart';
import 'diagnosis_16_sync.dart';

/// フィード上の Q1–16 回答から診断結果を確定する。
Future<PandaTypeResult> completeDiagnosis16FromFeed({
  required WidgetRef ref,
  required List<DummyQuestion> diagnosisQuestions,
  required Map<int, String> selectedOptionsByQuestion,
}) async {
  final catalog = diagnosisQuestions.length >= 16
      ? diagnosisQuestions
      : await ref.read(questionRepositoryProvider).getDiagnosis16Questions();
  final byNumber = {for (final q in catalog) q.number: q};

  final answers = <int, bool>{};
  for (var n = 1; n <= 16; n++) {
    final selected = selectedOptionsByQuestion[n];
    final q = byNumber[n];
    if (selected == null || q == null) continue;
    final choseA = selected == q.optionA;
    answers[n] = choseA;
    await Diagnosis16Store.saveAnswer(n, choseA);
  }

  if (answers.length < 16) {
    throw StateError(
      '診断16問の回答が揃っていません（${answers.length}/16）',
    );
  }

  final result = PandaTypeCalculator.compute(answers);
  await Diagnosis16Store.saveResult(result);
  await syncDiagnosis16Result(ref);

  ref.invalidate(profileControllerProvider);
  ref.invalidate(diagnosis16UnlockedProvider);
  ref.invalidate(feedWindowControllerProvider);
  ref.invalidate(questionHistoryProvider);

  return result;
}
