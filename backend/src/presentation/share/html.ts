/**
 * SNS共有から踏まれた時に返す HTML（OGP メタ + 最小 LP）。
 *
 * - X / LINE のクローラは JS を実行しないので `<head>` に OGP を直書き
 * - 同じ HTML を人間も見るので、最小限の LP + App Store CTA も入れる
 * - 実装の文体・URL設計は docs/18_share_growth_spec.md §3-4 と一致させる
 */

/** App Store / Google Play / Web LP の差し向け先。 */
export const APP_LINKS = {
  /** TestFlight 段階のため空。本配信後に `https://apps.apple.com/app/idXXXX` で差し替える。 */
  appStoreUrl: '',
  /** Bundle ID 確定後に有効化。 */
  playStoreUrl:
    'https://play.google.com/store/apps/details?id=io.valiark.pandatalk',
  /** 既存の Flutter Web 版。 */
  webAppUrl: 'https://valiark.jp/panda-talk',
  /** OGP用の汎用画像。後でロゴ等を `legal-site/og/share-default.png` 等に配置して差し替え。 */
  defaultOgImage: 'https://valiark.jp/panda-talk/icons/Icon-512.png',
}

function escapeHtml(input: string): string {
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

/** 全文字をHTML属性として安全にする（さらに改行を除去）。 */
function escapeAttr(input: string): string {
  return escapeHtml(input).replace(/\s+/g, ' ')
}

export type ShareHtmlInput = {
  /** ブラウザのタブ表示用＆OGP title */
  title: string
  /** OGP description（120字程度推奨） */
  description: string
  /** 共有URLそのもの（OGP url）。例: https://valiark.jp/panda-talk/q/17 */
  canonicalUrl: string
  /** 絶対URLでないと OGP は弾かれる */
  imageUrl: string
  /** 画面本文の中身（HTML 文字列。サニタイズ済みである前提） */
  bodyHtml: string
}

/**
 * ベース HTML を組み立てる。
 *
 * 重要: bodyHtml は呼び出し側が **必ず escapeHtml 済み** にすること。
 *  title / description / canonicalUrl / imageUrl は本関数内でエスケープ。
 */
export function renderShareHtml(input: ShareHtmlInput): string {
  const title = escapeAttr(input.title)
  const description = escapeAttr(input.description)
  const canonicalUrl = escapeAttr(input.canonicalUrl)
  const imageUrl = escapeAttr(input.imageUrl)

  return `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#111111">
<title>${title}</title>
<meta name="description" content="${description}">
<link rel="canonical" href="${canonicalUrl}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="パンダトーク">
<meta property="og:title" content="${title}">
<meta property="og:description" content="${description}">
<meta property="og:url" content="${canonicalUrl}">
<meta property="og:image" content="${imageUrl}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${title}">
<meta name="twitter:description" content="${description}">
<meta name="twitter:image" content="${imageUrl}">
<style>
  :root { color-scheme: light; }
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Hiragino Kaku Gothic ProN",
      "Yu Gothic UI", "Meiryo", "Segoe UI", sans-serif;
    background: #ffffff;
    color: #111111;
    line-height: 1.6;
    -webkit-font-smoothing: antialiased;
  }
  .container {
    max-width: 560px;
    margin: 0 auto;
    padding: 32px 20px 64px;
  }
  .brand {
    font-size: 14px;
    font-weight: 800;
    letter-spacing: 0.04em;
    color: #777777;
    margin-bottom: 24px;
  }
  .brand a { color: inherit; text-decoration: none; }
  .card {
    border: 1px solid #e5e5e5;
    border-radius: 24px;
    padding: 28px 24px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.04);
  }
  h1 {
    font-size: 22px;
    line-height: 1.4;
    font-weight: 900;
    margin: 0 0 16px;
  }
  .lead {
    font-size: 15px;
    color: #555;
    margin: 0 0 20px;
  }
  .options { display: flex; flex-direction: column; gap: 8px; margin: 16px 0 8px; }
  .option {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 14px 18px;
    border-radius: 100px;
    background: #f5f5f5;
    font-weight: 800;
    font-size: 15px;
  }
  .option .pct { color: #111; font-weight: 900; }
  .option.is-majority { background: #111; color: #fff; }
  .option.is-majority .pct { color: #fff; }
  .panda-image {
    display: block;
    width: 160px;
    height: 160px;
    margin: 8px auto 16px;
    border-radius: 24px;
    object-fit: contain;
    background: #f5f5f5;
  }
  .panda-name {
    text-align: center;
    font-size: 28px;
    font-weight: 900;
    margin: 0 0 6px;
  }
  .panda-tagline {
    text-align: center;
    color: #555;
    font-size: 15px;
    margin: 0 0 20px;
  }
  .cta {
    display: block;
    width: 100%;
    margin-top: 20px;
    padding: 16px;
    background: #111;
    color: #fff;
    text-align: center;
    text-decoration: none;
    border-radius: 100px;
    font-weight: 800;
    font-size: 16px;
  }
  .cta.secondary {
    background: #fff;
    color: #111;
    border: 1px solid #111;
    margin-top: 8px;
  }
  .footer {
    margin-top: 32px;
    text-align: center;
    color: #999;
    font-size: 12px;
  }
  .footer a { color: inherit; }
</style>
</head>
<body>
  <main class="container">
    <div class="brand"><a href="${escapeAttr(APP_LINKS.webAppUrl)}">🐼 パンダトーク</a></div>
    ${input.bodyHtml}
    <p class="footer">
      白黒つけるほど、仲良くなるSNS<br>
      <a href="${escapeAttr(APP_LINKS.webAppUrl)}">パンダトーク</a>
    </p>
  </main>
</body>
</html>`
}

/**
 * CTA ボタン群を組み立てる。
 * App Store URL が未確定の今は Web LP を主導線にする。
 */
export function renderCtaButtons(options?: { primaryLabel?: string }): string {
  const primaryLabel = options?.primaryLabel ?? 'アプリで開く'
  const buttons: string[] = []

  if (APP_LINKS.appStoreUrl) {
    buttons.push(
      `<a class="cta" href="${escapeAttr(APP_LINKS.appStoreUrl)}">${escapeHtml(primaryLabel)}（iOS）</a>`
    )
  }
  buttons.push(
    `<a class="cta${APP_LINKS.appStoreUrl ? ' secondary' : ''}" href="${escapeAttr(APP_LINKS.playStoreUrl)}">${escapeHtml(primaryLabel)}（Android）</a>`
  )
  if (!APP_LINKS.appStoreUrl) {
    buttons.push(
      `<a class="cta secondary" href="${escapeAttr(APP_LINKS.webAppUrl)}">Webで体験する</a>`
    )
  }
  return buttons.join('\n')
}

/** Question 用の本文 HTML。 */
export type QuestionBodyInput = {
  text: string
  optionA: string
  optionB: string
  percentA: number
}

export function renderQuestionBody(input: QuestionBodyInput): string {
  const percentA = clampPercent(input.percentA)
  const percentB = 100 - percentA
  const aMajority = percentA >= percentB
  return `
  <article class="card">
    <h1>Q. ${escapeHtml(input.text)}</h1>
    <div class="options">
      <div class="option${aMajority ? ' is-majority' : ''}">
        <span>${escapeHtml(input.optionA)}</span>
        <span class="pct">${percentA}%</span>
      </div>
      <div class="option${!aMajority ? ' is-majority' : ''}">
        <span>${escapeHtml(input.optionB)}</span>
        <span class="pct">${percentB}%</span>
      </div>
    </div>
    <p class="lead">あなたはどっち？</p>
    ${renderCtaButtons({ primaryLabel: 'アプリで答える' })}
  </article>`
}

/** 16type 用の本文 HTML。 */
export type PandaTypeBodyInput = {
  displayName: string
  tagline: string
  imageUrl: string
}

export function renderPandaTypeBody(input: PandaTypeBodyInput): string {
  return `
  <article class="card">
    <img class="panda-image" src="${escapeAttr(input.imageUrl)}" alt="${escapeAttr(input.displayName)}">
    <p class="panda-name">${escapeHtml(input.displayName)}</p>
    <p class="panda-tagline">${escapeHtml(input.tagline)}</p>
    <p class="lead">あなたはどのパンダ？16問でわかる価値観診断。</p>
    ${renderCtaButtons({ primaryLabel: 'アプリで診断する' })}
  </article>`
}

/** User Profile 用の本文 HTML。 */
export type ProfileBodyInput = {
  name: string
  username: string
  pandaTypeName?: string | null
  pandaTagline?: string | null
  oddballScore?: number | null
}

export function renderProfileBody(input: ProfileBodyInput): string {
  const pandaLine = input.pandaTypeName
    ? `<p class="panda-name">🐼 ${escapeHtml(input.pandaTypeName)}</p>${
        input.pandaTagline
          ? `<p class="panda-tagline">${escapeHtml(input.pandaTagline)}</p>`
          : ''
      }`
    : `<p class="panda-name">@${escapeHtml(input.username)}</p>`
  const odd = input.oddballScore != null
    ? `<p class="lead" style="text-align:center;">異端児スコア <strong>${clampPercent(input.oddballScore)}%</strong></p>`
    : ''
  return `
  <article class="card">
    ${pandaLine}
    ${odd}
    <p class="lead">${escapeHtml(input.name)} さんのパンダトーク。</p>
    ${renderCtaButtons({ primaryLabel: 'アプリで診断する' })}
  </article>`
}

/** 404 / 410 用のシンプルなページ。 */
export function renderNotFoundBody(message: string): string {
  return `
  <article class="card">
    <h1>見つかりませんでした</h1>
    <p class="lead">${escapeHtml(message)}</p>
    ${renderCtaButtons({ primaryLabel: 'パンダトークを開く' })}
  </article>`
}

function clampPercent(n: number): number {
  if (!Number.isFinite(n)) return 0
  if (n < 0) return 0
  if (n > 100) return 100
  return Math.round(n)
}
