import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../features/auth/valiark_auth_config.dart';

/// Build-time `--dart-define` overrides [dotenv] values from bundled `.env`.
class AppConfig {
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment(
      'PANDA_TALK_API_BASE_URL',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return _normalizeApiBaseUrl(fromDefine);
    final fromFile = dotenv.env['PANDA_TALK_API_BASE_URL']?.trim();
    if (fromFile != null && fromFile.isNotEmpty) {
      return _normalizeApiBaseUrl(fromFile);
    }
    return 'http://localhost:8787';
  }

  /// `localhost:8787` のように scheme 抜けを補正（`No host specified in URI` 防止）。
  static String _normalizeApiBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return 'http://localhost:8787';
    if (!value.contains('://')) {
      final isLocal =
          value.startsWith('localhost') || value.startsWith('127.0.0.1');
      value = '${isLocal ? 'http' : 'https'}://$value';
    }
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  /// `localhost` / `127.0.0.1` 向け（Mac 上の wrangler dev）。実機からは届かない。
  static bool get usesLocalApiHost {
    final base = apiBaseUrl.toLowerCase();
    return base.contains('localhost') || base.contains('127.0.0.1');
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
      pandaTalkAuthRedirectEnvKey,
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromFile = dotenv.env[pandaTalkAuthRedirectEnvKey]?.trim();
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    return pandaTalkAuthRedirectUrl;
  }

  /// Dashboard → Authentication → Redirect URLs must include this exact URI.
  static String get webAuthRedirectUrl {
    const fromDefine = String.fromEnvironment(
      pandaTalkWebAuthRedirectEnvKey,
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromFile = dotenv.env[pandaTalkWebAuthRedirectEnvKey]?.trim();
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    return pandaTalkWebAuthRedirectUrl;
  }

  /// Redirect URL selected for the current platform.
  static String get effectiveAuthRedirectUrl {
    return kIsWeb ? webAuthRedirectUrl : authRedirectUrl;
  }

  /// LINE SDK 用（公開 ID）。未設定時は [valiarkLineChannelId]（valiark-dev 共通）。
  static String get lineChannelId {
    const fromDefine = String.fromEnvironment(
      'PANDA_TALK_LINE_CHANNEL_ID',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromFile = dotenv.env['PANDA_TALK_LINE_CHANNEL_ID']?.trim();
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    return valiarkLineChannelId;
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

  /// SNS共有URLのベース。
  ///
  /// - dev (`.env`): Worker 直 `https://…-backend….workers.dev/share`
  /// - prod (`.env.prod` / TestFlight): `https://valiark.jp/panda-talk`
  ///
  /// 未設定時は [apiBaseUrl]/share にフォールバック（dev と同じ Worker を指す）。
  static String get shareBaseUrl {
    const fromDefine = String.fromEnvironment(
      'PANDA_TALK_SHARE_BASE_URL',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) {
      return fromDefine.replaceAll(RegExp(r'/+$'), '');
    }
    final fromFile = dotenv.env['PANDA_TALK_SHARE_BASE_URL']?.trim();
    if (fromFile != null && fromFile.isNotEmpty) {
      return fromFile.replaceAll(RegExp(r'/+$'), '');
    }
    if (usesLocalApiHost) {
      return '$apiBaseUrl/share';
    }
    return '$apiBaseUrl/share';
  }
}
