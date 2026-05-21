import 'dummy_data.dart';
import 'oddball_score.dart';

/// 自分の選択が少数派か（最新の A/B 票数に基づく。DB と同一ルール）。
bool isMinorityAnswer({
  required String selected,
  required DummyQuestion question,
  int? countA,
  int? countB,
}) {
  final selectedA = selected == question.optionA;
  final counts = voteCountsForQuestion(
    percentA: question.percentA,
    countA: countA ?? question.countA,
    countB: countB ?? question.countB,
  );
  return isMinorityChoice(
    choseA: selectedA,
    countA: counts.$1,
    countB: counts.$2,
  );
}

/// [selectedA] が true なら A 側を選んだときの少数派判定。
bool isMinorityFromSide({
  required bool selectedA,
  required int percentA,
  int countA = 0,
  int countB = 0,
}) {
  final counts = voteCountsForQuestion(
    percentA: percentA,
    countA: countA,
    countB: countB,
  );
  return isMinorityChoice(
    choseA: selectedA,
    countA: counts.$1,
    countB: counts.$2,
  );
}

int selectedSidePercent({
  required String selected,
  required DummyQuestion question,
  required int percentA,
}) {
  final selectedA = selected == question.optionA;
  return selectedA ? percentA : (100 - percentA);
}
