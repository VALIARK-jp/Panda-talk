import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Same idea as `pedal_share/lib/shared/services/deeplink_handler.dart`:
/// cold-start + foreground links for Supabase email confirmation / password-reset (PKCE).
///
/// [supabase_flutter] also observes [AppLinks]; this duplicates handling intentionally
/// so initial links are less likely to be missed on some devices (pedal_share pattern).
class ValiarkDeeplinkHandler {
  ValiarkDeeplinkHandler._();

  static bool _started = false;

  /// valiark-dev shared redirect ([AppConfig.authRedirectUrl]) and legacy path names.
  static bool isAuthCallbackUri(Uri? uri) {
    if (uri == null) return false;
    final s = uri.toString();
    if (uri.scheme == 'io.valiark.auth') return true;
    if (s.contains('login-callback')) return true;
    return false;
  }

  static Future<void> _consumeAuthUri(Uri uri) async {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      debugPrint('[ValiarkDeeplink] getSessionFromUrl ok');
    } catch (e, st) {
      debugPrint('[ValiarkDeeplink] getSessionFromUrl failed: $e\n$st');
    }
  }

  /// Call once from a [StatefulWidget] `didChangeDependencies` (e.g. [AuthGate]).
  static void handleOnce() {
    if (_started) return;
    _started = true;

    final appLinks = AppLinks();

    appLinks.getInitialLink().then((Uri? uri) async {
      if (!isAuthCallbackUri(uri)) return;
      await _consumeAuthUri(uri!);
    });

    appLinks.uriLinkStream.listen((Uri? uri) async {
      if (!isAuthCallbackUri(uri)) return;
      await _consumeAuthUri(uri!);
    });
  }
}
