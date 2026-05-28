/// 合致度（一致問数 / 共通回答問数）を整数パーセントに変換する。
int matchRatePercent({
  required int sameAnswerCount,
  required int commonAnswerCount,
}) {
  if (commonAnswerCount <= 0) return 0;
  return (sameAnswerCount / commonAnswerCount * 100).round();
}
