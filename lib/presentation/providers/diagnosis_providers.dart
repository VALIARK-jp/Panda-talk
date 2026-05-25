import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../infrastructure/diagnosis_16_store.dart';
import '../../infrastructure/providers/repositories.dart';

const _diagnosisQuestionCount = 16;

/// 16問の結果モーダルを見終え、17問目以降のフィードに進める状態。
final diagnosis16UnlockedProvider = FutureProvider<bool>((ref) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final questionRepo = ref.watch(questionRepositoryProvider);

  try {
    final profile = await profileRepo.getProfile();
    if (profile.hasDiagnosis16) return true;
  } catch (_) {}

  if (await Diagnosis16Store.isResultSeen()) return true;

  if (Supabase.instance.client.auth.currentSession != null) {
    try {
      final questions = await questionRepo.getFeedWindow(
        before: 0,
        after: 0,
        maxQuestionNumber: _diagnosisQuestionCount,
      );
      final answeredNumbers = questions
          .where((q) => q.number >= 1 && q.number <= _diagnosisQuestionCount)
          .where((q) => q.myAnswer != null)
          .map((q) => q.number)
          .toSet();
      for (var n = 1; n <= _diagnosisQuestionCount; n++) {
        if (!answeredNumbers.contains(n)) return false;
      }
      return true;
    } catch (_) {}
  }

  return false;
});
