import 'package:flutter/material.dart';

class PandaAvatar extends StatelessWidget {
  final double size;

  const PandaAvatar({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/panda/default.PNG',
        fit: BoxFit.contain,
      ),
    );
  }
}

/// 通常立ちポーズ（質問フィード・回答後など）
class PandaMascot extends StatelessWidget {
  final double size;
  final String expression;

  /// 指定時は [expression] より優先（16type キャラなど）。
  final String? assetPath;

  const PandaMascot({
    super.key,
    this.size = 240,
    this.expression = 'normal',
    this.assetPath,
  });

  static String assetForExpression(String expression) {
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

  @override
  Widget build(BuildContext context) {
    final asset = assetPath ?? assetForExpression(expression);
    final shrinkForSleep =
        assetPath == null && expression == 'majority';
    final height = shrinkForSleep ? size * 0.85 : size;

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(asset, fit: BoxFit.contain, height: height),
    );
  }
}

/// 寝そべりポーズ（オンボーディング用）
class PandaSleep extends StatelessWidget {
  final double size;

  const PandaSleep({super.key, this.size = 240});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.6,
      child: Image.asset('assets/images/panda/sleep.PNG', fit: BoxFit.contain),
    );
  }
}
