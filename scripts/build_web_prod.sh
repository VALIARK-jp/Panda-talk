#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/legal-site/panda-talk"

cd "$ROOT"

if [[ ! -f .env.prod ]]; then
  echo ".env.prod not found at repo root." >&2
  exit 1
fi

flutter build web \
  --release \
  --base-href=/panda-talk/ \
  --dart-define-from-file=.env.prod \
  --output "$OUT_DIR"

echo "Built web app to $OUT_DIR using .env.prod"
