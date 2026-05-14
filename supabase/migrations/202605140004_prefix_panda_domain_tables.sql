begin;

-- Views depend on table names; drop before renames.
drop view if exists public.user_oddball_scores;
drop view if exists public.comment_summaries;
drop view if exists public.hot_questions;
drop view if exists public.question_stats;

-- Domain tables → panda_* (FKs follow renames automatically).
alter table public.questions rename to panda_questions;
alter table public.answers rename to panda_answers;
alter table public.friendships rename to panda_friendships;
alter table public.match_scores rename to panda_match_scores;
alter table public.groups rename to panda_groups;
alter table public.group_members rename to panda_group_members;
alter table public.messages rename to panda_messages;
alter table public.comments rename to panda_comments;
alter table public.direct_messages rename to panda_direct_messages;
alter table public.question_likes rename to panda_question_likes;
alter table public.comment_likes rename to panda_comment_likes;
alter table public.notifications rename to panda_notifications;
alter table public.push_tokens rename to panda_push_tokens;
alter table public.notification_settings rename to panda_notification_settings;

-- Triggers: drop old names, recreate with panda-prefixed names.
drop trigger if exists set_questions_updated_at on public.panda_questions;
create trigger set_panda_questions_updated_at
before update on public.panda_questions
for each row execute function public.set_updated_at();

drop trigger if exists set_push_tokens_updated_at on public.panda_push_tokens;
create trigger set_panda_push_tokens_updated_at
before update on public.panda_push_tokens
for each row execute function public.set_updated_at();

drop trigger if exists set_notification_settings_updated_at on public.panda_notification_settings;
create trigger set_panda_notification_settings_updated_at
before update on public.panda_notification_settings
for each row execute function public.set_updated_at();

-- Indexes (names kept from original create; rename for clarity).
alter index if exists public.idx_questions_created_at
  rename to idx_panda_questions_created_at;
alter index if exists public.idx_answers_question_choice
  rename to idx_panda_answers_question_choice;
alter index if exists public.idx_friendships_user_a_status
  rename to idx_panda_friendships_user_a_status;
alter index if exists public.idx_friendships_user_b_status
  rename to idx_panda_friendships_user_b_status;
alter index if exists public.idx_match_scores_user_a_display
  rename to idx_panda_match_scores_user_a_display;
alter index if exists public.idx_match_scores_user_b_display
  rename to idx_panda_match_scores_user_b_display;
alter index if exists public.idx_comments_question_created_at
  rename to idx_panda_comments_question_created_at;
alter index if exists public.idx_question_likes_question_id
  rename to idx_panda_question_likes_question_id;
alter index if exists public.idx_comment_likes_comment_id
  rename to idx_panda_comment_likes_comment_id;
alter index if exists public.idx_notifications_user_id_unread
  rename to idx_panda_notifications_user_id_unread;

-- Recreate views with panda_* names.
create or replace view public.panda_question_stats
with (security_invoker = true) as
select
  q.id as question_id,
  count(a.id) filter (where a.choice = 'a')::integer as count_a,
  count(a.id) filter (where a.choice = 'b')::integer as count_b,
  count(a.id)::integer as total_count
from public.panda_questions q
left join public.panda_answers a on a.question_id = q.id
group by q.id;

create or replace view public.panda_hot_questions
with (security_invoker = true) as
select
  q.id,
  q.user_id,
  u.username,
  u.avatar_url,
  q.text,
  q.option_a,
  q.option_b,
  q.category,
  q.created_at,
  count(distinct ql.id)::integer as like_count,
  count(distinct c.id)::integer as comment_count,
  (count(distinct ql.id) + count(distinct c.id))::integer as heat_score
from public.panda_questions q
join public.panda_profiles u on u.id = q.user_id
left join public.panda_question_likes ql on ql.question_id = q.id
left join public.panda_comments c on c.question_id = q.id
group by q.id, u.id;

create or replace view public.panda_comment_summaries
with (security_invoker = true) as
select
  c.id,
  c.question_id,
  c.user_id,
  c.choice,
  c.body,
  c.created_at,
  count(cl.id)::integer as like_count
from public.panda_comments c
left join public.panda_comment_likes cl on cl.comment_id = c.id
group by c.id;

create or replace view public.panda_user_oddball_scores
with (security_invoker = true) as
with stats as (
  select
    question_id,
    count_a,
    count_b
  from public.panda_question_stats
)
select
  u.id as user_id,
  count(a.id)::integer as total_answer_count,
  count(a.id) filter (
    where
      (a.choice = 'a' and s.count_a < s.count_b)
      or (a.choice = 'b' and s.count_b < s.count_a)
  )::integer as minority_answer_count,
  case
    when count(a.id) = 0 then 0
    else round(
      (
        count(a.id) filter (
          where
            (a.choice = 'a' and s.count_a < s.count_b)
            or (a.choice = 'b' and s.count_b < s.count_a)
        )::numeric / count(a.id)::numeric
      ) * 100
    )::integer
  end as oddball_score
from public.panda_profiles u
left join public.panda_answers a on a.user_id = u.id
left join stats s on s.question_id = a.question_id
group by u.id;

comment on view public.panda_question_stats is '質問ごとの回答数集計。回答直後の比率表示に使う。';
comment on view public.panda_hot_questions is 'Hotタブ用。いいね数+コメント数をheat_scoreとして返す。';
comment on view public.panda_comment_summaries is 'コメント一覧用。コメント本文といいね数を返す。';
comment on view public.panda_user_oddball_scores is 'プロフィール用。少数派回答率から異端児スコアを返す。';

comment on table public.panda_questions is 'ユーザー投稿の二択質問。';
comment on table public.panda_answers is '登録ユーザーの回答。ゲスト回答は登録前は端末ローカルに保持する。';
comment on table public.panda_friendships is '相互承認制の友達関係。UUID順で1ペア1レコードに固定する。';
comment on table public.panda_match_scores is '共通回答から更新するユーザーペアごとの合致度キャッシュ。';
comment on table public.panda_notifications is 'アプリ内お知らせ。プッシュ配信はnotifications追加を起点に別処理で行う。';

commit;
