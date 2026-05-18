import 'package:shared_preferences/shared_preferences.dart';

const _kProfileSetupPrefix = 'panda_profile_setup_done_v1_';
const _kPendingEmailSignup = 'panda_pending_profile_setup_email_v1';

/// ユーザーごとに初回プロフィール入力が済んだかを端末に保存する。
class ProfileOnboardingStore {
  static String _key(String userId) => '$_kProfileSetupPrefix$userId';

  static Future<bool> isCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId)) ?? false;
  }

  static Future<void> setCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId), true);
  }

  /// 新規登録直後は必ずプロフィール入力へ（メール確認後の初回ログイン含む）。
  static Future<void> requireSetup(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }

  /// メール確認待ちの新規登録（セッション未発行）用。
  static Future<void> markPendingEmailSignup(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingEmailSignup, email.trim().toLowerCase());
  }

  /// 確認メールから初回ログインしたときに [requireSetup] を有効化する。
  static Future<void> applyPendingEmailSignup({
    required String userId,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(_kPendingEmailSignup);
    if (pending == null) return;
    if (email != null && email.trim().toLowerCase() != pending) return;
    await requireSetup(userId);
    await prefs.remove(_kPendingEmailSignup);
  }
}
