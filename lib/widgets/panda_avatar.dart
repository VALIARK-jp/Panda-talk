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

  const PandaMascot({super.key, this.size = 240, this.expression = 'normal'});

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

/// 寝そべりポーズ（オンボーディング用）
class PandaSleep extends StatelessWidget {
  final double size;

  const PandaSleep({super.key, this.size = 240});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.6,
      child: Image.asset(
        'assets/images/panda/sleep.PNG',
        fit: BoxFit.contain,
      ),
    );
  }
}
