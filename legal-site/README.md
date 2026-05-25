# Panda Talk legal site

Vercel の Root Directory に `legal-site` を指定してデプロイするための静的サイトです。

## 公開パス

- `/panda-talk`
- `/panda-talk/privacy_policy`
- `/panda-talk/terms_of_service`

## 想定URL

- `https://valiark.jp/panda-talk/privacy_policy`
- `https://valiark.jp/panda-talk/terms_of_service`

## Vercel 設定

1. Project Settings の `Root Directory` を `legal-site` に設定
2. Framework Preset は `Other`
3. Build Command は空欄
4. Output Directory は空欄
5. Domain に `valiark.jp` を割り当てる

## 補足

- `vercel.json` で `/panda-talk/...` の rewrite を定義しています。
- 法務文書を更新する場合は、`docs/legal/*.md` とこのサイトの HTML を両方更新してください。
