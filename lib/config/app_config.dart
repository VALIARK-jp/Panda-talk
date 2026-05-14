class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'PANDA_TALK_API_BASE_URL',
    defaultValue: 'http://localhost:8787',
  );

  /// valiark-dev: set via `--dart-define=PANDA_TALK_SUPABASE_URL=https://<ref>.supabase.co`
  static const supabaseUrl = String.fromEnvironment(
    'PANDA_TALK_SUPABASE_URL',
    defaultValue: 'https://rothadmykmuxncagbwqd.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'PANDA_TALK_SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJvdGhhZG15a211eG5jYWdid3FkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NTE0NjEsImV4cCI6MjA5NDIyNzQ2MX0.tOx_XbfZXvgzDJEA4s2fqSh73IIKwZLKJI0-QGHPro0',
  );

  /// Shared valiark-dev Auth redirect (same Supabase project for all Valiark apps).
  /// Dashboard → Authentication → Redirect URLs must include this exact URI.
  /// Override per build with `--dart-define=VALIARK_AUTH_REDIRECT_URL=...` if needed.
  static const authRedirectUrl = String.fromEnvironment(
    'VALIARK_AUTH_REDIRECT_URL',
    defaultValue: 'io.valiark.auth://callback',
  );

  static const lineChannelId = String.fromEnvironment(
    'PANDA_TALK_LINE_CHANNEL_ID',
    defaultValue: '',
  );

  static String get supabaseFunctionsUrl {
    return supabaseUrl.replaceFirst('.supabase.co', '.functions.supabase.co');
  }
}
