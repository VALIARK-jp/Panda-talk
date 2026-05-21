import 'panda_type.dart';

/// 初回16問の配点・表示ラベル（正本: [docs/16type_questions.md]）。
class Diagnosis16Mapping {
  const Diagnosis16Mapping._();

  static const measureLabels = <int, String>{
    1: '恋愛距離感',
    2: '人生観',
    3: '共感性',
    4: '行動スタイル',
    5: '思考人格',
    6: '刺激耐性',
    7: '行動制御',
    8: '価値観',
    9: '対人スタイル',
    10: '行動人格',
    11: '恋愛人格',
    12: '判断基準',
    13: '夢・安定',
    14: '感情耐性',
    15: '衝動性',
    16: '社会意識',
  };

  static String measureLabel(int questionNumber) =>
      measureLabels[questionNumber] ?? '診断';

  /// 選択肢ごとの加点。`isFirstPole` = 軸の第一極（安心・感情・慎重・理想）。
  static List<DiagnosisWeight> weightsFor(int questionNumber, bool choseA) {
    return choseA ? _weightsA[questionNumber]! : _weightsB[questionNumber]!;
  }

  static const _weightsA = <int, List<DiagnosisWeight>>{
    1: [DiagnosisWeight(PandaAxis.affection, true, 5)],
    2: [DiagnosisWeight(PandaAxis.life, true, 5)],
    3: [DiagnosisWeight(PandaAxis.thinking, true, 5)],
    4: [DiagnosisWeight(PandaAxis.action, true, 5)],
    5: [DiagnosisWeight(PandaAxis.thinking, true, 6)],
    6: [DiagnosisWeight(PandaAxis.affection, true, 4)],
    7: [DiagnosisWeight(PandaAxis.action, true, 5)],
    8: [DiagnosisWeight(PandaAxis.life, true, 5)],
    9: [DiagnosisWeight(PandaAxis.thinking, true, 5)],
    10: [DiagnosisWeight(PandaAxis.action, true, 6)],
    11: [DiagnosisWeight(PandaAxis.affection, true, 7)],
    12: [
      DiagnosisWeight(PandaAxis.thinking, true, 2),
      DiagnosisWeight(PandaAxis.life, true, 3),
    ],
    13: [DiagnosisWeight(PandaAxis.life, true, 5)],
    14: [DiagnosisWeight(PandaAxis.thinking, true, 5)],
    15: [
      DiagnosisWeight(PandaAxis.action, false, 3),
      DiagnosisWeight(PandaAxis.affection, false, 2),
    ],
    16: [
      DiagnosisWeight(PandaAxis.thinking, true, 4),
      DiagnosisWeight(PandaAxis.affection, true, 2),
    ],
  };

  static const _weightsB = <int, List<DiagnosisWeight>>{
    1: [DiagnosisWeight(PandaAxis.affection, false, 5)],
    2: [DiagnosisWeight(PandaAxis.life, false, 5)],
    3: [DiagnosisWeight(PandaAxis.thinking, false, 5)],
    4: [DiagnosisWeight(PandaAxis.action, false, 5)],
    5: [DiagnosisWeight(PandaAxis.thinking, false, 6)],
    6: [DiagnosisWeight(PandaAxis.affection, false, 4)],
    7: [DiagnosisWeight(PandaAxis.action, false, 5)],
    8: [DiagnosisWeight(PandaAxis.life, false, 5)],
    9: [DiagnosisWeight(PandaAxis.thinking, false, 5)],
    10: [DiagnosisWeight(PandaAxis.action, false, 6)],
    11: [DiagnosisWeight(PandaAxis.affection, false, 7)],
    12: [
      DiagnosisWeight(PandaAxis.thinking, false, 2),
      DiagnosisWeight(PandaAxis.life, false, 3),
    ],
    13: [DiagnosisWeight(PandaAxis.life, false, 5)],
    14: [DiagnosisWeight(PandaAxis.thinking, false, 5)],
    15: [DiagnosisWeight(PandaAxis.action, true, 5)],
    16: [
      DiagnosisWeight(PandaAxis.thinking, false, 3),
      DiagnosisWeight(PandaAxis.life, false, 3),
    ],
  };
}

class DiagnosisWeight {
  const DiagnosisWeight(this.axis, this.isFirstPole, this.points);

  final PandaAxis axis;
  final bool isFirstPole;
  final int points;
}
