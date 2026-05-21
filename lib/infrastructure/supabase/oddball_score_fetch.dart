import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/oddball_score.dart';

/// `panda_user_oddball_scores` を優先し、0% かつ回答があるときは
/// `panda_answers` から再計算（質問 RLS でビューが壊れている場合のフォールバック）。
Future<int> fetchOddballScoreForUser(
  SupabaseClient client,
  String userId, {
  int? answerCountHint,
}) async {
  try {
    final row = await client
        .from('panda_user_oddball_scores')
        .select('oddball_score, total_answer_count')
        .eq('user_id', userId)
        .maybeSingle();
    final score = (row?['oddball_score'] as num?)?.round() ?? 0;
    final total = row?['total_answer_count'] as int? ?? answerCountHint ?? 0;
    if (score > 0 || total == 0) return score;
  } catch (_) {
    // ビュー未適用・権限エラー時は下の集計へ
  }

  return computeOddballScoreFromAnswers(client, userId);
}

/// 認証ユーザーが読める `panda_answers` だけで異端児スコアを算出する。
Future<int> computeOddballScoreFromAnswers(
  SupabaseClient client,
  String userId,
) async {
  final myRows = await client
      .from('panda_answers')
      .select('question_id, choice')
      .eq('user_id', userId);

  if (myRows.isEmpty) return 0;

  final questionIds =
      myRows.map((r) => r['question_id'] as String).toSet().toList();

  final allRows = await client
      .from('panda_answers')
      .select('question_id, choice')
      .inFilter('question_id', questionIds);

  final countA = <String, int>{};
  final countB = <String, int>{};
  for (final row in allRows) {
    final qid = row['question_id'] as String;
    if (row['choice'] == 'a') {
      countA[qid] = (countA[qid] ?? 0) + 1;
    } else {
      countB[qid] = (countB[qid] ?? 0) + 1;
    }
  }

  var minority = 0;
  for (final row in myRows) {
    final qid = row['question_id'] as String;
    final choseA = row['choice'] == 'a';
    if (isMinorityChoice(
      choseA: choseA,
      countA: countA[qid] ?? 0,
      countB: countB[qid] ?? 0,
    )) {
      minority++;
    }
  }

  return oddballScorePercent(
    minorityAnswerCount: minority,
    totalAnswerCount: myRows.length,
  );
}
