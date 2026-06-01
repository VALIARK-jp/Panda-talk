#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env.prod ]]; then
  echo ".env.prod not found at repo root." >&2
  exit 1
fi

set -a
source .env.prod
set +a

if [[ -z "${PANDA_TALK_SUPABASE_URL:-}" ]]; then
  echo "PANDA_TALK_SUPABASE_URL is missing in .env.prod." >&2
  exit 1
fi

if [[ -z "${PANDA_TALK_SUPABASE_ANON_KEY:-}" ]]; then
  echo "PANDA_TALK_SUPABASE_ANON_KEY is missing in .env.prod." >&2
  exit 1
fi

if [[ -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  printf '%s' "$SUPABASE_SERVICE_ROLE_KEY" | (
    cd backend
    npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY
  )
else
  echo "SUPABASE_SERVICE_ROLE_KEY is not set in the shell." >&2
  echo "Set it before running this script so the backend can access Supabase." >&2
  exit 1
fi

cd "$ROOT/backend"
npx wrangler deploy \
  --var "SUPABASE_URL:${PANDA_TALK_SUPABASE_URL}" \
  --var "SUPABASE_ANON_KEY:${PANDA_TALK_SUPABASE_ANON_KEY}"
