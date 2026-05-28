/// ユーザーコード（username）の共通ルール。
class UsernameRules {
  UsernameRules._();

  static const minLength = 3;
  static const maxLength = 20;

  static final pattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static const validationMessage = 'ユーザーコードは英数字と_のみ、3〜20文字です';

  static String normalize(String username) => username.trim().toLowerCase();

  static bool isValid(String username) =>
      pattern.hasMatch(normalize(username));
}
