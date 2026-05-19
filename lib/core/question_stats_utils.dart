import 'dummy_data.dart';

/// 自分の選択が少数派か（最新の A 側比率に基づく）。
bool isMinorityAnswer({
  required String selected,
  required DummyQuestion question,
  required int percentA,
}) {
  final selectedA = selected == question.optionA;
  final selectedPercent = selectedA ? percentA : (100 - percentA);
  return selectedPercent < 50;
}

int selectedSidePercent({
  required String selected,
  required DummyQuestion question,
  required int percentA,
}) {
  final selectedA = selected == question.optionA;
  return selectedA ? percentA : (100 - percentA);
}
