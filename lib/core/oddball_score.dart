/// 回答 API 直後の集計。
class QuestionVoteStats {
  final int percentA;
  final int countA;
  final int countB;

  const QuestionVoteStats({
    required this.percentA,
    required this.countA,
    required this.countB,
  });
}

/// 異端児スコア用の多数派／少数派判定（DB ビューと同一ルール）。
///
/// - その問の総回答が 1 件だけ → 多数派（少数派にしない）
/// - 同票 → どちらも多数派
/// - それ以外 → 選んだ側の票数が相手より少なければ少数派
bool isMinorityChoice({
  required bool choseA,
  required int countA,
  required int countB,
}) {
  final total = countA + countB;
  if (total <= 1) return false;
  if (countA == countB) return false;
  if (choseA) return countA < countB;
  return countB < countA;
}

/// 少数派回答数 ÷ 総回答数 × 100（四捨五入）。
int oddballScorePercent({
  required int minorityAnswerCount,
  required int totalAnswerCount,
}) {
  if (totalAnswerCount <= 0) return 0;
  return ((minorityAnswerCount / totalAnswerCount) * 100).round();
}

/// 端末側の再計算: 回答済みマップから少数派数を数える。
int countMinorityAnswers({
  required Map<int, bool> selectedSideAByQuestion,
  required Map<int, int> countAByQuestion,
  required Map<int, int> countBByQuestion,
}) {
  var count = 0;
  for (final entry in selectedSideAByQuestion.entries) {
    final number = entry.key;
    final sideA = entry.value;
    final countA = countAByQuestion[number] ?? 0;
    final countB = countBByQuestion[number] ?? 0;
    if (isMinorityChoice(choseA: sideA, countA: countA, countB: countB)) {
      count++;
    }
  }
  return count;
}

/// API に count が無いときの最小推定（表示用。可能なら API の count を使う）。
(int countA, int countB) estimateVoteCountsFromPercent(int percentA) {
  if (percentA <= 0) return (0, 1);
  if (percentA >= 100) return (1, 0);
  if (percentA == 50) return (1, 1);
  // 同票でない片側優勢を最低 2 票で表現
  final countA = percentA > 50 ? 2 : 1;
  final countB = percentA > 50 ? 1 : 2;
  return (countA, countB);
}

(int countA, int countB) voteCountsForQuestion({
  required int percentA,
  int countA = 0,
  int countB = 0,
}) {
  if (countA > 0 || countB > 0) return (countA, countB);
  return estimateVoteCountsFromPercent(percentA);
}

/// ゲストが新規回答したあとの票数（既存集計 + 自分の 1 票）。
(int countA, int countB) voteCountsAfterGuestAnswer({
  required bool choseA,
  required int baseCountA,
  required int baseCountB,
}) {
  return (
    choseA ? baseCountA + 1 : baseCountA,
    choseA ? baseCountB : baseCountB + 1,
  );
}
