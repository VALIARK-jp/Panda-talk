import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/dummy_data.dart';
import 'providers/repositories.dart';
import 'question_progress_store.dart';
import 'supabase/supabase_answer_submit.dart';
import '../presentation/providers/profile_providers.dart';
import '../presentation/providers/question_providers.dart';

/// ゲスト時に端末だけへ保存した回答を、ログイン後に `panda_answers` へ送る。
///
/// 診断 Q1–16 は [uploadPendingDiagnosis16Answers] に任せ、この関数では送らない。
Future<void> uploadPendingGuestAnswers(WidgetRef ref) async {
  if (Supabase.instance.client.auth.currentSession == null) return;

  final raw = await QuestionProgressStore.loadGuest();
  if (raw == null) return;

  final progress = QuestionFeedState.fromJson(raw);
  final pending = Map<int, String>.from(progress.selectedOptionsByQuestion)
    ..removeWhere((number, _) => isDiagnosisQuestionNumber(number));
  if (pending.isEmpty) {
    await _pruneGuestDiagnosisKeysFromStore();
    return;
  }

  final repo = ref.read(questionRepositoryProvider);
  final questions = <DummyQuestion>[];
  try {
    final window = await repo.getFeedWindow(before: 30, after: 30);
    questions.addAll(window);
    questions.addAll(await repo.getHistory(limit: 200));
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('uploadPendingGuestAnswers: load questions failed: $e\n$st');
    }
    return;
  }

  final byNumber = <int, DummyQuestion>{};
  for (final q in questions) {
    if (isDiagnosisQuestionNumber(q.number)) continue;
    byNumber[q.number] = q;
  }

  final alreadyOnServer = await loadAnsweredQuestionIdsOnServer(repo);

  for (final entry in pending.entries) {
    if (isDiagnosisQuestionNumber(entry.key)) continue;
    final q = byNumber[entry.key];
    if (q?.apiId == null) continue;
    if (alreadyOnServer.contains(q!.apiId)) continue;

    try {
      await repo.answerQuestion(question: q, selectedOption: entry.value);
      alreadyOnServer.add(q.apiId!);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Already answered')) continue;
      if (AppConfig.usesLocalApiHost &&
          q.apiId != null &&
          (msg.contains('Connection refused') ||
              msg.contains('SocketException') ||
              msg.contains('ClientException'))) {
        try {
          final selectedA = entry.value == q.optionA;
          await submitAnswerViaSupabase(
            questionId: q.apiId!,
            selectedA: selectedA,
          );
          continue;
        } catch (e2) {
          if (kDebugMode) {
            debugPrint(
              'uploadPendingGuestAnswers: Q${entry.key} supabase fallback failed: $e2',
            );
          }
        }
      }
      if (kDebugMode) {
        debugPrint(
          'uploadPendingGuestAnswers: Q${entry.key} failed: $e',
        );
      }
    }
  }

  await _pruneGuestDiagnosisKeysFromStore();
  await QuestionProgressStore.clearGuest();
  ref.invalidate(profileControllerProvider);
  ref.invalidate(questionFeedControllerProvider);
}

Future<void> _pruneGuestDiagnosisKeysFromStore() async {
  final raw = await QuestionProgressStore.loadGuest();
  if (raw == null) return;

  final selected =
      raw['selectedOptionsByQuestion'] as Map<String, dynamic>? ?? {};
  final percent = raw['percentAByQuestion'] as Map<String, dynamic>? ?? {};
  final prunedSelected = {
    for (final e in selected.entries)
      if (!isDiagnosisQuestionNumber(int.parse(e.key))) e.key: e.value,
  };
  final prunedPercent = {
    for (final e in percent.entries)
      if (!isDiagnosisQuestionNumber(int.parse(e.key))) e.key: e.value,
  };

  if (prunedSelected.length == selected.length &&
      prunedPercent.length == percent.length) {
    return;
  }

  raw['selectedOptionsByQuestion'] = prunedSelected;
  raw['percentAByQuestion'] = prunedPercent;
  raw['answeredCount'] = prunedSelected.length;
  await QuestionProgressStore.saveGuest(raw);
}
