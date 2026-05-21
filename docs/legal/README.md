# 法務文書（ドラフト）

アプリ内リンク用に HTTPS で公開し、`.env` に設定する。

```env
PANDA_TALK_TERMS_URL=https://（公開URL）/terms
PANDA_TALK_PRIVACY_URL=https://（公開URL）/privacy
```

| ファイル | 内容 |
|---|---|
| [terms_of_service.md](./terms_of_service.md) | 利用規約 |
| [privacy_policy.md](./privacy_policy.md) | プライバシーポリシー |

**注意:** 本番公開前に弁護士等の確認を推奨。実装変更（Analytics 導入、FCM 開始等）時はプライバシーポリシーを更新すること。
