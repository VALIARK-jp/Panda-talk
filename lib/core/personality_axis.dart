import 'panda_type.dart';

/// 性格・傾向の1軸（16type専用ではなく、将来100問規模の分析にも流用）。
class PersonalityAxisDefinition {
  const PersonalityAxisDefinition({
    required this.id,
    required this.displayName,
    required this.firstPoleLabel,
    required this.secondPoleLabel,
  });

  final String id;
  final String displayName;
  final String firstPoleLabel;
  final String secondPoleLabel;
}

/// 1軸のスコア表示用（第一極の割合 0–100）。
class PersonalityAxisScore {
  const PersonalityAxisScore({
    required this.definition,
    required this.firstPolePercent,
  });

  final PersonalityAxisDefinition definition;
  final int firstPolePercent;

  int get secondPolePercent => 100 - firstPolePercent;
}

/// 現在アプリで表示する軸のレジストリ（将来ここに軸を追加可能）。
class PersonalityAxisRegistry {
  const PersonalityAxisRegistry._();

  static const affection = PersonalityAxisDefinition(
    id: 'affection',
    displayName: '愛情',
    firstPoleLabel: '安心',
    secondPoleLabel: '刺激',
  );
  static const thinking = PersonalityAxisDefinition(
    id: 'thinking',
    displayName: '思考',
    firstPoleLabel: '感情',
    secondPoleLabel: '論理',
  );
  static const action = PersonalityAxisDefinition(
    id: 'action',
    displayName: '行動',
    firstPoleLabel: '慎重',
    secondPoleLabel: '自由',
  );
  static const life = PersonalityAxisDefinition(
    id: 'life',
    displayName: '人生',
    firstPoleLabel: '理想',
    secondPoleLabel: '現実',
  );

  /// v1: 16type の4軸。将来はサーバー定義や別ソースに差し替え可能。
  static const List<PersonalityAxisDefinition> activeAxes = [
    affection,
    thinking,
    action,
    life,
  ];

  static List<PersonalityAxisScore> scoresFromPandaType(PandaTypeScores scores) {
    return [
      PersonalityAxisScore(
        definition: affection,
        firstPolePercent: scores.affection,
      ),
      PersonalityAxisScore(
        definition: thinking,
        firstPolePercent: scores.thinking,
      ),
      PersonalityAxisScore(
        definition: action,
        firstPolePercent: scores.action,
      ),
      PersonalityAxisScore(
        definition: life,
        firstPolePercent: scores.life,
      ),
    ];
  }

  static List<PersonalityAxisScore> scoresFromProfileFields({
    required int? affectionPct,
    required int? thinkingPct,
    required int? actionPct,
    required int? lifePct,
  }) {
    if (affectionPct == null ||
        thinkingPct == null ||
        actionPct == null ||
        lifePct == null) {
      return const [];
    }
    return scoresFromPandaType(
      PandaTypeScores(
        affection: affectionPct,
        thinking: thinkingPct,
        action: actionPct,
        life: lifePct,
      ),
    );
  }
}
