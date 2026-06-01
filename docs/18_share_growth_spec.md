# 18. SNS共有・ディープリンク試作仕様

> ブランチ: `feature/share-deeplink-growth`
> ステータス: **Phase 1〜3 実装済み / デプロイ・実機 UL 検証は未完了**
> 関連: `02_features.md` / `09_screens.md` / `17_marketing.md`
> 最終更新: 2026-05-28（Phase 3 実装 + 引き継ぎメモ）

---

## 0. このドキュメントの目的

パンダトークの SNS 共有機能を、単なる「URL文字列のシェア」から
**「見た人が自分も答えたくなる共有」** に進化させるための設計ドラフトを残す。

- 共有文 / 画像 / URL / ディープリンク / OGP / 未インストール時動線をワンセットで扱う
- 実装フェーズを切る（小さく出して、最後は BeReal 級のループに到達する）
- 議論内容を仕様として固定し、後続実装の判断軸にする

---

## 1. 議論の出発点（現状の弱さ）

今の共有は「情報」を出していて、「感情」と「参加したくなる導線」が出ていない。
パンダトークなら共有の主役は数字そのものではなく、
**自分がどんなやつか** と **世間とどれだけズレたか**。

### 現状の共有導線と弱点

| 種別 | 該当箇所 | 現状の出力 | 弱さ |
|---|---|---|---|
| 診断共有 | `lib/screens/post/diagnosis_16_result_modal.dart` (line 122付近) | 「愛情 60% 思考 40% ...」の数値列 | SNS では情報過多で刺さらない |
| プロフィール共有 | `lib/screens/profile/profile_screen.dart` (line 276付近) | 回答数 / 投稿数 / 友達数 / 異端児スコア | 本人以外には意味が薄い |
| 質問共有 | `lib/screens/home/question_feed_screen.dart` (line 367付近) | 比較的近い | 「押したくなる文」までは寄せ切れていない |

### 技術的な前提

- `share_plus` は導入済み
- `app_links` も導入済み（**認証用 deep link 処理で既に使用中**）
- 共有文の入口は3か所に既にある
- つまり「ライブラリ導入」ではなく「共有の中身と URL ハンドリング設計」が本体タスク

---

## 2. 最終的に目指す体験

> Xで見かける → 自分も答えたくなる → アプリを開く → 同じ質問に回答 → また共有する

このループを作るのがゴール。BeReal の Instagram/X 共有導線が参考イメージ。

### 完成形イメージ

1. アプリ内の共有ボタンを押す
2. iOS の共有シートが開く（Instagram / X / LINE / メッセージ）
3. 共有された投稿は **画像カード + 短い人格文 + URL** の3点セット
4. リンクを踏むと:
   - **アプリ未インストール** → `valiark.jp/panda-talk/q/17` の LP → 「アプリで回答する」→ App Store
   - **アプリインストール済み** → アプリ起動 → Q17 の画面へ直行（Universal Links）
5. 答え終わったらまた共有 → ループ

---

## 3. 共有文フォーマット（最優先・全面刷新）

数字を説明するのではなく、**人格をネタ化する**。
回答数 18 は弱いが、異端児スコア 72% は使える。これは「ゲームのステータス」として見せられるから。

### 3-1. 質問共有（拡散の主力）

```
Q. SNSで一番嫌なのは？

既読無視 67%
炎上すること 33%

私は「既読無視」派。
意外と多数派だった。

あなたはどっち？
https://valiark.jp/panda-talk/q/17

#パンダトーク
```

### 3-2. 診断共有（自己紹介・ネタ化用）

```
私は「ふしぎぱん」でした。

現実に馴染めない夜型芸術家。
異端児スコア 72%

当たりすぎてちょっと怖い。

あなたはどのパンダ？
https://valiark.jp/panda-talk/type/fushigipan

#パンダトーク
```

### 3-3. プロフィール共有（後回し可・"名刺"扱い）

```
🐼 ふしぎぱん
現実に馴染めない夜型芸術家

異端児スコア 72%
価値観、けっこうズレてました。

https://valiark.jp/panda-talk/u/panda_042fdd

#パンダトーク
```

### 共通ルール

- 共有文の末尾に **必ず URL** を入れる
- ハッシュタグは `#パンダトーク` 固定（拡散導線用）
- 文中の数字は「人格ステータス」として読めるものだけ採用（異端児スコア / 割合）
- 回答数・投稿数・友達数のような「本人にしか意味がない数字」は SNS共有文には載せない

---

## 4. URL 設計（確定）

ドメイン取得コストを避け、既存資産（Vercel/`valiark.jp` + Cloudflare Worker `panda-talk-backend`）に乗せる方針で確定。`pandatalk.app` は将来必要になれば乗せ替え可能な設計。

### 4-1. パスの形

| パス | 内容 |
|---|---|
| `https://valiark.jp/panda-talk/q/:number` | 質問（`questionNumber` を使う） |
| `https://valiark.jp/panda-talk/u/:username` | プロフィール |
| `https://valiark.jp/panda-talk/type/:slug` | 16type 診断タイプ（例: `fushigipan`） |

### 4-2. クエリパラメータ

- 必要なら `?from=share` を付けて流入経路を識別（Phase 2 実装時点ではクリーンURLで運用）
- 計測用に `?ref=<userId>` 等の拡張余地も残す（後決め）

### 4-3. 配信スタック

```
【prod】SNS共有URL: https://valiark.jp/panda-talk/q/17
            ↓
Vercel (legal-site, valiark.jp)  … 本番テスター・TestFlight 向け
            ↓  vercel.json rewrite → prod Worker
https://panda-talk-backend-prod.valiark.workers.dev/share/q/17
            ↓
valiark-prod Supabase

【dev】日常開発の共有文:
https://panda-talk-backend.valiark.workers.dev/share/q/17
            ↓
dev Worker 直（valiark.jp は触らない）
            ↓
valiark-dev Supabase
```

**dev/prod 分離（重要）**

| 環境 | アプリ設定 | 共有URL | Worker | DB |
|---|---|---|---|---|
| dev | `.env` | `{API_BASE}/share/q/17` | `panda-talk-backend` | valiark-dev |
| prod | `.env.prod` | `valiark.jp/panda-talk/q/17` | `panda-talk-backend-prod` | valiark-prod |

Flutter: `PANDA_TALK_SHARE_BASE_URL`（[AppConfig.shareBaseUrl](../lib/config/app_config.dart)）  
Worker: `SHARE_PUBLIC_BASE_URL`（`npm run deploy` / `deploy:prod` で注入）

**valiark.jp の rewrite は prod Worker のみ向ける。** dev デプロイで本番 URL を上書きしない。

---

## 5. 実装フェーズ

レベルを切って、段階的に出す。

### Phase 1 — 共有文の刷新 ✅ 実装済み

- `lib/core/share_utils.dart` — `ShareUrls` / `ShareTexts` / `AppShare`
- 共有文を §3 形式に刷新（診断 / 質問 / プロフィール / 回答結果 / ユーザ詳細）
- URL ベースは [AppConfig.shareBaseUrl](../lib/config/app_config.dart)（dev/prod 分離）

### Phase 1.5 — 主要SNSへの直行ボタン ✅ 実装済み

BeReal の「Instagram / X に直接送る」UI を踏襲する。
**現在の依存関係（`share_plus` / `url_launcher` / `flutter_line_sdk`）だけで実装可能**。
実装: `lib/widgets/share_action_sheet.dart` / `lib/core/share_utils.dart`（`ShareChannels`）

#### 共有シートUIの想定

```
[ X ]  [ LINE ]  [ Instagram ]  [ その他... ]
                                     ↑
                                share_plus のネイティブシート（フォールバック）
```

最後の「その他...」を残しておけば、メール / メッセージ / AirDrop / Threads など
非主要チャネルも全部カバーできる。

#### SNS別の実装方針

| 宛先 | 方式 | 実装コスト | 画像対応 | メモ |
|---|---|---|---|---|
| **X (旧Twitter)** | Web Intent URL を `url_launcher` で開く | 低（即着手） | ✕（仕様で不可） | アプリ入ってればXアプリが開く |
| **LINE** | `line://msg/text/...` または `https://line.me/R/share?text=...` | 低（即着手） | △（テキスト共有は容易） | `flutter_line_sdk` は認証用だが共有は URL Scheme で十分 |
| **Instagram Stories** | `instagram-stories://share` URL Scheme | 中（画像必須） | ◯（必須） | Phase 4 の画像生成とセット。`Info.plist` に `LSApplicationQueriesSchemes` 追加が必要 |
| **その他** | `share_plus` の `Share.share(text)` | （実装済み） | – | フォールバックとして必ず残す |

#### X 直行の例

```dart
final text = Uri.encodeComponent('Q. SNSで一番嫌なのは？\n\n私は「既読無視」派。\nあなたはどっち？');
final url = Uri.encodeComponent('https://valiark.jp/panda-talk/q/17');
final hashtags = Uri.encodeComponent('パンダトーク');

final intent = Uri.parse(
  'https://x.com/intent/post?text=$text&url=$url&hashtags=$hashtags',
);
await launchUrl(intent, mode: LaunchMode.externalApplication);
```

- `x.com/intent/post` が現行エンドポイント（旧 `twitter.com/intent/tweet` でも可）
- アプリインストール済みなら自動でXアプリが開く
- 画像添付は Web Intent では不可なので、画像出したい時は `share_plus` 経由になる

#### LINE 直行の例

```dart
final body = Uri.encodeComponent(
  'Q. SNSで一番嫌なのは？\n\n私は「既読無視」派。\nあなたはどっち？\nhttps://valiark.jp/panda-talk/q/17',
);
final lineUrl = Uri.parse('https://line.me/R/share?text=$body');
await launchUrl(lineUrl, mode: LaunchMode.externalApplication);
```

#### Instagram Stories 直行（Phase 4 とセット）

- 背景画像 or ステッカー画像が必須
- `Info.plist` に追記:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>instagram-stories</string>
  <string>instagram</string>
</array>
```

- `share_plus` の `SharePlus.instance.share(ShareParams(files: [...]))` でも代用可能
- 完全な Stories 直行体験を狙う場合は `MethodChannel` 経由でネイティブ呼び出し

#### 実装範囲のまとめ

- **Phase 4 と一緒に出すもの**: Instagram Stories 直行（画像必須なので）

### Phase 2 — Web 受け皿（valiark.jp/panda-talk）✅ コード実装済み（本番反映は一部未）

**配信スタック**:
- ドメイン: `valiark.jp/panda-talk/...`（既存 Vercel）
- 配信先: Cloudflare Worker `panda-talk-backend` を Vercel rewrite で proxy
- データ: 既存 backend と同じ `createContainer` 経由で Supabase 取得
- HTML テンプレ: `<head>` に OGP メタタグ直書き + 最小LP + App Store/Web CTA

**実装ファイル**:
- `backend/src/presentation/share/html.ts` — OGP HTML テンプレ + CTA
- `backend/src/presentation/share/pandaTypes.ts` — Flutter `PandaTypeCatalog` のミラー
- `backend/src/presentation/routes/share.ts` — `/share/q/:n` `/share/u/:user` `/share/type/:slug`
- `backend/src/domain/usecases/questions/GetQuestionByNumberUseCase.ts` — 新規
- `backend/src/domain/usecases/users/GetUserByUsernameUseCase.ts` — 新規
- `backend/src/domain/repositories/IQuestionRepository.ts` — `findByNumber` 追加
- `legal-site/vercel.json` — `/panda-talk/q/:id` 等の rewrite を Worker に proxy

**残課題（Phase 2 の本番運用）**:
- [x] **dev Worker デプロイ** — `https://panda-talk-backend.valiark.workers.dev/share/q/:n` で OGP/LP 確認済み
- [ ] **prod Worker デプロイ** — `npm run deploy:prod`（本番 DB 向け・ユーザー判断待ち）
- [ ] **Vercel デプロイ** — `legal-site/` を main 反映（`valiark.jp/panda-talk/*` rewrite + `.well-known`）
- [ ] **OGP 画像の差し替え**（現状は `Icon-512.png` を流用。1200×630 推奨）
- [ ] **App Store / TestFlight URL** — Worker env `SHARE_IOS_APP_URL` / LP の iOS CTA
- [ ] **LP 細部** — iOS ボタン常時表示・ブランドアイコン差し替え（`html.ts` 修正済み、dev 再デプロイ要確認）

### Phase 3 — ディープリンク受信（アプリ側）✅ コード実装済み（UL/App Links 検証は未）

**方針（GoRouter は未導入）**: 既存の `MaterialApp` + `Navigator` + Riverpod のまま、`app_links` で受信 → `pendingShareRouteProvider` → `MainApp` が画面遷移。

| 受信 URL | アプリ内動作 | ログイン |
|---|---|---|
| `…/panda-talk/q/:number` または `…/share/q/:number` | ホームタブ → `openQuestionInFeed` | 不要（ゲスト可） |
| `…/panda-talk/type/:slug` | `showDiagnosis16ResultModal`（タイプ紹介） | 不要 |
| `…/panda-talk/u/:username` | `UserDetailScreen` を push | **必要** |

**Flutter 実装ファイル**:
- `lib/infrastructure/share/share_deeplink.dart` — URI 解析（prod / dev Worker 両対応）
- `lib/infrastructure/share/share_deeplink_handler.dart` — `app_links` 受信（認証 PKCE と一本化）
- `lib/presentation/providers/share_deeplink_providers.dart` — `pendingShareRouteProvider`
- `lib/presentation/share/share_deeplink_navigation.dart` — 画面遷移実行
- `lib/presentation/auth_gate.dart` — ハンドラ起動
- `lib/screens/main_app.dart` — pending route の消費
- `lib/infrastructure/auth/valiark_deeplink_handler.dart` — 認証 URI のみ処理（`ShareDeeplinkHandler` から委譲）
- `lib/core/panda_type.dart` — `PandaTypeCatalog.previewResultForSlug`
- `lib/infrastructure/friend_repository.dart` / `api_friend_repository.dart` — `findUserByUsername`

**ネイティブ / Web 設定（コード追加済み・デプロイ/Portal 作業は未）**:
- `ios/Runner/Runner.entitlements` — `applinks:valiark.jp`
- `android/app/src/main/AndroidManifest.xml` — App Links intent-filter
- `legal-site/.well-known/apple-app-site-association`
- `legal-site/.well-known/assetlinks.json`（**SHA256 はプレースホルダ**）
- `legal-site/vercel.json` — `.well-known` の Content-Type ヘッダー

**残課題（Phase 3 の本番検証）** — 詳細は §10:
- [ ] Vercel デプロイで AASA / assetlinks を公開
- [ ] Apple Developer: App ID `com.valiark.pandaTalk` で Associated Domains 有効化 → 再プロビジョン → 再ビルド
- [ ] Android: `assetlinks.json` に実署名 SHA256 を填入
- [ ] iOS 実機で Universal Links E2E（Notes 等からタップ）
- [ ] Android 実機で App Links E2E

工数感（議論時の見立て）:

| レベル | 内容 | 工数 |
|---|---|---|
| L1 | 共有文に通常URLを入れる | 低（即着手） |
| L1.5 | X / LINE 直行ボタン（`url_launcher` で Web Intent / URL Scheme を叩く） | 低（即着手・追加ライブラリ不要） |
| L2 | アプリがそのURLを受けて画面遷移 | 中（半日〜1日） |
| L3 | 未インストール時はWeb/ストア、インストール済みなら該当画面へ | 中〜大（1日以上） |
| L3.5 | Instagram Stories 直行（画像生成とセット） | 中（画像レンダリングが本体） |
| OGP | XやLINEでカード表示 | 別レイヤー（Web側タスク） |

### Phase 4 — 画像共有カード

- アプリ内でカード画像を生成して `share_plus` 経由でファイル共有
- 質問カード:
  - 質問文 / 自分の選択 / みんなの割合（白黒バー） / パンダ / 「あなたはどっち？」
- 診断カード:
  - パンダタイプの絵 / 一言キャラ説明 / 異端児スコア
- Instagram ストーリー対応も将来的に検討（`SharePlus.shareXFiles` で画像直接シェア）

---

## 6. 画像共有 と OGP の整理

混同しがちなので分けて定義する。

| 項目 | 担当 | 強み | コスト |
|---|---|---|---|
| 画像共有 | アプリ側でカード画像を生成 → ファイル共有 | X / LINE / Instagram に強い。「一目で伝わる絵」が出せる | 画像レンダリング実装が必要 |
| OGP | Web側（`valiark.jp/panda-talk`）が `og:*` メタを返す | URLを貼っただけで自動サムネ | Phase 2 で実装済み |

両方やるのが理想。順序としては **画像共有が先に効く**（パンダキャラと診断文脈の親和性が高いため）。
OGP は Web 側準備が必要なので、Phase 2 のWeb受け皿と同時に進める。

---

## 7. 優先順位の確認

1. **質問共有**（拡散の主力 / 他人がそのまま参加できる）
2. **診断共有**（自己紹介・ネタ化 / SNSで強い）
3. プロフィール共有（後回しでよい / 他人には文脈が薄い）

> 質問と診断は他人がそのまま参加できる。プロフィールは本人の名刺。
> なので最初に手を入れるのは質問共有と診断共有。

---

## 8. 次の一手（2026-05-28 時点）

**完了**: Phase 1 / 1.5 / 2（コード）/ 3（コード）

**次に人がやること（優先順）**:

1. **Vercel デプロイ**（`legal-site/`）— rewrite + AASA + assetlinks を `valiark.jp` に載せる
2. **Apple Developer** — Associated Domains ON → 実機/TestFlight 再ビルド
3. **Android assetlinks** — 署名 SHA256 を填入
4. **iOS 実機 UL 検証** — §10 手順（`flutter run` だけでは不可）
5. **prod Worker デプロイ** — 本番テスター向け LP/OGP（判断が出たら）
6. **Phase 4** — 画像カード + Instagram Stories

---

## 9. 実機テストの整理（特に iOS）

### `flutter run` だけでは Universal Links は試せない

| やりたいこと | `flutter run`（実機） | 追加で必要なもの |
|---|---|---|
| アプリ内の共有ボタン → 共有文に URL が入る | ✅ 可 | なし |
| dev Worker URL をブラウザで開く → OGP/LP | ✅ 可（URL を直接開く） | dev Worker デプロイ済み |
| **リンクをタップ → アプリが開く（UL）** | ❌ 不可 | AASA 公開 + Associated Domains + 再インストール |
| **URL 受信後の画面遷移ロジック**（Phase 3） | △ 限定的 | 下記「遷移だけ試す方法」 |

**理由（iOS）**:
- Universal Links は **OS が `valiark.jp` の AASA を読み、別アプリ（Notes / X 等）からのタップ** で初めて発火する
- `flutter run` はアプリを起動するだけで、**HTTPS URL を OS 経由で注入しない**
- Safari のアドレスバー直打ちも Universal Link にならない（Apple 仕様）

### 遷移ロジックだけ試す方法

| 環境 | 方法 |
|---|---|
| **iOS Simulator** | アプリ起動後: `xcrun simctl openurl booted "https://valiark.jp/panda-talk/q/17"` |
| **iOS 実機（UL なし）** | 実質むずかしい。**AASA デプロイ後に Notes からタップ** が現実的 |
| **Android 実機** | `adb shell am start -a android.intent.action.VIEW -d "https://valiark.jp/panda-talk/q/17" com.pandatalk.panda_talk`（UL 検証前でも遷移確認しやすい） |

### iOS 実機で Universal Links を通すチェックリスト

1. [ ] `legal-site` を Vercel デプロイ
2. [ ] `curl -I https://valiark.jp/.well-known/apple-app-site-association` が 200 + JSON
3. [ ] Apple Developer → App ID `com.valiark.pandaTalk` → **Associated Domains** 有効
4. [ ] Xcode で再ビルド（Team `6KX9X2UAGT`）→ 実機に**再インストール**
5. [ ] Notes に `https://valiark.jp/panda-talk/q/17` を貼り**タップ**（Safari アドレスバーでは不可）
6. [ ] アプリ起動 → ホームタブで Q17 付近へジャンプすること

**bundle / team（固定値）**:
- Bundle ID: `com.valiark.pandaTalk`
- Team ID: `6KX9X2UAGT`
- AASA `appID`: `6KX9X2UAGT.com.valiark.pandaTalk`

---

## 10. 引き継ぎチェックリスト（担当者向け）

### いま repo に入っているもの

| 領域 | 状態 |
|---|---|
| 共有文・X/LINE 直行 | ✅ マージ前ブランチ上で実装済み |
| Worker `/share/*` + OGP HTML | ✅ 実装済み / dev デプロイ済み |
| Flutter ディープリンク受信〜遷移 | ✅ 実装済み |
| `legal-site/vercel.json` rewrite | ✅ コードあり / **Vercel 未反映の可能性** |
| `.well-known`（AASA / assetlinks） | ✅ ファイルあり / **Vercel 未反映** |
| iOS entitlements | ✅ コードあり / **Portal + 再ビルド要** |
| Android App Links | ✅ Manifest あり / **assetlinks SHA256 要填入** |

### 担当者が順にやること

#### A. Web（Vercel + 任意 prod Worker）

```bash
# legal-site を valiark.jp に反映（main merge + Vercel auto deploy または手動）
# 確認
curl -sS https://valiark.jp/.well-known/apple-app-site-association | head
curl -I https://valiark.jp/panda-talk/q/17
```

- [ ] `legal-site/vercel.json` が production に載っている
- [ ] AASA / assetlinks が 404 ではない
- [ ] （本番 LP 用）`backend && npm run deploy:prod` — **prod 判断後**

#### B. iOS（Universal Links）

- [ ] [Apple Developer](https://developer.apple.com) → Identifiers → `com.valiark.pandaTalk` → Associated Domains ✓
- [ ] Xcode → Signing 再生成 → Archive / TestFlight または実機 Run
- [ ] 実機に**新ビルドを再インストール**（AASA はインストール時に取得）
- [ ] Notes から `https://valiark.jp/panda-talk/q/17` をタップして E2E

#### C. Android（App Links）

- [ ] 署名証明書の SHA256 を取得:
  ```bash
  keytool -list -v -keystore <keystore> -alias <alias>
  ```
- [ ] `legal-site/.well-known/assetlinks.json` の `REPLACE_WITH_RELEASE_OR_DEBUG_SHA256` を差し替え → Vercel 再デプロイ
- [ ] 実機インストール後:
  ```bash
  adb shell pm get-app-links com.pandatalk.panda_talk
  ```
- [ ] `adb shell am start …` またはブラウザタップで E2E

#### D. アプリ設定（テスター向け）

| 用途 | `.env` / ビルド | 共有 URL |
|---|---|---|
| 日常 dev | `.env` | `https://panda-talk-backend….workers.dev/share/...` |
| TestFlight / 本番テスター | `.env.prod` | `https://valiark.jp/panda-talk/...` |

- [ ] TestFlight ビルドは `PANDA_TALK_SHARE_BASE_URL=https://valiark.jp/panda-talk` でビルド
- [ ] UL 検証は **valiark.jp URL のみ**（workers.dev は AASA 対象外）

#### E. 未着手（Phase 4 以降）

- [ ] 質問 / 診断の画像カード生成 + `share_plus` ファイル共有
- [ ] Instagram Stories 直行（`Info.plist` `LSApplicationQueriesSchemes`）
- [ ] OGP 専用画像 1200×630
- [ ] 流入計測 `?from=share` / analytics

### 既知の制約・仕様

- `/u/:username` 深リンクは **API が認証必須** → 未ログイン時は Snackbar「ログインが必要」
- ナビは **GoRouter なし**（`MainApp` + `Navigator.push`）
- 認証 PKCE と共有 URL は **同一 `AppLinks` リスナー**（二重 `getSessionFromUrl` 防止済み）
- dev 共有 URL（workers.dev）はアプリ内解析はするが **Universal Links にはならない**

---

## 11. 参考: BeReal の共有導線

- アプリ内に Instagram / X への共有導線がある
- 押すとそのSNSの投稿画面に直行
- 普通のリンクでも、踏めばインストール導線 → 投稿/プロフィール表示まで連結
- パンダトークでもこの一気通貫を最終形として狙う
