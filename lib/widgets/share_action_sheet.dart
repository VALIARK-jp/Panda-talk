import 'package:flutter/material.dart';

import '../core/diagnosis_share_card_data.dart';
import '../core/design_tokens.dart';
import '../core/share_utils.dart';

/// X / LINE / ネイティブシート の3チャネルから選んで共有させるボトムシート。
///
/// 仕様: [docs/18_share_growth_spec.md] §5 Phase 1.5 (主要SNSへの直行ボタン)
///
/// - X / LINE: アプリ未インストール時はブラウザに落ちる（Web Intent / Share URL）
/// - その他: `share_plus` のネイティブ共有シート（Instagram DM/フィード, Threads,
///   Mail, メッセージ, AirDrop 等を含む）
Future<void> showShareActionSheet(
  BuildContext context, {
  required SharePayload payload,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (_) => _ShareActionSheet(payload: payload),
  );
}

class _ShareActionSheet extends StatelessWidget {
  const _ShareActionSheet({required this.payload});

  final SharePayload payload;

  static const _xBg = AppColors.black;
  static const _xFg = AppColors.white;
  static const _lineBg = Color(0xFF06C755);
  static const _lineFg = AppColors.white;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'シェアする',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ChannelTile(
                    label: 'Xに投稿',
                    iconLabel: '𝕏',
                    background: _xBg,
                    foreground: _xFg,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ShareChannels.openX(payload.text);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ChannelTile(
                    label: 'LINEに送る',
                    iconLabel: 'LINE',
                    background: _lineBg,
                    foreground: _lineFg,
                    iconFontSize: 16,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ShareChannels.openLine(payload.text);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ChannelTile(
                    label: 'その他',
                    icon: Icons.ios_share,
                    background: AppColors.softGray,
                    foreground: AppColors.black,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await AppShare.content(context, payload);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (payload.diagnosisCard != null) ...[
              _DiagnosisPreview(card: payload.diagnosisCard!),
              const SizedBox(height: AppSpacing.md),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.softGray,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                payload.text,
                style: const TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textGray,
                  textStyle: const TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('キャンセル'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosisPreview extends StatelessWidget {
  const _DiagnosisPreview({required this.card});

  final DiagnosisShareCardData card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF0E6),
            Color(0xFFFFE2EE),
            Color(0xFFE3F7FF),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: 72,
              height: 72,
              color: AppColors.white,
              padding: const EdgeInsets.all(6),
              child: Image.asset(card.assetPath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.displayName,
                  style: const TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    height: 1.4,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'X / LINE はこのキャラ画像のリンクプレビュー、その他は画像カード付きで共有します。',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.icon,
    this.iconLabel,
    this.iconFontSize = 24,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final IconData? icon;
  final String? iconLabel;
  final double iconFontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: foreground, size: 24)
                : Text(
                    iconLabel ?? '',
                    style: TextStyle(
                      fontSize: iconFontSize,
                      fontWeight: FontWeight.w900,
                      color: foreground,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
