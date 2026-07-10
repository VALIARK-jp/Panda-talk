#!/usr/bin/env bash
# valiark-prod 向け Supabase CLI 手順（supabase login 済み前提）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REFS_FILE="$ROOT/scripts/valiark-project-refs.env"
if [[ -f "$REFS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$REFS_FILE"
fi

PROD_REF="${VALIARK_PROD_PROJECT_REF:-}"
if [[ -z "$PROD_REF" ]]; then
  echo "Set VALIARK_PROD_PROJECT_REF or create scripts/valiark-project-refs.env from valiark-project-refs.env.example" >&2
  exit 1
fi

usage() {
  echo "Usage: $0 db|functions|all" >&2
  echo "  db        — supabase link + db push to valiark-prod" >&2
  echo "  functions — deploy line-auth-native + apple-auth-native (secrets は事前に set)" >&2
  echo "  all       — db then functions" >&2
  exit 1
}

cmd="${1:-}"
[[ -z "$cmd" ]] && usage

run_db() {
  echo "==> Pushing migrations to prod ref: $PROD_REF"

  # Explicit pooler URL (IPv4). Dashboard → Connect → Session mode → URI
  if [[ -n "${SUPABASE_DB_URL:-}" ]]; then
    echo "    Using SUPABASE_DB_URL (--db-url)"
    supabase db push --db-url "$SUPABASE_DB_URL"
    echo "==> Done. Verify panda_* tables and auth RPCs in Dashboard."
    return
  fi

  local link_args=(--project-ref "$PROD_REF")
  local push_args=()
  if [[ -n "${SUPABASE_DB_PASSWORD:-}" ]]; then
    link_args+=(-p "$SUPABASE_DB_PASSWORD")
    push_args+=(-p "$SUPABASE_DB_PASSWORD")
  fi

  # IPv4-only networks (typical home Wi‑Fi): do NOT use --skip-pooler (db.*.supabase.co is IPv6).
  if [[ "${DB_PUSH_SKIP_POOLER:-}" == "1" ]]; then
    link_args+=(--skip-pooler)
    echo "    WARNING: skip-pooler uses IPv6 direct host. If you see 'IPv6 is not supported', unset DB_PUSH_SKIP_POOLER." >&2
  else
    echo "    Using pooler (IPv4). If connection refused → Dashboard → Database → Network Bans → Unban your IP." >&2
  fi

  if [[ -d "$ROOT/supabase/.temp" ]] && [[ "${SUPABASE_LINK_FRESH:-}" == "1" ]]; then
    rm -rf "$ROOT/supabase/.temp"
    echo "    Cleared supabase/.temp (SUPABASE_LINK_FRESH=1)"
  fi

  supabase link "${link_args[@]}"
  supabase db push "${push_args[@]}"
  echo "==> Done. Verify panda_* tables and auth RPCs in Dashboard."
}

run_functions() {
  echo "==> Deploying Edge Functions to prod ref: $PROD_REF"
  supabase link --project-ref "$PROD_REF"
  supabase functions deploy line-auth-native --no-verify-jwt
  supabase functions deploy apple-auth-native --no-verify-jwt
  echo "==> Done. Test LINE/Apple login from a prod-configured build."
}

case "$cmd" in
  db) run_db ;;
  functions) run_functions ;;
  all)
    run_db
    run_functions
    ;;
  *) usage ;;
esac
