import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/share_deeplink_providers.dart';
import '../auth/valiark_deeplink_handler.dart';
import 'share_deeplink.dart';

/// Universal Links / App Links で届く共有 URL を [pendingShareRouteProvider] に載せる。
///
/// 認証 PKCE は [ValiarkDeeplinkHandler] が処理するため、ここでは [AppLinks] を1本化して
/// 種別で振り分ける。
class ShareDeeplinkHandler {
  ShareDeeplinkHandler._();

  static bool _started = false;
  static WidgetRef? _ref;

  /// [AuthGate] の post-frame で一度だけ呼ぶ。
  static void bind(WidgetRef ref) {
    _ref = ref;
  }

  static void handleOnce() {
    if (_started) return;
    _started = true;

    if (kIsWeb) {
      _dispatch(Uri.base);
    }

    final appLinks = AppLinks();

    appLinks.getInitialLink().then((Uri? uri) async {
      await _dispatch(uri);
    });

    appLinks.uriLinkStream.listen((Uri? uri) async {
      await _dispatch(uri);
    });
  }

  static Future<void> _dispatch(Uri? uri) async {
    if (uri == null) return;

    if (ValiarkDeeplinkHandler.isAuthSessionUri(uri)) {
      await ValiarkDeeplinkHandler.consumeAuthUri(uri);
      return;
    }

    final route = parseShareUri(uri);
    if (route == null) return;

    final ref = _ref;
    if (ref == null) {
      debugPrint('[ShareDeeplink] ref not bound yet: $uri');
      return;
    }

    debugPrint('[ShareDeeplink] route=$route uri=$uri');
    ref.read(pendingShareRouteProvider.notifier).state = route;
  }
}
