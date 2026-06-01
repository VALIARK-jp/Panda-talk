#!/usr/bin/env bash
# Load `.env.prod` for local runs against valiark-prod (TestFlight 前の実機確認用).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_PROD="$ROOT/.env.prod"
if [[ ! -f "$ENV_PROD" ]]; then
  echo "Create .env.prod from .env.prod.example (see docs/16_valiark_prod_panda_talk_setup.md)" >&2
  exit 1
fi

# flutter_dotenv loads `.env` by default; symlink/copy pattern: use dart-define from .env.prod
set -a
# shellcheck disable=SC1090
source "$ENV_PROD"
set +a

DEFINES=(
  "--dart-define=PANDA_TALK_SUPABASE_URL=${PANDA_TALK_SUPABASE_URL:?}"
  "--dart-define=PANDA_TALK_SUPABASE_ANON_KEY=${PANDA_TALK_SUPABASE_ANON_KEY:?}"
  "--dart-define=PANDA_TALK_API_BASE_URL=${PANDA_TALK_API_BASE_URL:?}"
  "--dart-define=PANDA_TALK_AUTH_REDIRECT_URL=${PANDA_TALK_AUTH_REDIRECT_URL:-io.valiark.pandatalk://callback}"
  "--dart-define=PANDA_TALK_WEB_AUTH_REDIRECT_URL=${PANDA_TALK_WEB_AUTH_REDIRECT_URL:-https://valiark.jp/panda-talk/auth/callback}"
)

if [[ -f .env ]]; then
  exec flutter run "${DEFINES[@]}" "$@"
fi

cp .env.example .env 2>/dev/null || true
exec flutter run "${DEFINES[@]}" "$@"
