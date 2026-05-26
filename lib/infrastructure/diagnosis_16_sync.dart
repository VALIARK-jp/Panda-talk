import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/dummy_data.dart';
import 'diagnosis_16_store.dart';
import 'providers/repositories.dart';
import 'supabase/supabase_answer_submit.dart';
import '../presentation/providers/profile_providers.dart';
import '../presentation/providers/question_providers.dart';

/// ゲスト時の16問回答をログイン後に `panda_answers` へ送る（[Diagnosis16Store] のみ）。
Future<void> uploadPendingDiagnosis16Answers(WidgetRef ref) async {
  if (Supabase.instance.client.auth.currentSession == null) return;

  await Diagnosis16Store.migrateGuestScopeToCurrentUser();

  final answers = await Diagnosis16Store.loadAnswers();
  if (answers.isEmpty) return;

  final repo = ref.read(questionRepositoryProvider);
  List<DummyQuestion> questions;
  try {
    questions = await repo.getDiagnosis16Questions();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('uploadPendingDiagnosis16Answers: load failed: $e\n$st');
    }
    return;
  }

  if (kDebugMode) {
    debugPrint(
      'uploadPendingDiagnosis16Answers: ${answers.length} local, '
      '${questions.length} catalog (Q1–16)',
    );
  }

  final byNumber = {for (final q in questions) q.number: q};
  final diagnosisIds = questions.map((q) => q.apiId).whereType<String>().toSet();
  final alreadyOnServer = await loadAnsweredQuestionIdsOnServer(
    repo,
    onlyQuestionIds: diagnosisIds,
  );

  final pendingKeys =
      answers.keys.where(isDiagnosisQuestionNumber).toSet();
  final handled = <int>{};

  for (final entry in answers.entries) {
    if (!isDiagnosisQuestionNumber(entry.key)) continue;
    final q = byNumber[entry.key];
    if (q?.apiId == null) continue;
    if (alreadyOnServer.contains(q!.apiId)) {
      handled.add(entry.key);
      continue;
    }

    final selectedLabel = entry.value ? q.optionA : q.optionB;
    try {
      await repo.answerQuestion(question: q, selectedOption: selectedLabel);
      alreadyOnServer.add(q.apiId!);
      handled.add(entry.key);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Already answered')) {
        handled.add(entry.key);
        continue;
      }
      if (AppConfig.usesLocalApiHost &&
          (msg.contains('Connection refused') ||
              msg.contains('SocketException') ||
              msg.contains('ClientException'))) {
        try {
          await submitAnswerViaSupabase(
            questionId: q.apiId!,
            selectedA: entry.value,
          );
          handled.add(entry.key);
          continue;
        } catch (_) {}
      }
      if (kDebugMode) {
        debugPrint('uploadPendingDiagnosis16Answers Q${entry.key}: $e');
      }
    }
  }

  if (kDebugMode) {
    debugPrint(
      'uploadPendingDiagnosis16Answers: uploaded ${handled.length}/'
      '${pendingKeys.length}',
    );
  }

  if (handled.containsAll(pendingKeys)) {
    await Diagnosis16Store.clear();
  }

  ref.invalidate(questionHistoryProvider);
  ref.invalidate(feedWindowControllerProvider);
  ref.invalidate(questionFeedControllerProvider);
}

/// ローカルで完了した16type結果をログイン後にサーバーへ保存する。
Future<void> syncDiagnosis16Result(WidgetRef ref) async {
  if (Supabase.instance.client.auth.currentSession == null) return;

  try {
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    if (profile.hasDiagnosis16) return;

    final result = await Diagnosis16Store.loadResult();
    if (result == null) return;

    await ref.read(profileRepositoryProvider).savePandaType16(
      slug: result.slug,
      affectionPct: result.scores.affection,
      thinkingPct: result.scores.thinking,
      actionPct: result.scores.action,
      lifePct: result.scores.life,
      diagnosedAt: result.diagnosedAt,
    );
    ref.invalidate(profileControllerProvider);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('syncDiagnosis16Result failed: $e\n$st');
    }
  }
}
