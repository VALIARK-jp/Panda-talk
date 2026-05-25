import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/oddball_score.dart';

/// Worker が届かないとき（localhost + wrangler 未起動）に `panda_answers` へ直接保存する。
Future<int> submitAnswerViaSupabase({
  required String questionId,
  required bool selectedA,
}) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    throw StateError('ログインしていません');
  }

  final choice = selectedA ? 'a' : 'b';
  try {
    await client.from('panda_answers').upsert({
      'user_id': userId,
      'question_id': questionId,
      'choice': choice,
    }, onConflict: 'user_id,question_id');
  } on PostgrestException catch (e) {
    if (e.code != '23505') rethrow;
    await client
        .from('panda_answers')
        .update({'choice': choice})
        .eq('user_id', userId)
        .eq('question_id', questionId);
  }

  final percent = await fetchQuestionPercentAFromSupabase(questionId);
  if (kDebugMode) {
    debugPrint(
      'submitAnswerViaSupabase: saved questionId=$questionId percentA=$percent',
    );
  }
  return percent;
}

/// 質問の A/B 票数。`panda_answers` の生行は本人分しか読ませないため、
/// 全体集計は security definer RPC から取得する。
Future<QuestionVoteStats> fetchVoteStatsFromSupabase(String questionId) async {
  final client = Supabase.instance.client;
  try {
    final rows = await client.rpc<List<dynamic>>(
      'get_panda_question_stats',
      params: {'p_question_id': questionId},
    );
    final row = rows.isEmpty ? null : rows.first as Map<String, dynamic>;

    if (row != null) {
      final countA = row['count_a'] as int? ?? 0;
      final countB = row['count_b'] as int? ?? 0;
      final total = countA + countB;
      final percentA = total == 0 ? 50 : (countA / total * 100).round();
      return QuestionVoteStats(
        percentA: percentA,
        countA: countA,
        countB: countB,
      );
    }
  } catch (_) {
    // RPC未適用のdev環境では、旧ビューが読める場合だけ使う。
  }

  final row = await client
      .from('panda_question_stats')
      .select('count_a, count_b')
      .eq('question_id', questionId)
      .maybeSingle();
  if (row == null) {
    return const QuestionVoteStats(percentA: 50, countA: 0, countB: 0);
  }
  final countA = row['count_a'] as int? ?? 0;
  final countB = row['count_b'] as int? ?? 0;
  final total = countA + countB;
  final percentA = total == 0 ? 50 : (countA / total * 100).round();
  return QuestionVoteStats(percentA: percentA, countA: countA, countB: countB);
}

/// `panda_question_stats` から最新の A 側比率（0–100）を取得する。
Future<int> fetchQuestionPercentAFromSupabase(String questionId) async {
  return (await fetchVoteStatsFromSupabase(questionId)).percentA;
}
