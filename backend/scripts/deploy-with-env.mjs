#!/usr/bin/env node
/**
 * wrangler deploy with SUPABASE_URL / SUPABASE_ANON_KEY from env files (not committed in wrangler.toml).
 *
 *   node scripts/deploy-with-env.mjs           # ../.env
 *   node scripts/deploy-with-env.mjs --env production   # ../.env.prod
 */
import { spawnSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const backendDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..')
const root = path.join(backendDir, '..')

const args = process.argv.slice(2)
const isProd = args.includes('--env') && args[args.indexOf('--env') + 1] === 'production'
const envFile = isProd
  ? path.join(root, '.env.prod')
  : path.join(root, '.env')

function parseEnv(text) {
  const map = {}
  for (const line of text.split('\n')) {
    const t = line.trim()
    if (!t || t.startsWith('#')) continue
    const i = t.indexOf('=')
    if (i === -1) continue
    map[t.slice(0, i).trim()] = t.slice(i + 1).trim()
  }
  return map
}

if (!fs.existsSync(envFile)) {
  console.error(`Missing ${envFile}`)
  process.exit(1)
}

const fileEnv = parseEnv(fs.readFileSync(envFile, 'utf8'))
const supabaseUrl = fileEnv.PANDA_TALK_SUPABASE_URL
const supabaseAnon = fileEnv.PANDA_TALK_SUPABASE_ANON_KEY
const apiBaseUrl = fileEnv.PANDA_TALK_API_BASE_URL?.replace(/\/+$/, '')
const defaultShareBase = isProd
  ? 'https://valiark.jp/panda-talk'
  : apiBaseUrl
    ? `${apiBaseUrl}/share`
    : 'https://panda-talk-backend.valiark.workers.dev/share'
const sharePublicBase =
  fileEnv.PANDA_TALK_SHARE_BASE_URL?.replace(/\/+$/, '') || defaultShareBase

if (!supabaseUrl || !supabaseAnon) {
  console.error(`${envFile} needs PANDA_TALK_SUPABASE_URL and PANDA_TALK_SUPABASE_ANON_KEY`)
  process.exit(1)
}

if (supabaseUrl.includes('YOUR_') || supabaseAnon.includes('YOUR_')) {
  console.error(`Replace placeholders in ${envFile} before deploy`)
  process.exit(1)
}

const wranglerArgs = [
  'wrangler',
  'deploy',
  '--var',
  `SUPABASE_URL:${supabaseUrl}`,
  '--var',
  `SUPABASE_ANON_KEY:${supabaseAnon}`,
  '--var',
  `APP_ENV:${isProd ? 'production' : 'development'}`,
  '--var',
  `SHARE_PUBLIC_BASE_URL:${sharePublicBase}`,
]

if (isProd) {
  wranglerArgs.push('--env', 'production')
  console.error('Deploying production Worker (panda-talk-backend-prod)…')
  console.error(`SHARE_PUBLIC_BASE_URL=${sharePublicBase}`)
  console.error('Ensure: npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY --env production')
} else {
  console.error('Deploying dev Worker (panda-talk-backend)…')
  console.error(`SHARE_PUBLIC_BASE_URL=${sharePublicBase}`)
  console.error('Ensure: npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY')
}

const result = spawnSync('npx', wranglerArgs, {
  cwd: backendDir,
  stdio: 'inherit',
  env: process.env,
})

process.exit(result.status ?? 1)
