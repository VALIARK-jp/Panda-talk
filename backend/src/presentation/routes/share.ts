import { Hono } from 'hono'
import { createContainer } from '../../infrastructure/container'
import type { Env } from '../../infrastructure/env'
import { findPandaTypeBySlug } from '../share/pandaTypes'
import {
  APP_LINKS,
  renderNotFoundBody,
  renderPandaTypeBody,
  renderProfileBody,
  renderQuestionBody,
  renderShareHtml,
} from '../share/html'

/**
 * SNSで共有された URL を踏んだ時に返す HTML ルート。
 *
 * - 公開先: Vercel(legal-site) が `/panda-talk/{q,u,type}/*` を rewrite で proxy する
 * - X / LINE 等のクローラ向けに `<head>` に OGP を直書き
 * - 詳細: docs/18_share_growth_spec.md Phase 2
 *
 * 全 GET・認証不要。未発見時は 404 ボディだが Content-Type は HTML を維持
 * （クローラに OGP を読ませるため）。
 */
const app = new Hono<{ Bindings: Env }>()

/** OGP canonical / og:url のベース。deploy 時に SHARE_PUBLIC_BASE_URL で注入。 */
function publicBase(env: Env): string {
  return (
    env.SHARE_PUBLIC_BASE_URL?.replace(/\/+$/, '') ??
    'https://valiark.jp/panda-talk'
  )
}

function htmlResponse(body: string, status = 200) {
  return new Response(body, {
    status,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      // SNSクローラ向けに短めキャッシュ。データ更新を早く反映させる。
      'Cache-Control': 'public, max-age=60, s-maxage=300',
    },
  })
}

function clamp01to100(n: number | undefined | null): number {
  if (n == null || !Number.isFinite(n)) return 50
  if (n < 0) return 0
  if (n > 100) return 100
  return Math.round(n)
}

const STATIC_ASSET_BASE = 'https://valiark.jp/panda-talk'

function truncate(text: string, max: number): string {
  if (text.length <= max) return text
  return text.slice(0, max - 1) + '…'
}

// GET /share/q/:number - 質問共有 LP
app.get('/q/:number', async (c) => {
  const base = publicBase(c.env)
  const numberParam = c.req.param('number')
  const questionNumber = Number(numberParam)
  if (!Number.isInteger(questionNumber) || questionNumber <= 0) {
    return htmlResponse(
      renderShareHtml({
        title: 'パンダトーク',
        description: '白黒つけるほど、仲良くなるSNS。',
        canonicalUrl: `${base}/q/${encodeURIComponent(numberParam)}`,
        imageUrl: APP_LINKS.defaultOgImage,
        bodyHtml: renderNotFoundBody('質問IDが正しくありません。'),
      }),
      404
    )
  }

  try {
    const { getQuestionByNumberUseCase, getQuestionStatsUseCase } =
      createContainer(c.env)
    const question = await getQuestionByNumberUseCase.execute(questionNumber)
    if (!question) {
      return htmlResponse(
        renderShareHtml({
          title: `Q.${questionNumber} | パンダトーク`,
          description: 'この質問は見つかりませんでした。',
          canonicalUrl: `${base}/q/${questionNumber}`,
          imageUrl: APP_LINKS.defaultOgImage,
          bodyHtml: renderNotFoundBody('指定の質問は見つかりませんでした。'),
        }),
        404
      )
    }

    const stats = await getQuestionStatsUseCase.execute(question.id)
    const total = stats.countA + stats.countB
    const percentA = total === 0 ? 50 : Math.round((stats.countA / total) * 100)

    const title = truncate(`Q.${question.questionNumber} ${question.text}`, 80)
    const description = truncate(
      `${question.optionA} ${percentA}% / ${question.optionB} ${
        100 - percentA
      }% — あなたはどっち？`,
      120
    )

    return htmlResponse(
      renderShareHtml({
        title,
        description,
        canonicalUrl: `${base}/q/${question.questionNumber}`,
        imageUrl: APP_LINKS.defaultOgImage,
        bodyHtml: renderQuestionBody({
          text: question.text,
          optionA: question.optionA,
          optionB: question.optionB,
          percentA,
        }),
      })
    )
  } catch (err) {
    console.error('share /q error:', err)
    return htmlResponse(
      renderShareHtml({
        title: 'パンダトーク',
        description: '一時的にページを表示できませんでした。',
        canonicalUrl: `${base}/q/${questionNumber}`,
        imageUrl: APP_LINKS.defaultOgImage,
        bodyHtml: renderNotFoundBody('一時的にページを表示できませんでした。'),
      }),
      500
    )
  }
})

// GET /share/u/:username - プロフィール共有 LP
app.get('/u/:username', async (c) => {
  const base = publicBase(c.env)
  const username = c.req.param('username')

  try {
    const { getUserByUsernameUseCase } = createContainer(c.env)
    const user = await getUserByUsernameUseCase.execute(username)
    if (!user) {
      return htmlResponse(
        renderShareHtml({
          title: `@${username} | パンダトーク`,
          description: 'プロフィールが見つかりませんでした。',
          canonicalUrl: `${base}/u/${encodeURIComponent(username)}`,
          imageUrl: APP_LINKS.defaultOgImage,
          bodyHtml: renderNotFoundBody(
            'このプロフィールは見つかりませんでした。'
          ),
        }),
        404
      )
    }

    const pandaType = user.pandaTypeSlug
      ? findPandaTypeBySlug(user.pandaTypeSlug)
      : null
    const oddballScore = user.oddballScore ?? null

    const title = pandaType
      ? `${pandaType.displayName} の ${user.name} | パンダトーク`
      : `${user.name}（@${user.username}）| パンダトーク`
    const descriptionParts: string[] = []
    if (pandaType) descriptionParts.push(pandaType.tagline)
    if (oddballScore != null) {
      descriptionParts.push(`異端児スコア ${clamp01to100(oddballScore)}%`)
    }
    if (descriptionParts.length === 0) {
      descriptionParts.push('白黒つけるほど、仲良くなるSNS。')
    }

    return htmlResponse(
      renderShareHtml({
        title,
        description: truncate(descriptionParts.join(' / '), 120),
        canonicalUrl: `${base}/u/${encodeURIComponent(user.username)}`,
        imageUrl: APP_LINKS.defaultOgImage,
        bodyHtml: renderProfileBody({
          name: user.name,
          username: user.username,
          pandaTypeName: pandaType?.displayName ?? null,
          pandaTagline: pandaType?.tagline ?? null,
          oddballScore,
        }),
      })
    )
  } catch (err) {
    console.error('share /u error:', err)
    return htmlResponse(
      renderShareHtml({
        title: 'パンダトーク',
        description: '一時的にページを表示できませんでした。',
        canonicalUrl: `${base}/u/${encodeURIComponent(username)}`,
        imageUrl: APP_LINKS.defaultOgImage,
        bodyHtml: renderNotFoundBody('一時的にページを表示できませんでした。'),
      }),
      500
    )
  }
})

// GET /share/type/:slug - 16type 診断結果の共有 LP（DB引かず静的）
app.get('/type/:slug', (c) => {
  const base = publicBase(c.env)
  const slug = c.req.param('slug')
  const def = findPandaTypeBySlug(slug)
  if (!def) {
    return htmlResponse(
      renderShareHtml({
        title: 'パンダトーク 16type 診断',
        description: 'この診断タイプは見つかりませんでした。',
        canonicalUrl: `${base}/type/${encodeURIComponent(slug)}`,
        imageUrl: APP_LINKS.defaultOgImage,
        bodyHtml: renderNotFoundBody(
          '指定の診断タイプは見つかりませんでした。'
        ),
      }),
      404
    )
  }

  // 公開済みのパンダ画像（Flutter Web の assets をそのまま使う）。
  // 実体パスは legal-site/panda-talk/assets/assets/images/panda/{N}.PNG（ゼロパディング無し）。
  const imageUrl = `${STATIC_ASSET_BASE}/assets/assets/images/panda/${def.imageIndex}.PNG`

  return htmlResponse(
    renderShareHtml({
      title: `${def.displayName} | パンダトーク 16type 診断`,
      description: truncate(def.tagline, 120),
      canonicalUrl: `${base}/type/${def.slug}`,
      imageUrl,
      bodyHtml: renderPandaTypeBody({
        displayName: def.displayName,
        tagline: def.tagline,
        imageUrl,
      }),
    })
  )
})

export default app
