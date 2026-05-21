import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dummy_data.dart';
import '../core/panda_type.dart';
import '../domain/panda_type_calculator.dart';
import '../presentation/providers/diagnosis_providers.dart';
import '../presentation/providers/profile_providers.dart';
import '../presentation/providers/question_providers.dart';
import 'diagnosis_16_store.dart';
import 'diagnosis_16_sync.dart';

/// フィード上の Q1–16 回答から診断結果を確定する。
Future<PandaTypeResult> completeDiagnosis16FromFeed({
  required WidgetRef ref,
  required List<DummyQuestion> diagnosisQuestions,
  required Map<int, String> selectedOptionsByQuestion,
}) async {
  final answers = <int, bool>{};
  for (final q in diagnosisQuestions) {
    final selected = selectedOptionsByQuestion[q.number];
    if (selected == null) continue;
    final choseA = selected == q.optionA;
    answers[q.number] = choseA;
    await Diagnosis16Store.saveAnswer(q.number, choseA);
  }

  final result = PandaTypeCalculator.compute(answers);
  await Diagnosis16Store.saveResult(result);
  await syncDiagnosis16Result(ref);

  ref.invalidate(profileControllerProvider);
  ref.invalidate(diagnosis16UnlockedProvider);
  ref.invalidate(feedQuestionsProvider);
  ref.invalidate(questionHistoryProvider);

  return result;
}
