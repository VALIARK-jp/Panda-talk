import 'package:flutter/material.dart';

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
  required String text,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (_) => _ShareActionSheet(text: text),
  );
}

class _ShareActionSheet extends StatelessWidget {
  const _ShareActionSheet({required this.text});

  final String text;

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
                      await ShareChannels.openX(text);
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
                      await ShareChannels.openLine(text);
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
                    onTap: () {
                      Navigator.of(context).pop();
                      AppShare.text(context, text);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.softGray,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                text,
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
