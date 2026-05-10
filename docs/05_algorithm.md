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
