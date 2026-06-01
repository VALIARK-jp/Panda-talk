import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/share/share_deeplink.dart';

/// [ShareDeeplinkHandler] が受信した共有 URL の遷移先。
/// [MainApp] が消費して null に戻す。
final pendingShareRouteProvider = StateProvider<ShareRoute?>((ref) => null);
