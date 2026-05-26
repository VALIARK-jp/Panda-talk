#!/usr/bin/env bash
# Set Edge Function secrets on valiark-prod (requires supabase login + service_role).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1090
source "$ROOT/scripts/valiark-project-refs.env"

PROD_REF="${VALIARK_PROD_PROJECT_REF:?Set VALIARK_PROD_PROJECT_REF in scripts/valiark-project-refs.env}"

# SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are injected by Supabase for Edge Functions.
# CLI rejects secrets starting with SUPABASE_ (see supabase secrets set --help).

cd "$ROOT"
supabase link --project-ref "$PROD_REF"
supabase secrets set LINE_CHANNEL_ID="2010102462"

echo "LINE_CHANNEL_ID set on $PROD_REF."
echo "Deploy functions: ./scripts/valiark-prod-supabase-setup.sh functions"
