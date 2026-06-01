// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

void cleanupWebAuthCallbackUrl() {
  final current = Uri.base;
  final cleaned = Uri(
    path: '/panda-talk',
    queryParameters: const <String, String>{},
  );
  if (current.path == cleaned.path &&
      current.queryParameters.isEmpty &&
      (current.fragment.isEmpty)) {
    return;
  }
  html.window.history.replaceState(null, '', cleaned.toString());
}
