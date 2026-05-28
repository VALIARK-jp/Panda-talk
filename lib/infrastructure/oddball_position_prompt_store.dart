import 'package:shared_preferences/shared_preferences.dart';

const _guestKey = 'panda_oddball_prompt_guest_v1';

String _userKey(String userId) => 'panda_oddball_prompt_user_$userId';

class OddballPositionPromptStore {
  static Future<int> loadLastShownMilestone({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(userId == null ? _guestKey : _userKey(userId)) ?? 0;
  }

  static Future<void> saveLastShownMilestone(
    int milestone, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(userId == null ? _guestKey : _userKey(userId), milestone);
  }
}
