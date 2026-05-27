/**
 * 16type 診断のスラッグ → 表示名 / タグライン / 画像インデックス。
 * Flutter 側 `lib/core/panda_type.dart` の `PandaTypeCatalog.types` と一致させること。
 *
 * 参照: docs/16type.md, lib/core/panda_type.dart
 */
export type PandaTypeDefinition = {
  slug: string
  displayName: string
  tagline: string
  /** assets/images/panda/{imageIndex}.PNG（1〜16） */
  imageIndex: number
}

export const PANDA_TYPES: Readonly<PandaTypeDefinition[]> = [
  {
    slug: 'nikopan',
    displayName: 'にこぱん',
    tagline: '優しすぎて、自分を後回しにする共感型',
    imageIndex: 1,
  },
  {
    slug: 'yurupan',
    displayName: 'ゆるぱん',
    tagline: '人生ノリでなんとかしてきた自由人',
    imageIndex: 2,
  },
  {
    slug: 'satoripan',
    displayName: 'さとりぱん',
    tagline: '静かに見守る、現実的な観察者',
    imageIndex: 3,
  },
  {
    slug: 'bosupan',
    displayName: 'ボスぱん',
    tagline: '結果を出す、論理派リーダー',
    imageIndex: 4,
  },
  {
    slug: 'mamoripan',
    displayName: 'まもりぱん',
    tagline: '守りたい気持ちが強い、堅実派',
    imageIndex: 5,
  },
  {
    slug: 'piepan',
    displayName: 'ぴえぱん',
    tagline: '感情豊かで、理想を追う繊細派',
    imageIndex: 6,
  },
  {
    slug: 'tetsupan',
    displayName: 'てつぱん',
    tagline: '冷静に支える、理想主義の参謀',
    imageIndex: 7,
  },
  {
    slug: 'hiramekipan',
    displayName: 'ひらめきぱん',
    tagline: 'ひらめきで動く、自由な発想家',
    imageIndex: 8,
  },
  {
    slug: 'fuwapa',
    displayName: 'ふわぱん',
    tagline: 'ふわっと寄り添う、夢見る癒し系',
    imageIndex: 9,
  },
  {
    slug: 'tsunpan',
    displayName: 'つんぱん',
    tagline: '素直になれない、論理派ツンデレ',
    imageIndex: 10,
  },
  {
    slug: 'otapan',
    displayName: 'おたぱん',
    tagline: '好きを極める、慎重な理想主義',
    imageIndex: 11,
  },
  {
    slug: 'kirapan',
    displayName: 'きらぱん',
    tagline: 'キラキラを追う、自由なムードメーカー',
    imageIndex: 12,
  },
  {
    slug: 'shigodekipan',
    displayName: 'しごできぱん',
    tagline: '堅実に結果を出す、現実派の仕事人',
    imageIndex: 13,
  },
  {
    slug: 'amapan',
    displayName: 'あまぱん',
    tagline: '甘え上手で、のんびり現実派',
    imageIndex: 14,
  },
  {
    slug: 'fushigipan',
    displayName: 'ふしぎぱん',
    tagline: '謎めいた魅力の、感情派インテリア',
    imageIndex: 15,
  },
  {
    slug: 'kakurepan',
    displayName: 'かくれぱん',
    tagline: '控えめだけど芯のある、理想派',
    imageIndex: 16,
  },
]

export function findPandaTypeBySlug(slug: string): PandaTypeDefinition | null {
  return PANDA_TYPES.find((t) => t.slug === slug) ?? null
}
