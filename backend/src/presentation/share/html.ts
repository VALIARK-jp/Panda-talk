/**
 * SNS共有から踏まれた時に返す HTML（OGP メタ + 最小 LP）。
 *
 * - X / LINE のクローラは JS を実行しないので `<head>` に OGP を直書き
 * - 同じ HTML を人間も見るので、最小限の LP + ストア CTA も入れる
 * - 実装の文体・URL設計は docs/18_share_growth_spec.md §3-4 と一致させる
 */

import type { Env } from '../../infrastructure/env'

/** 静的アセット（Vercel 上の Flutter Web ビルド）。 */
export const STATIC_ASSET_BASE = 'https://valiark.jp/panda-talk'

const DEFAULT_ANDROID_URL =
  'https://play.google.com/store/apps/details?id=io.valiark.pandatalk'

/** TestFlight / App Store URL 未設定時の iOS フォールバック（Web ではない）。 */
const DEFAULT_IOS_SEARCH_URL =
  'https://apps.apple.com/jp/search?term=%E3%83%91%E3%83%B3%E3%83%80%E3%83%88%E3%83%BC%E3%82%AF'

/** App Store / TestFlight / Play / Web LP の差し向け先。 */
export type SharePageLinks = {
  iosAppUrl: string
  androidAppUrl: string
  webAppUrl: string
  brandLogoUrl: string
  defaultOgImage: string
}

/** Worker の env から LP 用リンクを解決。 */
export function resolveSharePageLinks(env?: Env): SharePageLinks {
  return {
    iosAppUrl: env?.SHARE_IOS_APP_URL?.trim() ?? '',
    androidAppUrl:
      env?.SHARE_ANDROID_APP_URL?.trim() || DEFAULT_ANDROID_URL,
    webAppUrl: STATIC_ASSET_BASE,
    brandLogoUrl: `${STATIC_ASSET_BASE}/assets/assets/images/app_icon.png`,
    defaultOgImage: `${STATIC_ASSET_BASE}/icons/Icon-512.png`,
  }
}

/** @deprecated resolveSharePageLinks を使う */
export const APP_LINKS = {
  appStoreUrl: '',
  playStoreUrl: DEFAULT_ANDROID_URL,
  webAppUrl: STATIC_ASSET_BASE,
  defaultOgImage: `${STATIC_ASSET_BASE}/icons/Icon-512.png`,
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
export function renderShareHtml(
  input: ShareHtmlInput,
  links: SharePageLinks
): string {
  const title = escapeAttr(input.title)
  const description = escapeAttr(input.description)
  const canonicalUrl = escapeAttr(input.canonicalUrl)
  const imageUrl = escapeAttr(input.imageUrl)
  const brandLogo = escapeAttr(links.brandLogoUrl)
  const webAppUrl = escapeAttr(links.webAppUrl)

  return `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#111111">
<title>${title}</title>
<meta name="description" content="${description}">
<link rel="icon" href="${brandLogo}">
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
  .brand { margin-bottom: 24px; }
  .brand a {
    display: inline-flex;
    align-items: center;
    gap: 10px;
    color: #777777;
    font-size: 14px;
    font-weight: 800;
    letter-spacing: 0.04em;
    text-decoration: none;
  }
  .brand-logo {
    width: 32px;
    height: 32px;
    border-radius: 8px;
    flex-shrink: 0;
  }
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
  .cta-group { display: flex; flex-direction: column; gap: 8px; margin-top: 20px; }
  .cta {
    display: block;
    width: 100%;
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
  }
  .web-link {
    display: block;
    margin-top: 12px;
    text-align: center;
    font-size: 13px;
    color: #777;
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
    <div class="brand">
      <a href="${webAppUrl}">
        <img class="brand-logo" src="${brandLogo}" width="32" height="32" alt="">
        パンダトーク
      </a>
    </div>
    ${input.bodyHtml}
    <p class="footer">
      白黒つけるほど、仲良くなるSNS<br>
      <a href="${webAppUrl}">パンダトーク</a>
    </p>
  </main>
</body>
</html>`
}

type CtaOptions = {
  primaryLabel?: string
  userAgent?: string
}

/**
 * iPhone / Android のストア導線を常に出す。
 * TestFlight / App Store URL は deploy 時の SHARE_IOS_APP_URL で注入。
 */
export function renderCtaButtons(
  links: SharePageLinks,
  options?: CtaOptions
): string {
  const primaryLabel = options?.primaryLabel ?? 'アプリで開く'
  const ua = options?.userAgent ?? ''
  const isIos = /iPhone|iPad|iPod/i.test(ua)
  const isAndroid = /Android/i.test(ua)

  const iosHref = links.iosAppUrl || DEFAULT_IOS_SEARCH_URL
  const iosPrimary = isIos || (!isIos && !isAndroid)
  const androidPrimary = isAndroid && !isIos

  const iosButton = `<a class="cta${iosPrimary ? '' : ' secondary'}" href="${escapeAttr(iosHref)}">${escapeHtml(primaryLabel)}（iPhone）</a>`
  const androidButton = `<a class="cta${androidPrimary ? '' : ' secondary'}" href="${escapeAttr(links.androidAppUrl)}">${escapeHtml(primaryLabel)}（Android）</a>`

  const ordered = isAndroid
    ? `${androidButton}\n${iosButton}`
    : `${iosButton}\n${androidButton}`

  return `<div class="cta-group">
${ordered}
<a class="web-link" href="${escapeAttr(links.webAppUrl)}">Webで体験する</a>
</div>`
}

/** Question 用の本文 HTML。 */
export type QuestionBodyInput = {
  text: string
  optionA: string
  optionB: string
  percentA: number
}

export function renderQuestionBody(
  input: QuestionBodyInput,
  links: SharePageLinks,
  userAgent?: string
): string {
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
    ${renderCtaButtons(links, { primaryLabel: 'アプリで答える', userAgent })}
  </article>`
}

/** 16type 用の本文 HTML。 */
export type PandaTypeBodyInput = {
  displayName: string
  tagline: string
  imageUrl: string
}

export function renderPandaTypeBody(
  input: PandaTypeBodyInput,
  links: SharePageLinks,
  userAgent?: string
): string {
  return `
  <article class="card">
    <img class="panda-image" src="${escapeAttr(input.imageUrl)}" alt="${escapeAttr(input.displayName)}">
    <p class="panda-name">${escapeHtml(input.displayName)}</p>
    <p class="panda-tagline">${escapeHtml(input.tagline)}</p>
    <p class="lead">あなたはどのパンダ？16問でわかる価値観診断。</p>
    ${renderCtaButtons(links, { primaryLabel: 'アプリで診断する', userAgent })}
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

export function renderProfileBody(
  input: ProfileBodyInput,
  links: SharePageLinks,
  userAgent?: string
): string {
  const pandaLine = input.pandaTypeName
    ? `<p class="panda-name">${escapeHtml(input.pandaTypeName)}</p>${
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
    ${renderCtaButtons(links, { primaryLabel: 'アプリで診断する', userAgent })}
  </article>`
}

/** 404 / 410 用のシンプルなページ。 */
export function renderNotFoundBody(
  message: string,
  links: SharePageLinks,
  userAgent?: string
): string {
  return `
  <article class="card">
    <h1>見つかりませんでした</h1>
    <p class="lead">${escapeHtml(message)}</p>
    ${renderCtaButtons(links, { primaryLabel: 'パンダトークを開く', userAgent })}
  </article>`
}

function clampPercent(n: number): number {
  if (!Number.isFinite(n)) return 0
  if (n < 0) return 0
  if (n > 100) return 100
  return Math.round(n)
}
