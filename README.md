# panda_talk

質問・マッチ・トークなどの Flutter アプリ（Valiark / valiark-dev）。

## 開発を始める

1. [.env.example](.env.example) を `.env` にコピーし、**Supabase URL / anon** を埋める（チーム配布）。
2. **API（Worker）の dev URL** を `.env` の `PANDA_TALK_API_BASE_URL` に書く（下記「API の向き先」）。
3. `flutter run`（初回は [scripts/flutter_run_dev.sh](scripts/flutter_run_dev.sh) でも可）。

| ドキュメント | 内容 |
|-------------|------|
| **[開発: API・実機・localhost](./docs/14_development_api_and_devices.md)** | **必読** — なぜ 2 ホストあるか、シミュレータ vs 実機、deploy / ngrok |
| [valiark_client_secrets_playbook.md](docs/valiark_client_secrets_playbook.md) | 秘密の配布・Git に載せないもの |
| [05_auth.md](docs/05_auth.md) | 認証（メール / LINE / Apple）の構築・運用 |
| [06_tech.md](docs/06_tech.md) | 技術構成・BFF（Hono + Worker）方針 |

## API の向き先（設計方針・要約）

このアプリは **Supabase（認証）** と **Cloudflare Worker（マッチ等の BFF）** の **2 つ** に繋ぐ。  
**全部 Supabase だけ** のプロジェクトと違い、**API 用 URL を開発モードで切り替える**必要がある。

| いつ | `PANDA_TALK_API_BASE_URL` | Worker（Mac） |
|------|---------------------------|----------------|
| **普段（シミュレータ）** | `http://localhost:8787` | `cd backend && npm run dev` |
| **実機** | `https://panda-talk-backend.valiark.workers.dev` | 不要（クラウド dev） |
| **実機 × 最新ローカル API** | ngrok URL、またはそのときだけ `npm run deploy` | `dev` + ngrok など |

- **実機にスマホの IP を書く運用はしない**（baselink のクラウド dev API と同じ）。
- **API を変えるたびの deploy は不要**。詳細は [docs/14_development_api_and_devices.md](docs/14_development_api_and_devices.md)。

### Worker の初回デプロイ（dev URL がまだ無い場合）

```bash
cd backend
npx wrangler login
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY
npm run deploy
# → https://panda-talk-backend.valiark.workers.dev を .env に記載
```

## Getting Started (Flutter)

See the [online documentation](https://docs.flutter.dev/) for tutorials and API reference.
