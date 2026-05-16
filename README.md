# panda_talk

質問・マッチ・トークなどの Flutter アプリ。

## 開発を始める

- **秘密の配り方・Git に載せないもの（Valiark 共通）**: [docs/valiark_client_secrets_playbook.md](docs/valiark_client_secrets_playbook.md)
- **認証（LINE / Apple）の手順**: [docs/05_auth.md](docs/05_auth.md)。LINE ログインには `.env` の `PANDA_TALK_LINE_CHANNEL_ID`（または `--dart-define`）が必要です。
- **すぐに実行**: [.env.example](.env.example) を `.env` にコピーし、Supabase URL / anon / LINE チャンネル ID を埋める。初回は [scripts/flutter_run_dev.sh](scripts/flutter_run_dev.sh) が `.env` が無ければ `.env.example` から作成します。Cursor / VS Code の **Run and Debug** では **`panda_talk (prompt LINE ID)`** で LINE ID だけ dart-define 上書きも可能です。

## Getting Started (Flutter)

See the [online documentation](https://docs.flutter.dev/) for tutorials and API reference.
