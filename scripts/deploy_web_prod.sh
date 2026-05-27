#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

"$ROOT/scripts/build_web_prod.sh"

cd "$ROOT/legal-site"
vercel --prod --yes
