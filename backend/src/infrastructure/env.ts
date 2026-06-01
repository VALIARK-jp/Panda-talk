export type Env = {
  SUPABASE_URL?: string
  SUPABASE_ANON_KEY?: string
  SUPABASE_SERVICE_ROLE_KEY?: string
  REPOSITORY_MODE?: 'mock' | 'supabase'
  APP_ENV?: 'development' | 'production'
  /** OGP / canonical URL のベース。dev: Worker 直、prod: valiark.jp/panda-talk */
  SHARE_PUBLIC_BASE_URL?: string
  /** TestFlight または App Store URL。未設定時は App Store 検索へフォールバック。 */
  SHARE_IOS_APP_URL?: string
  /** Google Play URL。未設定時は io.valiark.pandatalk の Play ストアページ。 */
  SHARE_ANDROID_APP_URL?: string
}
