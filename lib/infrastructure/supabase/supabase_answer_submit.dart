import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// `panda_question_stats` から最新の A 側比率（0–100）を取得する。
Future<int> fetchQuestionPercentAFromSupabase(String questionId) async {
  final client = Supabase.instance.client;
  final row = await client
      .from('panda_question_stats')
      .select('count_a, count_b')
      .eq('question_id', questionId)
      .maybeSingle();

  if (row == null) return 50;
  final countA = row['count_a'] as int? ?? 0;
  final countB = row['count_b'] as int? ?? 0;
  final total = countA + countB;
  if (total == 0) return 50;
  return (countA / total * 100).round();
}
