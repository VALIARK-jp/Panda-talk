import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_tokens.dart';
import '../core/dummy_data.dart';
import '../infrastructure/moderation_repository.dart';
import '../screens/match/user_detail_screen.dart';
import 'report_content_sheet.dart';

/// 投稿カードの投稿者アイコンタップ時: プロフィール閲覧 or 投稿通報。
Future<void> showPosterActionSheet(
  BuildContext context, {
  required WidgetRef ref,
  required DummyQuestion question,
}) {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  final authorId = question.authorUserId;
  final isSelf = authorId != null && authorId == currentUserId;
  final canOpenProfile = authorId != null && authorId.isNotEmpty;
  final canReport =
      !isSelf && question.apiId != null && question.apiId!.isNotEmpty;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.black),
              title: const Text(
                'プロフィールを見る',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              enabled: canOpenProfile,
              onTap: canOpenProfile
                  ? () {
                      Navigator.pop(sheetContext);
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => UserDetailScreen(
                            user: DummyUser(
                              id: authorId,
                              name: question.authorName,
                              matchRate: 0,
                              avatarUrl: question.authorAvatarUrl,
                            ),
                            fromMatch: false,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            if (canReport)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.textGray),
                title: const Text(
                  'この投稿を通報する',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showReportContentSheet(
                    context,
                    ref: ref,
                    targetType: ReportTargetType.question,
                    targetId: question.apiId!,
                    subjectLabel: question.text,
                  );
                },
              ),
            ListTile(
              title: const Text(
                'キャンセル',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      );
    },
  );
}
