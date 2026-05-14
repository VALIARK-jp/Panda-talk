import { execFileSync, spawn } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

function readProjectRefFromWrangler() {
  const tomlPath = path.join(__dirname, '..', 'wrangler.toml')
  const text = fs.readFileSync(tomlPath, 'utf8')
  const m = text.match(/SUPABASE_URL\s*=\s*"https:\/\/([^.]+)\.supabase\.co"/)
  return m ? m[1] : null
}

const projectRef = process.env.SUPABASE_PROJECT_REF ?? readProjectRefFromWrangler()
if (!projectRef) {
  throw new Error(
    'Set SUPABASE_PROJECT_REF or SUPABASE_URL in backend/wrangler.toml (https://<ref>.supabase.co)'
  )
}

const port = process.env.PORT ?? '8787'
const listenIp = process.env.WRANGLER_DEV_IP?.trim()

function readServiceRoleKey() {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return process.env.SUPABASE_SERVICE_ROLE_KEY
  }

  const output = execFileSync(
    'supabase',
    ['projects', 'api-keys', '--project-ref', projectRef, '-o', 'env'],
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'] }
  )
  const match = output.match(/^SUPABASE_SERVICE_ROLE_KEY="(.+)"$/m)
  if (!match) {
    throw new Error('Could not read SUPABASE_SERVICE_ROLE_KEY from Supabase CLI')
  }
  return match[1]
}

const serviceRoleKey = readServiceRoleKey()
const wranglerArgs = ['wrangler', 'dev', '--port', port]
if (listenIp) {
  wranglerArgs.push('--ip', listenIp)
}
wranglerArgs.push('--var', `SUPABASE_SERVICE_ROLE_KEY:${serviceRoleKey}`)

const child = spawn('npx', wranglerArgs, {
  stdio: 'inherit',
  env: process.env,
})

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal)
    return
  }
  process.exit(code ?? 0)
})
