begin;

create extension if not exists pgcrypto;
create extension if not exists citext;

do $$
begin
  create type public.answer_choice as enum ('a', 'b');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.friendship_status as enum ('pending', 'accepted');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.group_type as enum ('high_match', 'middle_match', 'low_match');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.notification_type as enum (
    'like',
    'comment',
    'friend_request',
    'friend_accepted',
    'new_match',
    'group_created'
  );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.platform as enum ('ios', 'android');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.panda_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email citext unique,
  username citext not null unique,
  name text not null,
  avatar_url text,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint panda_profiles_username_format check (username::text ~ '^[A-Za-z0-9_]{3,30}$'),
  constraint panda_profiles_name_not_blank check (btrim(name) <> '')
);

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.panda_profiles(id) on delete cascade,
  text text not null,
  option_a text not null,
  option_b text not null,
  category text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint questions_text_not_blank check (btrim(text) <> ''),
  constraint questions_option_a_not_blank check (btrim(option_a) <> ''),
  constraint questions_option_b_not_blank check (btrim(option_b) <> '')
);

create table if not exists public.answers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.panda_profiles(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  choice public.answer_choice not null,
  created_at timestamptz not null default now(),
  unique (user_id, question_id)
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references public.panda_profiles(id) on delete cascade,
  user_b_id uuid not null references public.panda_profiles(id) on delete cascade,
  requested_by uuid not null references public.panda_profiles(id) on delete cascade,
  status public.friendship_status not null default 'pending',
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  unique (user_a_id, user_b_id),
  constraint friendships_ordered_pair check (user_a_id < user_b_id),
  constraint friendships_requested_by_pair_member check (requested_by in (user_a_id, user_b_id)),
  constraint friendships_accepted_at_status check (
    (status = 'accepted' and accepted_at is not null)
    or (status = 'pending' and accepted_at is null)
  )
);

create table if not exists public.match_scores (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references public.panda_profiles(id) on delete cascade,
  user_b_id uuid not null references public.panda_profiles(id) on delete cascade,
  match_rate double precision not null,
  common_answer_count integer not null,
  same_answer_count integer not null,
  display_score double precision generated always as (
    match_rate * (common_answer_count::double precision / (common_answer_count + 50))
  ) stored,
  updated_at timestamptz not null default now(),
  unique (user_a_id, user_b_id),
  constraint match_scores_ordered_pair check (user_a_id < user_b_id),
  constraint match_scores_rate_range check (match_rate >= 0 and match_rate <= 1),
  constraint match_scores_counts_valid check (
    common_answer_count > 0
    and same_answer_count >= 0
    and same_answer_count <= common_answer_count
  )
);

create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type public.group_type not null,
  created_at timestamptz not null default now(),
  constraint groups_name_not_blank check (btrim(name) <> '')
);

create table if not exists public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.panda_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (group_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.panda_profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint messages_body_not_blank check (btrim(body) <> '')
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  user_id uuid not null references public.panda_profiles(id) on delete cascade,
  choice public.answer_choice not null,
  body text not null,
  created_at timestamptz not null default now(),
  constraint comments_body_not_blank check (btrim(body) <> '')
);

create table if not exists public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.panda_profiles(id) on delete cascade,
  receiver_id uuid not null references public.panda_profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint direct_messages_distinct_users check (sender_id <> receiver_id),
  constraint direct_messages_body_not_blank check (btrim(body) <> '')
);

create table if not exists public.question_likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.panda_profiles(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, question_id)
);

create table if not exists public.comment_likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.panda_profiles(id) on delete cascade,
  comment_id uuid not null references public.comments(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, comment_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.panda_profiles(id) on delete cascade,
  actor_id uuid references public.panda_profiles(id) on delete set null,
  type public.notification_type not null,
  target_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.panda_profiles(id) on delete cascade,
  token text not null,
  platform public.platform not null,
  updated_at timestamptz not null default now(),
  unique (user_id, token),
  constraint push_tokens_token_not_blank check (btrim(token) <> '')
);

create table if not exists public.notification_settings (
  user_id uuid primary key references public.panda_profiles(id) on delete cascade,
  likes_enabled boolean not null default true,
  comments_enabled boolean not null default true,
  friend_requests_enabled boolean not null default true,
  matches_enabled boolean not null default true,
  groups_enabled boolean not null default true,
  messages_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_panda_profiles_updated_at on public.panda_profiles;
create trigger set_panda_profiles_updated_at
before update on public.panda_profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_questions_updated_at on public.questions;
create trigger set_questions_updated_at
before update on public.questions
for each row execute function public.set_updated_at();

drop trigger if exists set_push_tokens_updated_at on public.push_tokens;
create trigger set_push_tokens_updated_at
before update on public.push_tokens
for each row execute function public.set_updated_at();

drop trigger if exists set_notification_settings_updated_at on public.notification_settings;
create trigger set_notification_settings_updated_at
before update on public.notification_settings
for each row execute function public.set_updated_at();

create index if not exists idx_panda_profiles_username_prefix
  on public.panda_profiles (lower(username::text) text_pattern_ops);

create index if not exists idx_questions_created_at
  on public.questions (created_at, id);

create index if not exists idx_answers_question_choice
  on public.answers (question_id, choice);

create index if not exists idx_friendships_user_a_status
  on public.friendships (user_a_id, status);

create index if not exists idx_friendships_user_b_status
  on public.friendships (user_b_id, status);

create index if not exists idx_match_scores_user_a_display
  on public.match_scores (user_a_id, display_score desc);

create index if not exists idx_match_scores_user_b_display
  on public.match_scores (user_b_id, display_score desc);

create index if not exists idx_comments_question_created_at
  on public.comments (question_id, created_at desc, id desc);

create index if not exists idx_question_likes_question_id
  on public.question_likes (question_id);

create index if not exists idx_comment_likes_comment_id
  on public.comment_likes (comment_id);

create index if not exists idx_notifications_user_id_unread
  on public.notifications (user_id, is_read, created_at desc);

create or replace view public.question_stats
with (security_invoker = true) as
select
  q.id as question_id,
  count(a.id) filter (where a.choice = 'a')::integer as count_a,
  count(a.id) filter (where a.choice = 'b')::integer as count_b,
  count(a.id)::integer as total_count
from public.questions q
left join public.answers a on a.question_id = q.id
group by q.id;

create or replace view public.hot_questions
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
from public.questions q
join public.panda_profiles u on u.id = q.user_id
left join public.question_likes ql on ql.question_id = q.id
left join public.comments c on c.question_id = q.id
group by q.id, u.id;

create or replace view public.comment_summaries
with (security_invoker = true) as
select
  c.id,
  c.question_id,
  c.user_id,
  c.choice,
  c.body,
  c.created_at,
  count(cl.id)::integer as like_count
from public.comments c
left join public.comment_likes cl on cl.comment_id = c.id
group by c.id;

create or replace view public.user_oddball_scores
with (security_invoker = true) as
with stats as (
  select
    question_id,
    count_a,
    count_b
  from public.question_stats
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
left join public.answers a on a.user_id = u.id
left join stats s on s.question_id = a.question_id
group by u.id;

alter table public.panda_profiles enable row level security;
alter table public.questions enable row level security;
alter table public.answers enable row level security;
alter table public.friendships enable row level security;
alter table public.match_scores enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.messages enable row level security;
alter table public.comments enable row level security;
alter table public.direct_messages enable row level security;
alter table public.question_likes enable row level security;
alter table public.comment_likes enable row level security;
alter table public.notifications enable row level security;
alter table public.push_tokens enable row level security;
alter table public.notification_settings enable row level security;

comment on table public.panda_profiles is 'Panda Talk用プロフィール。Supabase Auth UIDと1:1で紐づく。';
comment on table public.questions is 'ユーザー投稿の二択質問。';
comment on table public.answers is '登録ユーザーの回答。ゲスト回答は登録前は端末ローカルに保持する。';
comment on table public.friendships is '相互承認制の友達関係。UUID順で1ペア1レコードに固定する。';
comment on table public.match_scores is '共通回答から更新するユーザーペアごとの合致度キャッシュ。';
comment on table public.notifications is 'アプリ内お知らせ。プッシュ配信はnotifications追加を起点に別処理で行う。';
comment on view public.question_stats is '質問ごとの回答数集計。回答直後の比率表示に使う。';
comment on view public.hot_questions is 'Hotタブ用。いいね数+コメント数をheat_scoreとして返す。';
comment on view public.comment_summaries is 'コメント一覧用。コメント本文といいね数を返す。';
comment on view public.user_oddball_scores is 'プロフィール用。少数派回答率から異端児スコアを返す。';

commit;
