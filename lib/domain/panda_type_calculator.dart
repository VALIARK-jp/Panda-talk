import '../core/diagnosis_16_mapping.dart';
import '../core/panda_type.dart';

/// 16問の回答（question_number → Aを選んだか）から加重スコアとタイプを算出。
class PandaTypeCalculator {
  const PandaTypeCalculator._();

  static PandaTypeResult compute(Map<int, bool> choseOptionAByQuestion) {
    final firstPoints = <PandaAxis, int>{
      for (final axis in PandaAxis.values) axis: 0,
    };
    final secondPoints = <PandaAxis, int>{
      for (final axis in PandaAxis.values) axis: 0,
    };

    for (final entry in choseOptionAByQuestion.entries) {
      final number = entry.key;
      if (number < 1 || number > 16) continue;
      final weights = Diagnosis16Mapping.weightsFor(number, entry.value);
      for (final w in weights) {
        if (w.isFirstPole) {
          firstPoints[w.axis] = firstPoints[w.axis]! + w.points;
        } else {
          secondPoints[w.axis] = secondPoints[w.axis]! + w.points;
        }
      }
    }

    int pct(PandaAxis axis) {
      final first = firstPoints[axis]!;
      final second = secondPoints[axis]!;
      final total = first + second;
      if (total == 0) return 50;
      return ((first / total) * 100).round();
    }

    final scores = PandaTypeScores(
      affection: pct(PandaAxis.affection),
      thinking: pct(PandaAxis.thinking),
      action: pct(PandaAxis.action),
      life: pct(PandaAxis.life),
    );

    final def = PandaTypeCatalog.resolve(scores);
    return PandaTypeResult(
      slug: def.slug,
      displayName: def.displayName,
      tagline: def.tagline,
      scores: scores,
      diagnosedAt: DateTime.now(),
    );
  }
}
