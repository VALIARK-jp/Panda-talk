import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_tokens.dart';
import '../valiark_public_info.dart';

/// Created by・ロゴ・共通アカウントの案内（主文＋補足）・姉妹アプリリンク。
class ValiarkAuthNoticeBlock extends StatelessWidget {
  const ValiarkAuthNoticeBlock({
    super.key,
    required this.onLightBackground,
    this.showCreatedByHeader = true,
  });

  /// ログイン画面・メールフォームなど白 / 薄灰背景なら `true`。
  final bool onLightBackground;

  /// `false` にすると「Created by」行だけ省略（メール画面など省スペース用）。
  final bool showCreatedByHeader;

  Color get _muted =>
      onLightBackground ? AppColors.textGray : AppColors.white.withValues(alpha: 0.78);

  Color get _divider =>
      onLightBackground ? AppColors.borderGray : AppColors.white.withValues(alpha: 0.28);

  Color get _linkColor => onLightBackground ? AppColors.black : AppColors.white;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCreatedByHeader) ...[
          Row(
            children: [
              Expanded(child: Container(height: 1, color: _divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Created by',
                  style: TextStyle(
                    color: onLightBackground
                        ? AppColors.textGray
                        : AppColors.white.withValues(alpha: 0.88),
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: _divider)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Center(
          child: SvgPicture.asset(
            'assets/images/logo/valiark_logo_right.svg',
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          valiarkUnifiedAccountLeadJa.trim(),
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: AppFontSize.sm,
            height: 1.5,
            color: onLightBackground ? AppColors.black : AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          valiarkAuthSupplementJa.trim(),
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: AppFontSize.sm,
            height: 1.45,
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (valiarkSisterAppLinks.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 0,
            children: [
              Text(
                'その他のアプリ：',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (var i = 0; i < valiarkSisterAppLinks.length; i++) ...[
                if (i > 0)
                  Text('・', style: TextStyle(fontSize: AppFontSize.sm, color: _muted)),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: _linkColor,
                  ),
                  onPressed: () => _openLink(context, valiarkSisterAppLinks[i].uri),
                  child: Text(
                    valiarkSisterAppLinks[i].title,
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: _linkColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openLink(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('リンクを開けませんでした')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('リンクを開けませんでした: $e')),
        );
      }
    }
  }
}
