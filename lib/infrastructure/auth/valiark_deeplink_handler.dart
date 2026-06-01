import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import 'web_auth_url_cleanup.dart';

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
    final configuredUris = [
      Uri.tryParse(AppConfig.authRedirectUrl),
      Uri.tryParse(AppConfig.webAuthRedirectUrl),
    ];
    for (final configured in configuredUris) {
      if (configured == null) continue;
      if (_matchesConfiguredRedirect(uri, configured)) return true;
    }
    return uri.toString().contains('login-callback');
  }

  static bool _matchesConfiguredRedirect(Uri uri, Uri configured) {
    if (uri.scheme != configured.scheme) return false;
    if (configured.host.isNotEmpty && uri.host != configured.host) return false;

    final configuredPath = configured.path.replaceAll(RegExp(r'/+$'), '');
    final uriPath = uri.path.replaceAll(RegExp(r'/+$'), '');

    if (configuredPath.isNotEmpty && configuredPath != uriPath) return false;
    return true;
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
      if (kIsWeb) {
        normalizeWebAuthCallbackUrl();
      }
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
