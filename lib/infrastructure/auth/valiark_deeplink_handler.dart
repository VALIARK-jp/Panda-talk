import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

/// Cold-start + foreground links for Supabase email confirmation / password-reset (PKCE).
///
/// [Supabase.initialize] では `detectSessionInUri: false` にすること。`true` の場合、
/// パッケージ内蔵のリスナーとここが同じ URI で [AuthClient.getSessionFromUrl] を二度呼び、
/// 「Code verifier could not be found in local storage」になる。
class ValiarkDeeplinkHandler {
  ValiarkDeeplinkHandler._();

  /// 同一 URI を二重に処理しない（initialLink と uriLinkStream の両方が届く端末対策）。
  static final Set<String> _sessionUrlHandled = {};

  /// [supabase_flutter] の PKCE / エラー戻り判定に合わせる（無関係な deep link を除外）。
  static bool isAuthSessionUri(Uri? uri) {
    if (uri == null) return false;
    if (!_isOurAuthHost(uri)) return false;
    final hasPkceCode = uri.queryParameters.containsKey('code');
    final hasImplicitToken =
        uri.fragment.contains('access_token') ||
        uri.fragment.contains('error_description');
    return hasPkceCode || hasImplicitToken;
  }

  static bool _isOurAuthHost(Uri uri) {
    final configured = Uri.tryParse(AppConfig.authRedirectUrl);
    if (configured != null &&
        uri.scheme == configured.scheme &&
        (configured.host.isEmpty || uri.host == configured.host)) {
      return true;
    }
    return uri.toString().contains('login-callback');
  }

  static Future<void> consumeAuthUri(Uri uri) async {
    if (!isAuthSessionUri(uri)) return;

    final key = uri.toString();
    if (!_sessionUrlHandled.add(key)) {
      debugPrint('[ValiarkDeeplink] skip duplicate session uri');
      return;
    }

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      debugPrint('[ValiarkDeeplink] getSessionFromUrl ok');
    } catch (e, st) {
      _sessionUrlHandled.remove(key);
      debugPrint('[ValiarkDeeplink] getSessionFromUrl failed: $e\n$st');
    }
  }

  /// @deprecated [ShareDeeplinkHandler.handleOnce] が AppLinks を一本化して呼ぶ。
  static void handleOnce() {
    // ShareDeeplinkHandler が認証 URI も処理する。
  }
}
