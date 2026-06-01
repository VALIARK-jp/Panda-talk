import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'diagnosis_share_card_data.dart';
import 'dummy_data.dart';
import 'panda_character_assets.dart';
import 'panda_type.dart';
import '../config/app_config.dart';
import '../infrastructure/share/diagnosis_share_card_renderer.dart';

/// 共有URL組み立て（[docs/18_share_growth_spec.md] §4 URL設計）。
///
/// ベース URL は [AppConfig.shareBaseUrl]（`.env` / `.env.prod` で dev/prod を分離）。
/// - dev: `https://panda-talk-backend….workers.dev/share/q/17`（valiark-dev のデータ）
/// - prod: `https://valiark.jp/panda-talk/q/17`（valiark-prod・本番テスター向け）
class ShareUrls {
  const ShareUrls._();

  static String get base => AppConfig.shareBaseUrl;

  static String question(int number) => '$base/q/$number';
  static String pandaType(String slug) => '$base/type/$slug';
  static String user(String usernameOrId) => '$base/u/$usernameOrId';
}

/// SNS向け共有文ビルダ（[docs/18_share_growth_spec.md] §3）。
///
/// 「数字を説明する」のではなく「人格をネタ化する」方針。本人にしか意味のない
/// 数字（回答数 / 投稿数 / 友達数）は載せない。
class ShareTexts {
  const ShareTexts._();

  static const String _hashtag = '#パンダトーク';

  /// 質問共有（拡散の主力）。
  static String question({
    required DummyQuestion q,
    String? selected,
    required int percentA,
    bool isMinority = false,
  }) {
    final percentB = 100 - percentA;
    final lines = <String>[
      'Q. ${q.text}',
      '',
      '${q.optionA} $percentA%',
      '${q.optionB} $percentB%',
      if (selected != null) ...[
        '',
        '私は「$selected」派。',
        isMinority ? 'やっぱり少数派でした。' : '意外と多数派だった。',
      ],
      '',
      'あなたはどっち？',
      ShareUrls.question(q.number),
      '',
      _hashtag,
    ];
    return lines.join('\n');
  }

  /// 診断共有（自己紹介・ネタ化用）。
  static String diagnosis({
    required PandaTypeResult result,
    int? oddballScore,
  }) {
    final lines = <String>[
      '私は「${result.displayName}」でした。',
      '',
      if (result.tagline.isNotEmpty) result.tagline,
      if (oddballScore != null) '異端児スコア $oddballScore%',
      '',
      'あなたはどのパンダ？',
      ShareUrls.pandaType(result.slug),
      '',
      _hashtag,
    ];
    return lines.join('\n');
  }

  /// プロフィール共有（後回し優先度／"名刺"用途）。
  static String profile(DummyProfile profile) {
    final header = profile.hasDiagnosis16
        ? _pandaHeaderLines(profile.pandaTypeSlug!)
        : <String>['@${profile.username}'];
    final lines = <String>[
      ...header,
      '',
      '異端児スコア ${profile.oddballScore}%',
      _oddballFlavor(profile.oddballScore),
      '',
      'あなたも診断する？',
      ShareUrls.user(profile.username),
      '',
      _hashtag,
    ];
    return lines.join('\n');
  }

  /// 回答結果のクイック共有（質問IDが取れない／単独画面用）。
  static String answerResult({
    required String selected,
    required int selectedPercent,
    required bool isMinority,
  }) {
    final flavor = isMinority ? 'やっぱり少数派でした。' : '意外と多数派だった。';
    return <String>[
      '私は「$selected」派。',
      '$flavor（$selectedPercent%）',
      '',
      'あなたはどっち？',
      ShareUrls.base,
      '',
      _hashtag,
    ].join('\n');
  }

  /// マッチ詳細の共有。
  static String matchUser({
    required String displayName,
    required int matchRatePct,
    String? usernameOrId,
  }) {
    final urlLine = usernameOrId == null
        ? ShareUrls.base
        : ShareUrls.user(usernameOrId);
    return <String>[
      '$displayName さんと価値観マッチ $matchRatePct%。',
      '世界観、けっこう近いかも。',
      '',
      'あなたも診断する？',
      urlLine,
      '',
      _hashtag,
    ].join('\n');
  }

  static List<String> _pandaHeaderLines(String slug) {
    final def = PandaTypeCatalog.bySlug(slug);
    if (def == null) return <String>['🐼 $slug'];
    return <String>[
      '🐼 ${def.displayName}',
      if (def.tagline.isNotEmpty) def.tagline,
    ];
  }

  static String _oddballFlavor(int score) {
    if (score >= 80) return 'もう完全にズレてる。';
    if (score >= 60) return '価値観、けっこうズレてました。';
    if (score >= 40) return 'まあまあ世間並み。';
    if (score >= 20) return 'けっこう多数派寄り。';
    return 'ど真ん中の多数派。';
  }
}

class SharePayload {
  const SharePayload({
    required this.text,
    this.title,
    this.diagnosisCard,
  });

  final String text;
  final String? title;
  final DiagnosisShareCardData? diagnosisCard;

  factory SharePayload.text(String text, {String? title}) {
    return SharePayload(text: text, title: title);
  }

  factory SharePayload.diagnosis({
    required PandaTypeResult result,
    int? oddballScore,
  }) {
    final shareUrl = ShareUrls.pandaType(result.slug);
    final assetPath = PandaCharacterAssets.imagePathForSlug(result.slug);
    return SharePayload(
      title: '${result.displayName} を共有',
      text: ShareTexts.diagnosis(result: result, oddballScore: oddballScore),
      diagnosisCard: assetPath == null
          ? null
          : DiagnosisShareCardData(
              slug: result.slug,
              assetPath: assetPath,
              displayName: result.displayName,
              tagline: result.tagline,
              shareUrl: shareUrl,
              oddballScore: oddballScore,
            ),
    );
  }
}

/// 主要SNSへの直行（[docs/18_share_growth_spec.md] §5 Phase 1.5）。
///
/// 追加ライブラリ不要・Web Intent / URL Scheme を url_launcher で叩くだけ。
/// アプリが入っていればX/LINEアプリが開き、未インストールならブラウザに落ちる。
class ShareChannels {
  const ShareChannels._();

  /// X (旧Twitter) の投稿画面を事前入力で開く。
  /// 画像添付はWeb Intent仕様上不可（Phase 4 で share_plus + 画像生成と併用）。
  static Future<bool> openX(String text) async {
    final url = Uri.parse(
      'https://x.com/intent/post?text=${Uri.encodeComponent(text)}',
    );
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// LINE の共有画面を事前入力で開く。
  static Future<bool> openLine(String text) async {
    final url = Uri.parse(
      'https://line.me/R/share?text=${Uri.encodeComponent(text)}',
    );
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

/// ネイティブ共有シート（既存導線・フォールバック）。
class AppShare {
  const AppShare._();

  static Future<void> text(BuildContext context, String text) {
    return content(context, SharePayload.text(text));
  }

  static Future<void> content(BuildContext context, SharePayload payload) async {
    final renderObject = context.findRenderObject();
    final origin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    final diagnosisCard = payload.diagnosisCard;
    if (diagnosisCard != null) {
      final imageFile = await DiagnosisShareCardRenderer.render(diagnosisCard);
      await Share.shareXFiles(
        [imageFile],
        subject: payload.title ?? 'パンダトークをシェア',
        text: payload.text,
        sharePositionOrigin: origin,
      );
      return;
    }

    await Share.share(
      payload.text,
      subject: payload.title ?? 'パンダトークをシェア',
      sharePositionOrigin: origin,
    );
  }
}
