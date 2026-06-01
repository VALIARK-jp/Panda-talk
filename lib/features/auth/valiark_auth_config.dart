/// valiark-dev 上の Valiark 系アプリ共通 LINE Login チャンネル ID（pedal_share とは別）。
///
/// Edge Function の Secret `LINE_CHANNEL_ID` と同じ値に Dashboard で揃える。
/// クライアントの [LineSDK.instance.setup] 用（公開 ID。シークレットは Supabase のみ）。
const valiarkLineChannelId = '2010102462';

/// Panda Talk 専用メール確認 / PKCE リダイレクト（他 Valiark アプリとスキームを分離）。
///
/// `.env` の [pandaTalkAuthRedirectEnvKey]、iOS/Android の URL Types、
/// Supabase Dashboard → Redirect URLs の3か所で同じ値に揃える。
const pandaTalkAuthRedirectUrl = 'io.valiark.pandatalk://callback';

/// Panda Talk Web 専用メール確認 / PKCE リダイレクト。
///
/// 本番は `valiark.jp/panda-talk/auth/callback` に戻す。ローカル Web 検証では
/// `--dart-define` / `.env` で `http://localhost:<port>/auth/callback` を上書きする。
const pandaTalkWebAuthRedirectUrl =
    'https://valiark.jp/panda-talk/auth/callback';

/// [dotenv] / `--dart-define` 用キー名。
const pandaTalkAuthRedirectEnvKey = 'PANDA_TALK_AUTH_REDIRECT_URL';

/// [dotenv] / `--dart-define` 用キー名（Web 専用）。
const pandaTalkWebAuthRedirectEnvKey = 'PANDA_TALK_WEB_AUTH_REDIRECT_URL';
