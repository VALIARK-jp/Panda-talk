import { execFileSync, spawn } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import {
  loadDevVars,
  loadProjectRef,
  loadRootEnv,
} from './read-supabase-config.mjs'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const projectRef = loadProjectRef()
if (!projectRef) {
  throw new Error(
    'Set SUPABASE_PROJECT_REF, scripts/valiark-project-refs.env, backend/.dev.vars, or root .env PANDA_TALK_SUPABASE_URL'
  )
}

const port = process.env.PORT ?? '8787'
const listenIp = process.env.WRANGLER_DEV_IP?.trim()

function readServiceRoleKey() {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return process.env.SUPABASE_SERVICE_ROLE_KEY
  }

  const devVars = loadDevVars()
  if (devVars.SUPABASE_SERVICE_ROLE_KEY) {
    return devVars.SUPABASE_SERVICE_ROLE_KEY
  }

  const rootEnv = loadRootEnv()
  if (rootEnv.PANDA_TALK_SUPABASE_SERVICE_ROLE_KEY) {
    return rootEnv.PANDA_TALK_SUPABASE_SERVICE_ROLE_KEY
  }

  try {
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
  } catch (error) {
    const detail =
      error && typeof error === 'object' && 'code' in error ? ` (${error.code})` : ''
    throw new Error(
      'SUPABASE_SERVICE_ROLE_KEY is required for backend dev. ' +
        'Set it in the shell, backend/.dev.vars, or root .env as ' +
        'PANDA_TALK_SUPABASE_SERVICE_ROLE_KEY, or install/login Supabase CLI' +
        detail
    )
  }
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
