import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a legal document URL in the external browser.
Future<void> openLegalUrl(
  BuildContext context,
  String url,
  String label,
) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('$label の掲載準備中です。')),
    );
    return;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('リンク URL が未設定または不正です。')),
    );
    return;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('ブラウザを開けませんでした')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('ブラウザを開けませんでした: $e')),
      );
    }
  }
}
