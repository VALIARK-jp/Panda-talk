#!/usr/bin/env node
/**
 * Pre-flight: prod placeholders replaced before deploy / TestFlight.
 * Usage: node scripts/check-prod-config.mjs
 */
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..')
let failed = false

function fail(msg) {
  console.error(`FAIL: ${msg}`)
  failed = true
}

function ok(msg) {
  console.log(`OK: ${msg}`)
}

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

const envProd = path.join(root, '.env.prod')
if (!fs.existsSync(envProd)) {
  fail('.env.prod missing (copy from .env.prod.example)')
} else {
  const text = fs.readFileSync(envProd, 'utf8')
  const env = parseEnv(text)
  if (!env.PANDA_TALK_SUPABASE_URL || env.PANDA_TALK_SUPABASE_URL.includes('YOUR_')) {
    fail('.env.prod: PANDA_TALK_SUPABASE_URL missing or placeholder')
  } else {
    ok('.env.prod has Supabase URL')
  }
  if (!env.PANDA_TALK_SUPABASE_ANON_KEY || env.PANDA_TALK_SUPABASE_ANON_KEY.length < 20) {
    fail('.env.prod: PANDA_TALK_SUPABASE_ANON_KEY missing')
  } else {
    ok('.env.prod has anon key')
  }
  if (
    !env.PANDA_TALK_API_BASE_URL ||
    env.PANDA_TALK_API_BASE_URL.includes('YOUR_ACCOUNT')
  ) {
    fail('.env.prod: PANDA_TALK_API_BASE_URL — set after npm run deploy:prod')
  } else {
    ok('.env.prod has API base URL')
  }
  for (const [key, label] of [
    ['PANDA_TALK_TERMS_URL', 'terms URL'],
    ['PANDA_TALK_PRIVACY_URL', 'privacy URL'],
  ]) {
    const value = env[key]
    if (!value || !value.startsWith('https://')) {
      fail(`.env.prod: ${key} must be an https URL`)
    } else {
      ok(`.env.prod has ${label}`)
    }
  }
}

const refsPath = path.join(root, 'scripts', 'valiark-project-refs.env')
if (!fs.existsSync(refsPath)) {
  fail('scripts/valiark-project-refs.env missing')
} else {
  const refs = parseEnv(fs.readFileSync(refsPath, 'utf8'))
  if (!refs.VALIARK_PROD_PROJECT_REF) {
    fail('VALIARK_PROD_PROJECT_REF not set')
  } else {
    ok('valiark-project-refs.env has prod ref')
  }
}

const devVars = path.join(root, 'backend', '.dev.vars')
if (!fs.existsSync(devVars)) {
  fail('backend/.dev.vars missing — run: cd backend && npm run sync:dev-vars')
} else {
  ok('backend/.dev.vars exists')
}

process.exit(failed ? 1 : 0)
