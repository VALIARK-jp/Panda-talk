import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Build-time `--dart-define` overrides [dotenv] values from bundled `.env`.
class AppConfig {
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment(
      'PANDA_TALK_API_BASE_URL',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromFile = dotenv.env['PANDA_TALK_API_BASE_URL']?.trim();
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    return 'http://localhost:8787';
  }

  static String get supabaseUrl {
    const fromDefine = String.fromEnvironment(
      'PANDA_TALK_SUPABASE_URL',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['PANDA_TALK_SUPABASE_URL']?.trim() ?? '';
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment(
      'PANDA_TALK_SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['PANDA_TALK_SUPABASE_ANON_KEY']?.trim() ?? '';
  }

  /// Dashboard → Authentication → Redirect URLs must include this exact URI.
  static String get authRedirectUrl {
    const fromDefine = String.fromEnvironment(
      'VALIARK_AUTH_REDIRECT_URL',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromFile = dotenv.env['VALIARK_AUTH_REDIRECT_URL']?.trim();
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    return 'io.valiark.auth://callback';
  }

  static String get lineChannelId {
    const fromDefine = String.fromEnvironment(
      'PANDA_TALK_LINE_CHANNEL_ID',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['PANDA_TALK_LINE_CHANNEL_ID']?.trim() ?? '';
  }

  static String get supabaseFunctionsUrl {
    return supabaseUrl.replaceFirst('.supabase.co', '.functions.supabase.co');
  }

  /// 利用規約（HTTPS）。空のときはアプリ内リンクを出さない／タップで準備中。
  static String get termsOfServiceUrl {
    const fromDefine = String.fromEnvironment(
      'PANDA_TALK_TERMS_URL',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['PANDA_TALK_TERMS_URL']?.trim() ?? '';
  }

  /// プライバシーポリシー（HTTPS）。
  static String get privacyPolicyUrl {
    const fromDefine = String.fromEnvironment(
      'PANDA_TALK_PRIVACY_URL',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['PANDA_TALK_PRIVACY_URL']?.trim() ?? '';
  }
}
