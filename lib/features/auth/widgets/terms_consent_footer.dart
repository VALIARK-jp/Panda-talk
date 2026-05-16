import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import '../../../core/design_tokens.dart';

/// 利用規約・プライバシーポリシーへの同意（本文＋リンク）。
///
/// URL は [AppConfig.termsOfServiceUrl] / [AppConfig.privacyPolicyUrl]（`.env` または dart-define）。
class TermsConsentFooter extends StatelessWidget {
  const TermsConsentFooter({super.key, required this.onLightBackground});

  final bool onLightBackground;

  Color get _body =>
      onLightBackground ? AppColors.textGray : AppColors.white.withValues(alpha: 0.82);

  Color get _link => onLightBackground ? AppColors.black : AppColors.white;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'パンダトークは VALIARK合同会社（以下「当社」）が提供するサービスです。'
          '本サービスをご利用になるには、当社が定める利用規約およびプライバシーポリシーに同意いただく必要があります。'
          'ログインまたは新規登録を完了した時点で、当該規約・ポリシーの内容を理解し、これに同意したものとみなします。',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: AppFontSize.sm,
            height: 1.45,
            color: _body,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 0,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: _link,
              ),
              onPressed: () => _openUrl(
                context,
                AppConfig.termsOfServiceUrl,
                '利用規約',
              ),
              child: Text(
                '利用規約を読む',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationColor: _link.withValues(alpha: 0.35),
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: _link,
              ),
              onPressed: () => _openUrl(
                context,
                AppConfig.privacyPolicyUrl,
                'プライバシーポリシー',
              ),
              child: Text(
                'プライバシーポリシーを読む',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationColor: _link.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String url, String label) async {
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
}
