import 'dart:math';

import 'dummy_data.dart';
import 'panda_character_assets.dart';

/// フィード1問ごとのパンダ見た目（スクロールで変わらないよう seed 固定）。
class FeedPandaChoice {
  const FeedPandaChoice._({
    required this.usesDefaultSet,
    this.typeImageIndex,
  });

  /// `default.PNG` / `sleep.PNG` と表情連動。
  final bool usesDefaultSet;

  /// 1–16 の 16type キャラ（[usesDefaultSet] が false のとき）。
  final int? typeImageIndex;

  static FeedPandaChoice forQuestion(DummyQuestion question) {
    final seed = Object.hash(
      question.apiId,
      question.number,
      question.text,
    );
    final rng = Random(seed);
    // 約1/3 はデフォルト系、残りは 16type からランダム
    if (rng.nextInt(3) == 0) {
      return const FeedPandaChoice._(usesDefaultSet: true);
    }
    return FeedPandaChoice._(
      usesDefaultSet: false,
      typeImageIndex: 1 + rng.nextInt(16),
    );
  }

  /// [expression] は `normal` / `minority` / `majority`（デフォルト系のみ反映）。
  String assetPathForExpression(String expression) {
    if (usesDefaultSet) {
      return _defaultAssetForExpression(expression);
    }
    return PandaCharacterAssets.imagePathForIndex(typeImageIndex!);
  }

  static String _defaultAssetForExpression(String expression) {
    switch (expression) {
      case 'minority':
        return 'assets/images/panda/default.PNG';
      case 'majority':
        return 'assets/images/panda/sleep.PNG';
      case 'happy':
      case 'normal':
      default:
        return 'assets/images/panda/default.PNG';
    }
  }
}
