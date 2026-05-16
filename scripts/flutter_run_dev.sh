#!/usr/bin/env bash
# Ensure `.env` exists, then run Flutter (values are read via flutter_dotenv in main).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example — set PANDA_TALK_SUPABASE_* and LINE." >&2
fi

exec flutter run "$@"
