import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../infrastructure/diagnosis_16_store.dart';
import '../infrastructure/profile_onboarding_store.dart';
import '../infrastructure/question_progress_store.dart';
import '../infrastructure/providers/repositories.dart';
import 'providers/auth_providers.dart';
import 'providers/comment_providers.dart';
import 'providers/diagnosis_providers.dart';
import 'providers/friend_providers.dart';
import 'providers/match_providers.dart';
import 'providers/moderation_providers.dart';
import 'providers/notification_providers.dart';
import 'providers/post_providers.dart';
import 'providers/profile_providers.dart';
import 'providers/question_providers.dart';
import 'providers/settings_providers.dart';
import 'providers/talk_providers.dart';
import 'providers/user_profile_providers.dart';

/// ログアウト・別アカウントログインのたびに増やし、[MainApp] 等を丸ごと作り直す。
final appSessionEpochProvider = StateProvider<int>((ref) => 0);

bool hasValidAuthSession() {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return false;
  return !session.isExpired;
}

bool didAuthUserChange(User? previous, User? next) => previous?.id != next?.id;

/// ユーザー依存の Riverpod 状態をすべて捨て、画面が前アカウントのデータを出さないようにする。
void resetSessionScopedState(
  WidgetRef ref, {
  bool clearGuestMode = false,
}) {
  ref.read(feedJumpToQuestionNumberProvider.notifier).state = null;

  ref.invalidate(questionFeedControllerProvider);
  ref.invalidate(feedWindowControllerProvider);
  ref.invalidate(feedBootstrapProvider);
  ref.invalidate(profileControllerProvider);
  ref.invalidate(diagnosis16UnlockedProvider);
  ref.invalidate(questionHistoryProvider);
  ref.invalidate(currentQuestionProvider);
  ref.invalidate(similarUsersProvider);
  ref.invalidate(oppositeUsersProvider);
  ref.invalidate(middleUsersProvider);
  ref.invalidate(compareAnswersProvider);
  ref.invalidate(groupsProvider);
  ref.invalidate(directThreadsProvider);
  ref.invalidate(groupMessagesProvider);
  ref.invalidate(directMessagesProvider);
  ref.invalidate(friendControllerProvider);
  ref.invalidate(notificationControllerProvider);
  ref.invalidate(unreadNotificationCountProvider);
  ref.invalidate(settingsControllerProvider);
  ref.invalidate(questionPostControllerProvider);
  ref.invalidate(commentControllerProvider);
  ref.invalidate(userProfileProvider);
  ref.invalidate(moderationControllerProvider);

  ref.read(appSessionEpochProvider.notifier).update((n) => n + 1);

  if (clearGuestMode) {
    ref.read(guestModeProvider.notifier).state = false;
  }
}

Future<void> performSignOut(WidgetRef ref) async {
  await ref.read(authServiceProvider).signOut();
  resetSessionScopedState(ref, clearGuestMode: true);
}

/// サーバー上のアカウント削除 → 端末データ削除 → ログアウト。
Future<void> performAccountDeletion(WidgetRef ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  await ref.read(profileRepositoryProvider).deleteAccount();
  if (userId != null) {
    await QuestionProgressStore.clearForUser(userId);
    await ProfileOnboardingStore.clearLocalForUser(userId);
  }
  await Diagnosis16Store.clear();
  try {
    await ref.read(authServiceProvider).signOut();
  } catch (_) {
    // サーバー側で auth ユーザー削除済みのときはローカル signOut が失敗することがある
  }
  resetSessionScopedState(ref, clearGuestMode: true);
}
