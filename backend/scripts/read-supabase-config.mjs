#!/usr/bin/env node
/** Shared: resolve SUPABASE_URL and project ref from .dev.vars, root .env, or wrangler. */
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const backendDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..')
const root = path.join(backendDir, '..')

export function parseEnv(text) {
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

export function loadSupabaseUrl() {
  const devVars = path.join(backendDir, '.dev.vars')
  if (fs.existsSync(devVars)) {
    const v = parseEnv(fs.readFileSync(devVars, 'utf8'))
    if (v.SUPABASE_URL) return v.SUPABASE_URL
  }
  const envPath = path.join(root, '.env')
  if (fs.existsSync(envPath)) {
    const v = parseEnv(fs.readFileSync(envPath, 'utf8'))
    if (v.PANDA_TALK_SUPABASE_URL) return v.PANDA_TALK_SUPABASE_URL
  }
  return null
}

export function projectRefFromUrl(url) {
  const m = url?.match(/https:\/\/([^.]+)\.supabase\.co/)
  return m ? m[1] : null
}

export function loadProjectRef() {
  if (process.env.SUPABASE_PROJECT_REF) return process.env.SUPABASE_PROJECT_REF
  const refsFile = path.join(root, 'scripts', 'valiark-project-refs.env')
  if (fs.existsSync(refsFile)) {
    const v = parseEnv(fs.readFileSync(refsFile, 'utf8'))
    if (process.env.VALIARK_ENV === 'production' && v.VALIARK_PROD_PROJECT_REF) {
      return v.VALIARK_PROD_PROJECT_REF
    }
    if (v.VALIARK_DEV_PROJECT_REF) return v.VALIARK_DEV_PROJECT_REF
  }
  return projectRefFromUrl(loadSupabaseUrl())
}
