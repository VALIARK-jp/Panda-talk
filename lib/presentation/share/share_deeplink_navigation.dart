import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/dummy_data.dart';
import '../../core/panda_type.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../infrastructure/share/share_deeplink.dart';
import '../../screens/match/user_detail_screen.dart';
import '../../widgets/diagnosis_16_result_modal.dart';
import '../providers/feed_window_controller.dart';

Future<void> navigateShareRoute(
  BuildContext context,
  WidgetRef ref, {
  required ShareRoute route,
  required VoidCallback openDiagnosisTab,
}) async {
  switch (route) {
    case ShareQuestionRoute(:final questionNumber):
      openDiagnosisTab();
      await openQuestionInFeed(ref, questionNumber: questionNumber);
    case ShareUserRoute(:final username):
      await _openUserProfile(context, ref, username);
    case SharePandaTypeRoute(:final slug):
      await _openPandaTypePreview(context, slug);
  }
}

Future<void> _openUserProfile(
  BuildContext context,
  WidgetRef ref,
  String username,
) async {
  if (Supabase.instance.client.auth.currentUser == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('プロフィールを見るにはログインが必要です')),
    );
    return;
  }

  final user = await _resolveUserByUsername(ref, username);
  if (!context.mounted) return;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ユーザー @$username が見つかりませんでした')),
    );
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => UserDetailScreen(user: user),
    ),
  );
}

Future<void> _openPandaTypePreview(BuildContext context, String slug) async {
  final result = PandaTypeCatalog.previewResultForSlug(slug);
  if (!context.mounted) return;

  if (result == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('パンダタイプが見つかりませんでした')),
    );
    return;
  }

  await showDiagnosis16ResultModal(context, result);
}

Future<DummyUser?> _resolveUserByUsername(
  WidgetRef ref,
  String username,
) async {
  try {
    return await ref
        .read(friendRepositoryProvider)
        .findUserByUsername(username);
  } catch (_) {
    return null;
  }
}
