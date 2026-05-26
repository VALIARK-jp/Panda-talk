-- Run in Supabase SQL Editor on valiark-prod.
-- Purpose: seed Q1-Q16 as panda_questions for a specific operator user.
-- Default user_id here is the one provided in chat; change only if needed.

begin;

-- Ensure this user exists in panda_profiles (required by FK on panda_questions.user_id).
-- If this fails, create the profile row first (or login once with this account).
do $$
declare
  _uid uuid := '5aafcbd6-efa8-4d34-8c8d-776e9f8f1c22';
begin
  if not exists (select 1 from public.panda_profiles p where p.id = _uid) then
    raise exception 'panda_profiles row not found for user_id=%', _uid;
  end if;
end $$;

with target_user as (
  select '5aafcbd6-efa8-4d34-8c8d-776e9f8f1c22'::uuid as user_id
)
insert into public.panda_questions (user_id, text, option_a, option_b, category)
select
  t.user_id,
  q.text,
  q.option_a,
  q.option_b,
  q.category
from target_user t
cross join (
  values
    ('恋人にされて嫌なのは？', '放置される', '束縛される', '恋愛'),
    ('将来なりたいのは？', '好きなことして生きる', '安定して暮らす', '生活'),
    ('友達が自分抜きで遊んでた', '普通に傷つく', '別に気にならない', '友達'),
    ('旅行するなら？', '秒単位で計画したい', 'ノープランがいい', '旅行'),
    ('相談された時、先に考えるのは？', '気持ち', '解決方法', '性格'),
    ('理想の休日は？', '家でゆっくり', '知らない場所へ行く', '生活'),
    ('締切が1週間後です', 'すぐやる', 'ギリギリでやる', '仕事'),
    ('プレゼントでもらって嬉しいのは？', '思い出に残るもの', '実用的なもの', '生活'),
    ('ケンカしたら？', 'とりあえず謝る', '納得するまで話す', '性格'),
    ('デートするなら？', '計画したい', '流れで決めたい', '恋愛'),
    ('恋愛するなら？', '安心したい', 'ドキドキしたい', '恋愛'),
    ('信じたいのは？', '直感', 'データ', '性格'),
    ('宝くじで1億円当たったら？', 'やりたいこと始める', 'とりあえず貯金する', 'お金'),
    ('嫌なのは？', '冷たく論破される', '感情的に怒鳴られる', '性格'),
    ('好きな食べ物は？', '最初に食べる', '最後まで残す', '食べ物'),
    ('SNSで一番嫌なのは？', '既読無視', '炎上すること', '生活')
) as q(text, option_a, option_b, category);

commit;

-- Verification queries:
-- select question_number, text, category from public.panda_questions order by question_number asc limit 20;
-- select count(*) from public.panda_questions;
