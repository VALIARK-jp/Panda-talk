import 'web_auth_url_cleanup_stub.dart'
    if (dart.library.html) 'web_auth_url_cleanup_web.dart';

void normalizeWebAuthCallbackUrl() {
  cleanupWebAuthCallbackUrl();
}
