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
Future<void> uploadPendingGuestAnswers(WidgetRef ref) async {
  if (Supabase.instance.client.auth.currentSession == null) return;

  final raw = await QuestionProgressStore.loadGuest();
  if (raw == null) return;

  final progress = QuestionFeedState.fromJson(raw);
  final pending = progress.selectedOptionsByQuestion;
  if (pending.isEmpty) return;

  final repo = ref.read(questionRepositoryProvider);
  final questions = <DummyQuestion>[];
  try {
    questions.addAll(await repo.getFeedQuestions());
    questions.addAll(await repo.getHistory());
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('uploadPendingGuestAnswers: load questions failed: $e\n$st');
    }
    return;
  }

  final byNumber = {for (final q in questions) q.number: q};

  for (final entry in pending.entries) {
    final q = byNumber[entry.key];
    if (q == null || q.apiId == null) continue;
    try {
      await repo.answerQuestion(question: q, selectedOption: entry.value);
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

  await QuestionProgressStore.clearGuest();
  ref.invalidate(profileControllerProvider);
  ref.invalidate(questionFeedControllerProvider);
}
