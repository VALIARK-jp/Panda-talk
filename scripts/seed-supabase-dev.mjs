import { execFileSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { loadProjectRef } from '../backend/scripts/read-supabase-config.mjs'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

function loadDevProjectRef() {
  const refsFile = path.join(__dirname, 'valiark-project-refs.env')
  if (fs.existsSync(refsFile)) {
    const text = fs.readFileSync(refsFile, 'utf8')
    const match = text.match(/^VALIARK_DEV_PROJECT_REF=(.+)$/m)
    if (match?.[1]?.trim()) return match[1].trim()
  }
  return process.env.VALIARK_DEV_PROJECT_REF ?? null
}

const projectRef = process.env.SUPABASE_PROJECT_REF ?? loadProjectRef()
const VALIARK_DEV_PROJECT_REF = loadDevProjectRef()
if (!projectRef) {
  throw new Error(
    'Set SUPABASE_PROJECT_REF or SUPABASE_URL in backend/wrangler.toml (https://<ref>.supabase.co)'
  )
}

if (
  !VALIARK_DEV_PROJECT_REF ||
  (projectRef !== VALIARK_DEV_PROJECT_REF &&
    process.env.ALLOW_DEV_SEED_ON_PROJECT !== projectRef)
) {
  console.error(
    `seed:dev is restricted to valiark-dev (${VALIARK_DEV_PROJECT_REF ?? 'set VALIARK_DEV_PROJECT_REF in scripts/valiark-project-refs.env'}). ` +
      `Target was ${projectRef}. For prod use manual Q1–16 (docs/16_valiark_prod_panda_talk_setup.md). ` +
      `To override: ALLOW_DEV_SEED_ON_PROJECT=${projectRef} npm run seed:dev`
  )
  process.exit(1)
}
const supabaseUrl =
  process.env.SUPABASE_URL ?? `https://${projectRef}.supabase.co`

function readServiceRoleKey() {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return process.env.SUPABASE_SERVICE_ROLE_KEY
  }

  const output = execFileSync(
    'supabase',
    ['projects', 'api-keys', '--project-ref', projectRef, '-o', 'env'],
    { encoding: 'utf8' }
  )
  const match = output.match(/^SUPABASE_SERVICE_ROLE_KEY="(.+)"$/m)
  if (!match) {
    throw new Error('Could not read SUPABASE_SERVICE_ROLE_KEY from Supabase CLI')
  }
  return match[1]
}

const serviceRoleKey = readServiceRoleKey()

async function request(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
      'Content-Type': 'application/json',
      ...options.headers,
    },
  })

  if (!response.ok) {
    const body = await response.text()
    throw new Error(`${options.method ?? 'GET'} ${url} failed: ${body}`)
  }

  const text = await response.text()
  if (!text) return null
  return JSON.parse(text)
}

async function rest(resource, { method = 'GET', query = {}, body, prefer } = {}) {
  const params = new URLSearchParams(query)
  const url = `${supabaseUrl}/rest/v1/${resource}${params.size ? `?${params}` : ''}`
  return request(url, {
    method,
    body: body === undefined ? undefined : JSON.stringify(body),
    headers: prefer ? { Prefer: prefer } : undefined,
  })
}

async function listAuthUsers() {
  const data = await request(`${supabaseUrl}/auth/v1/admin/users?page=1&per_page=1000`)
  return data.users ?? []
}

async function getOrCreateAuthUser(seed, existingUsers) {
  const existing = existingUsers.find((user) => user.email === seed.email)
  if (existing) return existing

  return request(`${supabaseUrl}/auth/v1/admin/users`, {
    method: 'POST',
    body: JSON.stringify({
      email: seed.email,
      password: 'PandaTalk_dev_2026!',
      email_confirm: true,
      user_metadata: {
        name: seed.name,
        username: seed.username,
      },
    }),
  })
}

function orderedPair(userAId, userBId) {
  return userAId < userBId ? [userAId, userBId] : [userBId, userAId]
}

const userSeeds = [
  {
    email: 'alice.dev@panda-talk.local',
    username: 'alice',
    name: 'Alice',
    bio: '朝のコーヒー派',
  },
  {
    email: 'bob.dev@panda-talk.local',
    username: 'bob',
    name: 'Bob',
    bio: '週末は外に出たい派',
  },
  {
    email: 'carol.dev@panda-talk.local',
    username: 'carol',
    name: 'Carol',
    bio: '考えすぎるタイプ',
  },
]

const questionSeeds = [
  {
    id: '00000000-0000-4000-8000-000000000101',
    authorUsername: 'alice',
    text: '休日はどっちで過ごしたい？',
    option_a: '家派',
    option_b: '外出派',
    category: 'lifestyle',
  },
  {
    id: '00000000-0000-4000-8000-000000000102',
    authorUsername: 'bob',
    text: '連絡はどっちが楽？',
    option_a: '電話',
    option_b: 'メッセージ',
    category: 'communication',
  },
  {
    id: '00000000-0000-4000-8000-000000000103',
    authorUsername: 'carol',
    text: '旅行の計画は？',
    option_a: '細かく決める',
    option_b: '現地で決める',
    category: 'travel',
  },
  {
    id: '00000000-0000-4000-8000-000000000104',
    authorUsername: 'alice',
    text: '新しい店に入るなら？',
    option_a: '口コミを見てから',
    option_b: '直感で入る',
    category: 'food',
  },
]

async function main() {
  const authUsers = await listAuthUsers()
  const users = []

  for (const seed of userSeeds) {
    const authUser = await getOrCreateAuthUser(seed, authUsers)
    users.push({ ...seed, id: authUser.id })
  }

  await rest('panda_profiles', {
    method: 'POST',
    query: { on_conflict: 'id' },
    prefer: 'resolution=merge-duplicates,return=minimal',
    body: users.map((user) => ({
      id: user.id,
      email: user.email,
      username: user.username,
      name: user.name,
      avatar_url: null,
      bio: user.bio,
    })),
  })

  const usersByUsername = new Map(users.map((user) => [user.username, user]))
  const questions = questionSeeds.map((question) => ({
    id: question.id,
    user_id: usersByUsername.get(question.authorUsername).id,
    text: question.text,
    option_a: question.option_a,
    option_b: question.option_b,
    category: question.category,
  }))

  await rest('panda_questions', {
    method: 'POST',
    query: { on_conflict: 'id' },
    prefer: 'resolution=merge-duplicates,return=minimal',
    body: questions,
  })

  const alice = usersByUsername.get('alice')
  const bob = usersByUsername.get('bob')
  const carol = usersByUsername.get('carol')

  const answerSeeds = [
    { user_id: alice.id, question_id: questionSeeds[0].id, choice: 'a' },
    { user_id: bob.id, question_id: questionSeeds[0].id, choice: 'b' },
    { user_id: carol.id, question_id: questionSeeds[0].id, choice: 'a' },
    { user_id: alice.id, question_id: questionSeeds[1].id, choice: 'b' },
    { user_id: bob.id, question_id: questionSeeds[1].id, choice: 'b' },
    { user_id: carol.id, question_id: questionSeeds[1].id, choice: 'a' },
    { user_id: alice.id, question_id: questionSeeds[2].id, choice: 'a' },
    { user_id: bob.id, question_id: questionSeeds[2].id, choice: 'b' },
  ]

  await rest('panda_answers', {
    method: 'POST',
    query: { on_conflict: 'user_id,question_id' },
    prefer: 'resolution=ignore-duplicates,return=minimal',
    body: answerSeeds,
  })

  const comments = [
    {
      id: '00000000-0000-4000-8000-000000000201',
      question_id: questionSeeds[0].id,
      user_id: alice.id,
      choice: 'a',
      body: '外に出る準備を考えると家が楽。',
    },
    {
      id: '00000000-0000-4000-8000-000000000202',
      question_id: questionSeeds[0].id,
      user_id: bob.id,
      choice: 'b',
      body: '休日こそ外で気分を変えたい。',
    },
  ]

  await rest('panda_comments', {
    method: 'POST',
    query: { on_conflict: 'id' },
    prefer: 'resolution=merge-duplicates,return=minimal',
    body: comments,
  })

  await rest('panda_question_likes', {
    method: 'POST',
    query: { on_conflict: 'user_id,question_id' },
    prefer: 'resolution=ignore-duplicates,return=minimal',
    body: [
      { user_id: alice.id, question_id: questionSeeds[0].id },
      { user_id: bob.id, question_id: questionSeeds[0].id },
      { user_id: carol.id, question_id: questionSeeds[1].id },
    ],
  })

  const [aliceBobA, aliceBobB] = orderedPair(alice.id, bob.id)
  const [aliceCarolA, aliceCarolB] = orderedPair(alice.id, carol.id)
  const [bobCarolA, bobCarolB] = orderedPair(bob.id, carol.id)

  await rest('panda_match_scores', {
    method: 'POST',
    query: { on_conflict: 'user_a_id,user_b_id' },
    prefer: 'resolution=merge-duplicates,return=minimal',
    body: [
      {
        user_a_id: aliceBobA,
        user_b_id: aliceBobB,
        common_answer_count: 3,
        same_answer_count: 1,
        match_rate: 1 / 3,
      },
      {
        user_a_id: aliceCarolA,
        user_b_id: aliceCarolB,
        common_answer_count: 2,
        same_answer_count: 1,
        match_rate: 0.5,
      },
      {
        user_a_id: bobCarolA,
        user_b_id: bobCarolB,
        common_answer_count: 2,
        same_answer_count: 0,
        match_rate: 0,
      },
    ],
  })

  const [questionCount, answerCount] = await Promise.all([
    rest('panda_questions', { query: { select: 'id' } }),
    rest('panda_answers', { query: { select: 'id' } }),
  ])

  console.log(`Seeded ${users.length} users, ${questionCount.length} questions, ${answerCount.length} answers.`)
}

main().catch((error) => {
  console.error(error.message)
  process.exit(1)
})
