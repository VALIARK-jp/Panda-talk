/// 16type 診断の軸・タイプ定義（[docs/16type.md]）。
enum PandaAxis { affection, thinking, action, life }

class PandaTypeScores {
  const PandaTypeScores({
    required this.affection,
    required this.thinking,
    required this.action,
    required this.life,
  });

  /// 愛情: 安心側の割合（0–100）
  final int affection;

  /// 思考: 感情側の割合
  final int thinking;

  /// 行動: 慎重側の割合
  final int action;

  /// 人生: 理想側の割合
  final int life;

  int percentFor(PandaAxis axis) => switch (axis) {
    PandaAxis.affection => affection,
    PandaAxis.thinking => thinking,
    PandaAxis.action => action,
    PandaAxis.life => life,
  };
}

class PandaTypeDefinition {
  const PandaTypeDefinition({
    required this.slug,
    required this.displayName,
    required this.tagline,
    required this.imageIndex,
    required this.affectionFirst,
    required this.thinkingFirst,
    required this.actionFirst,
    required this.lifeFirst,
  });

  final String slug;
  final String displayName;
  final String tagline;

  /// [assets/images/panda/{imageIndex}.PNG]（[docs/16type.md] の01〜16順）
  final int imageIndex;
  final bool affectionFirst;
  final bool thinkingFirst;
  final bool actionFirst;
  final bool lifeFirst;
}

class PandaTypeResult {
  const PandaTypeResult({
    required this.slug,
    required this.displayName,
    required this.tagline,
    required this.scores,
    this.diagnosedAt,
  });

  final String slug;
  final String displayName;
  final String tagline;
  final PandaTypeScores scores;
  final DateTime? diagnosedAt;

  factory PandaTypeResult.fromJson(Map<String, dynamic> json) {
    final slug = json['pandaTypeSlug'] as String? ?? json['slug'] as String?;
    final def = slug != null ? PandaTypeCatalog.bySlug(slug) : null;
    return PandaTypeResult(
      slug: slug ?? 'nikopan',
      displayName: def?.displayName ?? json['displayName'] as String? ?? 'にこぱん',
      tagline: def?.tagline ?? json['tagline'] as String? ?? '',
      scores: PandaTypeScores(
        affection: (json['typeAffectionPct'] as num?)?.toInt() ??
            (json['affection'] as num?)?.toInt() ??
            50,
        thinking: (json['typeThinkingPct'] as num?)?.toInt() ??
            (json['thinking'] as num?)?.toInt() ??
            50,
        action: (json['typeActionPct'] as num?)?.toInt() ??
            (json['action'] as num?)?.toInt() ??
            50,
        life: (json['typeLifePct'] as num?)?.toInt() ??
            (json['life'] as num?)?.toInt() ??
            50,
      ),
      diagnosedAt: json['diagnosed16At'] != null
          ? DateTime.tryParse(json['diagnosed16At'] as String)
          : null,
    );
  }

  Map<String, dynamic> toApiJson() => {
    'pandaTypeSlug': slug,
    'typeAffectionPct': scores.affection,
    'typeThinkingPct': scores.thinking,
    'typeActionPct': scores.action,
    'typeLifePct': scores.life,
    'diagnosed16At': (diagnosedAt ?? DateTime.now()).toUtc().toIso8601String(),
  };
}

class PandaTypeCatalog {
  const PandaTypeCatalog._();

  static const axisLabels = {
    PandaAxis.affection: ('安心', '刺激'),
    PandaAxis.thinking: ('感情', '論理'),
    PandaAxis.action: ('慎重', '自由'),
    PandaAxis.life: ('理想', '現実'),
  };

  static const types = <PandaTypeDefinition>[
    PandaTypeDefinition(
      slug: 'nikopan',
      displayName: 'にこぱん',
      tagline: '優しすぎて、自分を後回しにする共感型',
      imageIndex: 1,
      affectionFirst: true,
      thinkingFirst: true,
      actionFirst: true,
      lifeFirst: true,
    ),
    PandaTypeDefinition(
      slug: 'yurupan',
      displayName: 'ゆるぱん',
      tagline: '人生ノリでなんとかしてきた自由人',
      imageIndex: 2,
      affectionFirst: false,
      thinkingFirst: true,
      actionFirst: false,
      lifeFirst: true,
    ),
    PandaTypeDefinition(
      slug: 'satoripan',
      displayName: 'さとりぱん',
      tagline: '静かに見守る、現実的な観察者',
      imageIndex: 3,
      affectionFirst: true,
      thinkingFirst: false,
      actionFirst: false,
      lifeFirst: false,
    ),
    PandaTypeDefinition(
      slug: 'bosupan',
      displayName: 'ボスぱん',
      tagline: '結果を出す、論理派リーダー',
      imageIndex: 4,
      affectionFirst: false,
      thinkingFirst: false,
      actionFirst: false,
      lifeFirst: false,
    ),
    PandaTypeDefinition(
      slug: 'mamoripan',
      displayName: 'まもりぱん',
      tagline: '守りたい気持ちが強い、堅実派',
      imageIndex: 5,
      affectionFirst: true,
      thinkingFirst: true,
      actionFirst: true,
      lifeFirst: false,
    ),
    PandaTypeDefinition(
      slug: 'piepan',
      displayName: 'ぴえぱん',
      tagline: '感情豊かで、理想を追う繊細派',
      imageIndex: 6,
      affectionFirst: false,
      thinkingFirst: true,
      actionFirst: true,
      lifeFirst: true,
    ),
    PandaTypeDefinition(
      slug: 'tetsupan',
      displayName: 'てつぱん',
      tagline: '冷静に支える、理想主義の参謀',
      imageIndex: 7,
      affectionFirst: true,
      thinkingFirst: false,
      actionFirst: false,
      lifeFirst: true,
    ),
    PandaTypeDefinition(
      slug: 'hiramekipan',
      displayName: 'ひらめきぱん',
      tagline: 'ひらめきで動く、自由な発想家',
      imageIndex: 8,
      affectionFirst: false,
      thinkingFirst: false,
      actionFirst: false,
      lifeFirst: true,
    ),
    PandaTypeDefinition(
      slug: 'fuwapa',
      displayName: 'ふわぱん',
      tagline: 'ふわっと寄り添う、夢見る癒し系',
      imageIndex: 9,
      affectionFirst: true,
      thinkingFirst: true,
      actionFirst: false,
      lifeFirst: true,
    ),
    PandaTypeDefinition(
      slug: 'tsunpan',
      displayName: 'つんぱん',
      tagline: '素直になれない、論理派ツンデレ',
      imageIndex: 10,
      affectionFirst: false,
      thinkingFirst: false,
      actionFirst: true,
      lifeFirst: false,
    ),
    PandaTypeDefinition(
      slug: 'otapan',
      displayName: 'おたぱん',
      tagline: '好きを極める、慎重な理想主義',
      imageIndex: 11,
      affectionFirst: true,
      thinkingFirst: false,
      actionFirst: true,
      lifeFirst: true,
    ),
    PandaTypeDefinition(
      slug: 'kirapan',
      displayName: 'きらぱん',
      tagline: 'キラキラを追う、自由なムードメーカー',
      imageIndex: 12,
      affectionFirst: false,
      thinkingFirst: true,
      actionFirst: false,
      lifeFirst: false,
    ),
    PandaTypeDefinition(
      slug: 'shigodekipan',
      displayName: 'しごできぱん',
      tagline: '堅実に結果を出す、現実派の仕事人',
      imageIndex: 13,
      affectionFirst: true,
      thinkingFirst: false,
      actionFirst: true,
      lifeFirst: false,
    ),
    PandaTypeDefinition(
      slug: 'amapan',
      displayName: 'あまぱん',
      tagline: '甘え上手で、のんびり現実派',
      imageIndex: 14,
      affectionFirst: true,
      thinkingFirst: true,
      actionFirst: false,
      lifeFirst: false,
    ),
    PandaTypeDefinition(
      slug: 'fushigipan',
      displayName: 'ふしぎぱん',
      tagline: '謎めいた魅力の、感情派インテリア',
      imageIndex: 15,
      affectionFirst: false,
      thinkingFirst: true,
      actionFirst: true,
      lifeFirst: false,
    ),
    PandaTypeDefinition(
      slug: 'kakurepan',
      displayName: 'かくれぱん',
      tagline: '控えめだけど芯のある、理想派',
      imageIndex: 16,
      affectionFirst: false,
      thinkingFirst: false,
      actionFirst: true,
      lifeFirst: true,
    ),
  ];

  static PandaTypeDefinition? bySlug(String slug) {
    for (final t in types) {
      if (t.slug == slug) return t;
    }
    return null;
  }

  static PandaTypeDefinition resolve(PandaTypeScores scores) {
    final affectionFirst = scores.affection >= 50;
    final thinkingFirst = scores.thinking >= 50;
    final actionFirst = scores.action >= 50;
    final lifeFirst = scores.life >= 50;

    for (final t in types) {
      if (t.affectionFirst == affectionFirst &&
          t.thinkingFirst == thinkingFirst &&
          t.actionFirst == actionFirst &&
          t.lifeFirst == lifeFirst) {
        return t;
      }
    }
    return types.first;
  }
}
