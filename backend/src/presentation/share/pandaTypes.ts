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
  /** Flutter で実際に使っている assets/images/panda/*.PNG のファイル名 */
  imageFileName: string
}

export const PANDA_TYPES: Readonly<PandaTypeDefinition[]> = [
  {
    slug: 'nikopan',
    displayName: 'にこぱん',
    tagline: '優しすぎて、自分を後回しにする共感型',
    imageFileName: '1.PNG',
  },
  {
    slug: 'yurupan',
    displayName: 'ゆるぱん',
    tagline: '人生ノリでなんとかしてきた自由人',
    imageFileName: '2.PNG',
  },
  {
    slug: 'satoripan',
    displayName: 'さとりぱん',
    tagline: '静かに見守る、現実的な観察者',
    imageFileName: '3.PNG',
  },
  {
    slug: 'bosupan',
    displayName: 'ボスぱん',
    tagline: '結果を出す、論理派リーダー',
    imageFileName: '4.PNG',
  },
  {
    slug: 'mamoripan',
    displayName: 'まもりぱん',
    tagline: '守りたい気持ちが強い、堅実派',
    imageFileName: '5.PNG',
  },
  {
    slug: 'piepan',
    displayName: 'ぴえぱん',
    tagline: '感情豊かで、理想を追う繊細派',
    imageFileName: '6.PNG',
  },
  {
    slug: 'tetsupan',
    displayName: 'てつぱん',
    tagline: '冷静に支える、理想主義の参謀',
    imageFileName: '7.PNG',
  },
  {
    slug: 'hiramekipan',
    displayName: 'ひらめきぱん',
    tagline: 'ひらめきで動く、自由な発想家',
    imageFileName: '8.PNG',
  },
  {
    slug: 'fuwapa',
    displayName: 'ふわぱん',
    tagline: 'ふわっと寄り添う、夢見る癒し系',
    imageFileName: '9.PNG',
  },
  {
    slug: 'tsunpan',
    displayName: 'つんぱん',
    tagline: '素直になれない、論理派ツンデレ',
    imageFileName: '10.PNG',
  },
  {
    slug: 'otapan',
    displayName: 'おたぱん',
    tagline: '好きを極める、慎重な理想主義',
    imageFileName: '11.PNG',
  },
  {
    slug: 'kirapan',
    displayName: 'きらぱん',
    tagline: 'キラキラを追う、自由なムードメーカー',
    imageFileName: '12.PNG',
  },
  {
    slug: 'shigodekipan',
    displayName: 'しごできぱん',
    tagline: '堅実に結果を出す、現実派の仕事人',
    imageFileName: '13.PNG',
  },
  {
    slug: 'amapan',
    displayName: 'あまぱん',
    tagline: '甘え上手で、のんびり現実派',
    imageFileName: '14.PNG',
  },
  {
    slug: 'fushigipan',
    displayName: 'ふしぎぱん',
    tagline: '謎めいた魅力の、感情派インテリア',
    imageFileName: '15.PNG',
  },
  {
    slug: 'kakurepan',
    displayName: 'かくれぱん',
    tagline: '控えめだけど芯のある、理想派',
    imageFileName: '16.PNG',
  },
]

export function findPandaTypeBySlug(slug: string): PandaTypeDefinition | null {
  return PANDA_TYPES.find((t) => t.slug === slug) ?? null
}
