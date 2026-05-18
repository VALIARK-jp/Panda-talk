import '../config/app_config.dart';

/// API 呼び出し失敗時に画面へ出す文言。
String formatApiUserFacingError(Object error) {
  final msg = error.toString();
  final base = AppConfig.apiBaseUrl.toLowerCase();
  final loopback = base.contains('localhost') || base.contains('127.0.0.1');
  if (!loopback) return msg;

  final networkish = msg.contains('SocketException') ||
      msg.contains('ClientException') ||
      msg.contains('Connection refused') ||
      msg.contains('Connection reset') ||
      msg.contains('Failed host lookup') ||
      msg.contains('Network is unreachable');
  if (!networkish) return msg;

  return '接続できません。\n'
      '・認証（Supabase）は `https://….supabase.co` で、これとは別の API です。\n'
      '・`.env` の `PANDA_TALK_API_BASE_URL` が `localhost` のままだと、'
      '実機では届きません（baselink などと同様、チーム配布の **dev 用 HTTPS URL** を入れる）。\n'
      '・シミュレータで Mac 上の wrangler dev だけ使うときだけ `localhost:8787` でよい。\n\n'
      '詳細: $msg';
}
