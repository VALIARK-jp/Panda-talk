import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/diagnosis_share_card_data.dart';

class DiagnosisShareCardRenderer {
  const DiagnosisShareCardRenderer._();

  static Future<XFile> render(DiagnosisShareCardData data) async {
    final pandaImage = await _loadAssetImage(data.assetPath);
    final recorder = ui.PictureRecorder();
    const width = 1080.0;
    const height = 1350.0;
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    _paintBackground(canvas, const Size(width, height));
    _paintBackdropShapes(canvas);
    _paintCard(canvas, const Size(width, height), pandaImage, data);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('診断共有カードの画像化に失敗しました');
    }

    return XFile.fromData(
      byteData.buffer.asUint8List(),
      mimeType: 'image/png',
      name: 'panda-talk-${data.slug}.png',
    );
  }

  static Future<ui.Image> _loadAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 620,
      targetHeight: 620,
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFEFE2),
          Color(0xFFFFD7E8),
          Color(0xFFD8F7FF),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  static void _paintBackdropShapes(Canvas canvas) {
    final soft = Paint()..style = PaintingStyle.fill;

    soft.color = const Color(0x33FF8FB1);
    canvas.drawCircle(const Offset(160, 170), 120, soft);

    soft.color = const Color(0x33FFCA5F);
    canvas.drawCircle(const Offset(920, 210), 150, soft);

    soft.color = const Color(0x3349D5FF);
    canvas.drawCircle(const Offset(910, 1090), 180, soft);

    soft.color = const Color(0x3317C964);
    canvas.drawCircle(const Offset(180, 1160), 130, soft);

    final stripe = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x18FFFFFF);
    for (var i = 0; i < 5; i++) {
      final top = 88.0 + (i * 44);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-40, top, 420, 16),
          const Radius.circular(999),
        ),
        stripe,
      );
    }
  }

  static void _paintCard(
    Canvas canvas,
    Size size,
    ui.Image pandaImage,
    DiagnosisShareCardData data,
  ) {
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(84, 94, size.width - 168, size.height - 188),
      const Radius.circular(56),
    );
    canvas.drawRRect(
      shadowRect.shift(const Offset(0, 18)),
      Paint()..color = const Color(0x1F111111),
    );

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(72, 72, size.width - 144, size.height - 188),
      const Radius.circular(56),
    );
    canvas.drawRRect(cardRect, Paint()..color = Colors.white);

    _paintText(
      canvas,
      'あなたの16タイプは',
      const Offset(150, 122),
      maxWidth: 780,
      style: const TextStyle(
        color: Color(0xFF777777),
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );

    _paintText(
      canvas,
      data.displayName,
      const Offset(150, 182),
      maxWidth: 780,
      style: const TextStyle(
        color: Color(0xFF111111),
        fontSize: 86,
        fontWeight: FontWeight.w900,
        height: 1.0,
      ),
    );

    final accentTop = RRect.fromRectAndRadius(
      const Rect.fromLTWH(150, 316, 420, 18),
      const Radius.circular(999),
    );
    canvas.drawRRect(
      accentTop,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF5BC5FF), Color(0xFFFF8DAA)],
        ).createShader(accentTop.outerRect),
    );

    final imageBox = RRect.fromRectAndRadius(
      const Rect.fromLTWH(150, 382, 780, 500),
      const Radius.circular(44),
    );
    canvas.drawRRect(imageBox, Paint()..color = const Color(0xFFF7F7F7));
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(204, 400, 672, 464),
      image: pandaImage,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    _paintText(
      canvas,
      data.tagline,
      const Offset(150, 936),
      maxWidth: 780,
      style: const TextStyle(
        color: Color(0xFF333333),
        fontSize: 46,
        fontWeight: FontWeight.w800,
        height: 1.32,
      ),
    );

    if (data.oddballScore != null) {
      final badgeRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(150, 1078, 324, 78),
        const Radius.circular(999),
      );
      canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFF111111));
      _paintText(
        canvas,
        '異端児スコア ${data.oddballScore}%',
        const Offset(188, 1098),
        maxWidth: 250,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      );
    }

    _paintText(
      canvas,
      'あなたはどのパンダ？',
      const Offset(150, 1186),
      maxWidth: 780,
      style: const TextStyle(
        color: Color(0xFF111111),
        fontSize: 38,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
    );

    _paintText(
      canvas,
      data.shareUrl,
      const Offset(150, 1236),
      maxWidth: 780,
      style: const TextStyle(
        color: Color(0xFF777777),
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
    );

    _paintText(
      canvas,
      '#パンダトーク',
      const Offset(784, 1240),
      maxWidth: 150,
      style: const TextStyle(
        color: Color(0xFF111111),
        fontSize: 26,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
      textAlign: TextAlign.right,
    );
  }

  static void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    required TextStyle style,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }
}
