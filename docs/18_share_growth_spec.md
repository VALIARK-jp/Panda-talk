# 18. SNS共有・ディープリンク試作仕様

> ブランチ: `feature/share-deeplink-growth`
> ステータス: **試作（議論ログ兼仕様ドラフト）**
> 関連: `02_features.md` / `09_screens.md` / `17_marketing.md`

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
SNS共有URL: https://valiark.jp/panda-talk/q/17
            ↓
Vercel (legal-site, valiark.jp)
            ↓  vercel.json rewrite
https://panda-talk-backend.valiark.workers.dev/share/q/17
            ↓
Cloudflare Worker (Hono, panda-talk-backend)
            ↓
Supabase REST から該当データ取得
            ↓
OGP メタ付き HTML を返す
            ↓
SNSクローラは og:* を読む / 人間は LP を見る
```

- **ドメイン**: `valiark.jp/panda-talk/...`（既存 Vercel）
- **Web受け皿**: Vercel が `/panda-talk/q/:id` `/panda-talk/u/:username` `/panda-talk/type/:slug` を Cloudflare Worker に rewrite proxy
- **Worker側のルート**: `/share/q/:number` `/share/u/:username` `/share/type/:slug`
- **データ取得**: 既存の `createContainer` 経由でユースケース呼び出し（`getQuestionByNumberUseCase` / `getQuestionStatsUseCase` / `getUserByUsernameUseCase`）
- **共存**: 既存の `https://valiark.jp/panda-talk` (Flutter Web LP) と `/panda-talk/privacy_policy` 等は温存

---

## 5. 実装フェーズ

レベルを切って、段階的に出す。

### Phase 1 — 共有文の刷新（最優先・低コスト）

- `diagnosis_16_result_modal.dart` の共有テキストを §3-2 形式に
- `question_feed_screen.dart` の共有テキストを §3-1 形式に
- `profile_screen.dart` の共有テキストを §3-3 形式に
- すべての共有文の末尾に `https://valiark.jp/panda-talk/...` を入れる
- この段階ではアプリ内遷移は不要。**通常URLとして貼られればOK**

> ここが一番費用対効果が高い。すぐ着手。

### Phase 1.5 — 主要SNSへの直行ボタン（BeReal 型導線）

BeReal の「Instagram / X に直接送る」UI を踏襲する。
**現在の依存関係（`share_plus` / `url_launcher` / `flutter_line_sdk`）だけで実装可能**。
追加ライブラリはゼロ。

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

- **Phase 1.5 で出すもの**: X 直行ボタン / LINE 直行ボタン / ネイティブシート（既存）
- **Phase 4 と一緒に出すもの**: Instagram Stories 直行（画像必須なので）

### Phase 2 — Web 受け皿（valiark.jp/panda-talk）✅ 実装済み

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

**残課題（Phase 2 完了の前にやる）**:
- [ ] **Worker のデプロイ**（`backend && npm run deploy`）— コードはマージしたが本番反映が必要
- [ ] **Vercel デプロイ**（`legal-site/vercel.json` の更新を反映）
- [ ] **OGP 画像の差し替え**（現状は `Icon-512.png` を流用。X の summary_large_image は 1200×630 推奨）
- [ ] **App Store URL の差し込み**（`APP_LINKS.appStoreUrl` 空欄）— TestFlight 段階のため未確定

### Phase 3 — ディープリンク受信（アプリ側）

- Universal Links (iOS) / App Links (Android) の設定
- `app_links` で `https://valiark.jp/panda-talk/q/:id` 等を受信
- `GoRouter` で該当画面に直接遷移
- データ未取得時のローディング・404 ハンドリングを定義

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

## 8. 次の一手

1. §3 のフォーマットで既存3つの共有文を書き換える（Phase 1）
2. §4 の URL 設計を確定（チーム合意）
3. X 直行 / LINE 直行ボタンを既存共有導線に追加（Phase 1.5・追加ライブラリ不要）
4. `valiark.jp/panda-talk/q/:id` の最小 LP + OGP を用意（Phase 2）
5. `app_links` の認証以外のパス受信を追加し、`GoRouter` に流す（Phase 3）
6. 質問カード画像生成 → `share_plus` で画像付き共有 / Instagram Stories 直行（Phase 4）

---

## 9. 参考: BeReal の共有導線

- アプリ内に Instagram / X への共有導線がある
- 押すとそのSNSの投稿画面に直行
- 普通のリンクでも、踏めばインストール導線 → 投稿/プロフィール表示まで連結
- パンダトークでもこの一気通貫を最終形として狙う
