import 'package:shared_preferences/shared_preferences.dart';

const _kPostLoginWelcomeDone = 'panda_post_login_welcome_v1';

class PostLoginOnboardingStore {
  static Future<bool> isWelcomeCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kPostLoginWelcomeDone) ?? false;
  }

  static Future<void> setWelcomeCompleted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPostLoginWelcomeDone, true);
  }
}
