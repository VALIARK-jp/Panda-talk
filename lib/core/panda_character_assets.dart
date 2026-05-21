import 'panda_type.dart';

/// 16type キャラクター画像（[assets/images/panda/1.PNG]〜16.PNG）。
class PandaCharacterAssets {
  const PandaCharacterAssets._();

  static String imagePathForIndex(int imageIndex) {
    final n = imageIndex.clamp(1, 16);
    return 'assets/images/panda/$n.PNG';
  }

  static String? imagePathForSlug(String? slug) {
    if (slug == null) return null;
    final def = PandaTypeCatalog.bySlug(slug);
    if (def == null) return null;
    return imagePathForIndex(def.imageIndex);
  }
}
