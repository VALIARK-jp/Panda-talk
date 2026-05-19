import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class AppShare {
  const AppShare._();

  static void text(BuildContext context, String text) {
    final renderObject = context.findRenderObject();
    final origin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    Share.share(text, sharePositionOrigin: origin);
  }
}
