#!/usr/bin/env node
/**
 * Pipe prod/dev service_role into wrangler secret (non-interactive when key is known).
 *
 *   cd backend
 *   node scripts/put-wrangler-service-role.mjs              # dev, from Supabase CLI
 *   node scripts/put-wrangler-service-role.mjs --env production
 */
import { execFileSync, spawnSync } from 'node:child_process'
import { loadProjectRef } from './read-supabase-config.mjs'

const args = process.argv.slice(2)
const isProd = args.includes('--env') && args[args.indexOf('--env') + 1] === 'production'

if (isProd) {
  process.env.VALIARK_ENV = 'production'
}

const projectRef = loadProjectRef()
if (!projectRef) {
  console.error('Could not resolve project ref')
  process.exit(1)
}

const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  ?? (() => {
    const out = execFileSync(
      'supabase',
      ['projects', 'api-keys', '--project-ref', projectRef, '-o', 'env'],
      { encoding: 'utf8' }
    )
    const m = out.match(/^SUPABASE_SERVICE_ROLE_KEY="(.+)"$/m)
    return m?.[1]
  })()

if (!key) {
  console.error('Set SUPABASE_SERVICE_ROLE_KEY or run supabase login')
  process.exit(1)
}

const wranglerArgs = ['wrangler', 'secret', 'put', 'SUPABASE_SERVICE_ROLE_KEY']
if (isProd) wranglerArgs.push('--env', 'production')

const r = spawnSync('npx', wranglerArgs, {
  input: key,
  encoding: 'utf8',
  stdio: ['pipe', 'inherit', 'inherit'],
})

process.exit(r.status ?? 1)
