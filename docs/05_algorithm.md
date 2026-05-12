# アルゴリズム設計

## 問題フィード

全ユーザーに同じ順番（投稿順）で問題を表示する。

```sql
SELECT * FROM questions
WHERE id NOT IN (
  SELECT question_id FROM answers WHERE user_id = '自分のID'
)
ORDER BY created_at ASC
LIMIT 10;
```

**理由:** 投稿が古い問題ほど回答者が多い → 共通回答数が増えてmatch_rateの信頼度が上がる

---

## 合致度計算

```
match_rate = same_answers / common_answers
```

**例:**
```
共通回答数: 100問
同じ回答数: 87問
→ 合致度: 87%
```

---

## 信頼度スコア

共通回答数をもとに信頼係数を算出し、match_rateに掛け合わせてソートに使う。

```
display_score = match_rate * confidence(common_answer_count)

confidence(n) = n / (n + 50)
```

**例:**
```
95% / 共通5問  → 0.95 * (5/55)   = 0.086
80% / 共通50問 → 0.80 * (50/100) = 0.400
80% / 共通200問 → 0.80 * (200/250) = 0.640
```

回答数が少ない高合致より、回答数が多い中合致の方が上位に表示される。

---

## マッチ表示

`display_score = match_rate * (common_answer_count / (common_answer_count + 50))`

### 高合致（似た人）
```sql
ORDER BY (match_rate * common_answer_count / (common_answer_count + 50)) DESC
```

### 低合致（真逆の人）
```sql
ORDER BY ((1 - match_rate) * common_answer_count / (common_answer_count + 50)) DESC
```

### 中合致（50%付近）
```sql
ORDER BY (ABS(match_rate - 0.5) * common_answer_count / (common_answer_count + 50)) ASC
```

---

## match_scores 更新戦略

### インクリメンタル更新（採用方針）

バッチ再計算はしない。**回答イベントをトリガーに差分だけ更新する。**

```
ユーザーAが問題Qに回答
  ↓
問題Qに回答済みのユーザー一覧を取得
  ↓
各ユーザーBとのmatch_scoreを upsert
  - common_answer_count += 1
  - same_answer_count += 1（一致した場合）
  - match_rate = same_answer_count / common_answer_count
```

**計算量:** O(問題Qの回答者数) — 回答者が増えるほど1回あたりの更新量が増えるが、バッチより大幅に軽い

### レコード数

- ペアごとに1レコード（nC2件が上限）
- 共通回答が0問のペアはレコードなし → 実際はnC2より大幅に少ない

| ユーザー数 | 最大レコード数 |
|---|---|
| 1,000人 | 約50万 |
| 10,000人 | 約5,000万 |

---

## グループ自動生成ロジック

### トリガー設計

2種類のトリガーでグループを生成する。

```
① 新規ユーザー登録時
    → 登録したユーザーをグループに即時アサイン

② 月次バッチ（毎月1日 0:00）
    → 全ユーザーのグループを再編成
```

---

### ① 新規登録時の即時アサイン

```
新規ユーザー登録
  ↓
match_scoresから上位マッチを取得
  ↓
既存グループに空きスロットがあれば順番に埋める
  ↓
空きがなければ新規グループ候補を探す
  （3人全ペアが条件を満たすか検証）
  ↓
成立すればグループ作成・通知送信
```

**空きスロットの「順番」:**
- グループは3人固定
- グループメンバーの退会などで2人以下になった場合、`group_members` のレコード数が条件
- 空きが生じたグループを `created_at ASC` 順（古い順）に並べ、先に埋めていく

---

### ② 月次バッチ処理

```
毎月1日 0:00（Supabase Cron Job）
  ↓
全ユーザーの match_scores を取得
  ↓
type別に3人グループを再生成
  ↓
既存グループと差分比較
  - メンバー変化あり → グループ更新・通知
  - 変化なし → スキップ
```

**再編成ポリシー:**
- 既存グループのメンバーが条件を満たし続ける場合はそのまま継続
- 条件を外れた場合のみ解散・再生成
- ユーザーが回答を増やすことで合致度が変化 → 月次でグループが変わることがある

---

### グループ成立条件（type別）

| type | 条件 |
|---|---|
| high_match | 3人全ペアの match_rate ≥ 0.75 |
| middle_match | 3人全ペアの match_rate が 0.45〜0.55 |
| low_match | 3人全ペアの match_rate ≤ 0.35 |

3C2 = 3組すべてが条件を満たす場合のみ成立。

---

### 実装方式

```
Supabase Cron Job（pg_cron）
  → Edge Function: generateGroups()
    → match_scores を type別にクエリ
    → 3人組を探索してグループ INSERT
    → notifications INSERT（グループ生成通知）
    → FCM で push 送信
```
