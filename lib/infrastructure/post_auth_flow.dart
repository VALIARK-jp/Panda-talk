import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_tokens.dart';
import 'profile_onboarding_store.dart';
import 'providers/repositories.dart';
import '../presentation/providers/auth_providers.dart';
import '../presentation/providers/profile_providers.dart';

/// ログイン成功後: セッション確認 → プロフィール入力済みか判定 → 画面遷移。
class PostAuthFlow {
  PostAuthFlow._();

  static Future<bool> hasSession() async {
    await Supabase.instance.client.auth.refreshSession();
    return Supabase.instance.client.auth.currentSession != null;
  }

  /// DB / メタデータ / 端末キャッシュから「初回プロフィール入力が不要か」を判定する。
  static Future<bool> isProfileSetupComplete(WidgetRef ref) async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    if (userId == null || user == null) return false;

    if (await ProfileOnboardingStore.isCompleted(userId)) {
      return true;
    }

    final provider = user.appMetadata['provider'] as String? ?? 'email';
    try {
      await ref.read(authServiceProvider).ensureBackendProfile(provider: provider);
    } catch (_) {}

    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      if (ProfileOnboardingStore.hasRequiredFieldsFilled(
        username: profile.username,
        name: profile.name,
      )) {
        await ProfileOnboardingStore.setCompleted(userId);
        return true;
      }
    } catch (_) {}

    await ProfileOnboardingStore.applyPendingEmailSignup(
      userId: userId,
      email: user.email,
    );

    return ProfileOnboardingStore.isCompleted(userId);
  }

  /// ログイン処理のあと: プロフィール判定まで終えてからルートへ戻す。
  static Future<void> finishLogin({
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    if (!await hasSession()) {
      throw StateError('ログインに失敗しました。もう一度お試しください。');
    }

    await isProfileSetupComplete(ref);

    if (!context.mounted) return;
    ref.invalidate(authUserProvider);
    ref.invalidate(profileControllerProvider);

    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }

  static Future<T?> withLoading<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    if (!context.mounted) return null;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.black),
      ),
    );
    try {
      return await action();
    } finally {
      if (context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
    }
  }
}
