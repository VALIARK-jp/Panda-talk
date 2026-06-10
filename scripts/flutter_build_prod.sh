#!/usr/bin/env bash
# Build a prod IPA against valiark-prod (.env.prod → --dart-define).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_PROD="$ROOT/.env.prod"
if [[ ! -f "$ENV_PROD" ]]; then
  echo "Create .env.prod from .env.prod.example (see docs/16_valiark_prod_panda_talk_setup.md)" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_PROD"
set +a

DEFINES=(
  "--dart-define=PANDA_TALK_SUPABASE_URL=${PANDA_TALK_SUPABASE_URL:?}"
  "--dart-define=PANDA_TALK_SUPABASE_ANON_KEY=${PANDA_TALK_SUPABASE_ANON_KEY:?}"
  "--dart-define=PANDA_TALK_API_BASE_URL=${PANDA_TALK_API_BASE_URL:?}"
  "--dart-define=PANDA_TALK_AUTH_REDIRECT_URL=${PANDA_TALK_AUTH_REDIRECT_URL:-io.valiark.pandatalk://callback}"
  "--dart-define=PANDA_TALK_TERMS_URL=${PANDA_TALK_TERMS_URL:?}"
  "--dart-define=PANDA_TALK_PRIVACY_URL=${PANDA_TALK_PRIVACY_URL:?}"
  "--dart-define=PANDA_TALK_ENABLE_NOTIFICATION_TEST=${PANDA_TALK_ENABLE_NOTIFICATION_TEST:-true}"
)

node "$ROOT/scripts/check-prod-config.mjs"
exec flutter build ipa "${DEFINES[@]}" "$@"
