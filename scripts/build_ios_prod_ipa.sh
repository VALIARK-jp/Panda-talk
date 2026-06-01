#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT"

if [[ ! -f .env.prod ]]; then
  echo ".env.prod not found at repo root." >&2
  exit 1
fi

flutter build ipa \
  --release \
  --dart-define-from-file=.env.prod \
  "$@"
