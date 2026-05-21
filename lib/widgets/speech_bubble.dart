import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

enum SpeechBubbleVariant { light, dark }

enum SpeechBubbleTail {
  /// 下中央（上の要素＝パンダへ向ける）
  bottomCenter,
  /// 下左（パンダ右上あたりからの吹き出し）
  bottomLeft,
  /// 左上（右下の要素へ）
  topLeft,
}

/// 白黒ミニマルの吹き出し（三角しっぽ付き）。
class SpeechBubble extends StatelessWidget {
  final String text;
  final SpeechBubbleVariant variant;
  final SpeechBubbleTail tail;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final int maxLines;

  const SpeechBubble({
    super.key,
    required this.text,
    this.variant = SpeechBubbleVariant.light,
    this.tail = SpeechBubbleTail.bottomLeft,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.maxLines = 4,
  });

  Color get _bg =>
      variant == SpeechBubbleVariant.dark ? AppColors.black : AppColors.white;

  Color get _fg => variant == SpeechBubbleVariant.dark
      ? AppColors.white
      : AppColors.black;

  Border? get _border => variant == SpeechBubbleVariant.light
      ? Border.all(color: AppColors.borderGray)
      : null;

  @override
  Widget build(BuildContext context) {
    final body = Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: textStyle ??
          TextStyle(
            fontSize: AppFontSize.md,
            fontWeight: FontWeight.w600,
            color: _fg,
            height: 1.4,
          ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _columnAlign,
      children: [
        if (_tailOnTop) _BubbleTail(variant: variant, tail: tail),
        Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: _border,
            boxShadow: variant == SpeechBubbleVariant.dark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: body,
        ),
        if (!_tailOnTop) _BubbleTail(variant: variant, tail: tail),
      ],
    );
  }

  bool get _tailOnTop =>
      tail == SpeechBubbleTail.topLeft;

  CrossAxisAlignment get _columnAlign {
    switch (tail) {
      case SpeechBubbleTail.bottomCenter:
        return CrossAxisAlignment.center;
      case SpeechBubbleTail.bottomLeft:
      case SpeechBubbleTail.topLeft:
        return CrossAxisAlignment.start;
    }
  }
}

class _BubbleTail extends StatelessWidget {
  final SpeechBubbleVariant variant;
  final SpeechBubbleTail tail;

  const _BubbleTail({required this.variant, required this.tail});

  @override
  Widget build(BuildContext context) {
    final color =
        variant == SpeechBubbleVariant.dark ? AppColors.black : AppColors.white;
    final borderColor = AppColors.borderGray;

    Alignment align;
    switch (tail) {
      case SpeechBubbleTail.bottomCenter:
        align = Alignment.center;
      case SpeechBubbleTail.bottomLeft:
      case SpeechBubbleTail.topLeft:
        align = Alignment.centerLeft;
    }

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: CustomPaint(
          size: const Size(14, 8),
          painter: _TailPainter(
            color: color,
            borderColor: variant == SpeechBubbleVariant.light ? borderColor : null,
            pointsDown: tail != SpeechBubbleTail.topLeft,
          ),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  final Color? borderColor;
  final bool pointsDown;

  _TailPainter({
    required this.color,
    this.borderColor,
    required this.pointsDown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width / 2, 0);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);

    if (borderColor != null && pointsDown) {
      final stroke = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawLine(Offset.zero, Offset(size.width / 2, size.height), stroke);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width / 2, size.height), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _TailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointsDown != pointsDown;
}
