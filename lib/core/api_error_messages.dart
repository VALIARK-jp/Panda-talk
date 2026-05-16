import '../config/app_config.dart';

/// API 呼び出し失敗時に画面へ出す文言。[AppConfig.apiBaseUrl] がループバックで
/// 接続エラーのときは、実機開発向けのヒントを付与する。
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
      '・ローカル API（Worker）が起動しているか確認してください。\n'
      '・実機では localhost はこの端末自身を指します。`.env` の '
      'PANDA_TALK_API_BASE_URL を Mac の LAN IP（例: http://192.168.0.12:8787）'
      'にしてください。Worker は `WRANGLER_DEV_IP=0.0.0.0` で待ち受けると '
      'LAN から届きやすいです（backend の dev スクリプト参照）。\n\n'
      '詳細: $msg';
}
