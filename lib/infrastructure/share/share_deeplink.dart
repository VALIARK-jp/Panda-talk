import '../../config/app_config.dart';

/// 共有 URL から解決したアプリ内遷移先。
sealed class ShareRoute {
  const ShareRoute();
}

final class ShareQuestionRoute extends ShareRoute {
  const ShareQuestionRoute(this.questionNumber);

  final int questionNumber;
}

final class ShareUserRoute extends ShareRoute {
  const ShareUserRoute(this.username);

  final String username;
}

final class SharePandaTypeRoute extends ShareRoute {
  const SharePandaTypeRoute(this.slug);

  final String slug;
}

/// `https://valiark.jp/panda-talk/...` および dev Worker `/share/...` を解析する。
ShareRoute? parseShareUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;

  // prod: https://valiark.jp/panda-talk/q/17
  if (_isProdShareHost(uri) &&
      segments.length >= 3 &&
      segments[0] == 'panda-talk') {
    return _routeFromKind(segments[1], segments[2]);
  }

  // dev: https://…workers.dev/share/q/17
  if (_isDevShareHost(uri) &&
      segments.length >= 3 &&
      segments[0] == 'share') {
    return _routeFromKind(segments[1], segments[2]);
  }

  // shareBaseUrl が Worker 直 URL のとき（path が /share/q/17）
  if (_matchesConfiguredShareBase(uri)) {
    if (segments.length >= 3 && segments[0] == 'share') {
      return _routeFromKind(segments[1], segments[2]);
    }
    if (segments.length >= 2 && segments[0] == 'panda-talk') {
      return _routeFromKind(segments[1], segments[2]);
    }
  }

  return null;
}

ShareRoute? _routeFromKind(String kind, String value) {
  switch (kind) {
    case 'q':
      final number = int.tryParse(value);
      if (number == null || number <= 0) return null;
      return ShareQuestionRoute(number);
    case 'u':
      final username = value.trim();
      if (username.isEmpty) return null;
      return ShareUserRoute(username);
    case 'type':
      final slug = value.trim().toLowerCase();
      if (slug.isEmpty) return null;
      return SharePandaTypeRoute(slug);
    default:
      return null;
  }
}

bool _isProdShareHost(Uri uri) {
  return uri.host == 'valiark.jp' || uri.host == 'www.valiark.jp';
}

bool _isDevShareHost(Uri uri) {
  return uri.host.endsWith('.workers.dev');
}

bool _matchesConfiguredShareBase(Uri uri) {
  final base = Uri.tryParse(AppConfig.shareBaseUrl);
  if (base == null) return false;
  if (uri.host != base.host) return false;
  if (base.path.isEmpty || base.path == '/') return true;
  final basePath = base.path.replaceAll(RegExp(r'/+$'), '');
  return uri.path.startsWith(basePath);
}

bool isShareUri(Uri? uri) => parseShareUri(uri) != null;
