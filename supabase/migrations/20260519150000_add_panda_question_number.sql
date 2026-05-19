begin;

create sequence if not exists public.panda_questions_question_number_seq;

alter table public.panda_questions
  add column if not exists question_number bigint;

with numbered as (
  select
    id,
    row_number() over (order by created_at asc, id asc) as next_number
  from public.panda_questions
  where question_number is null
)
update public.panda_questions q
set question_number = numbered.next_number
from numbered
where q.id = numbered.id;

do $$
declare
  max_question_number bigint;
begin
  select coalesce(max(question_number), 0)
  into max_question_number
  from public.panda_questions;

  perform setval(
    'public.panda_questions_question_number_seq',
    greatest(max_question_number, 1),
    max_question_number > 0
  );
end $$;

alter table public.panda_questions
  alter column question_number set default nextval('public.panda_questions_question_number_seq'),
  alter column question_number set not null;

alter sequence public.panda_questions_question_number_seq
  owned by public.panda_questions.question_number;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'panda_questions_question_number_key'
      and conrelid = 'public.panda_questions'::regclass
  ) then
    alter table public.panda_questions
      add constraint panda_questions_question_number_key unique (question_number);
  end if;
end $$;

drop view if exists public.panda_hot_questions;

create view public.panda_hot_questions
with (security_invoker = true) as
select
  q.id,
  q.question_number,
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

comment on view public.panda_hot_questions is 'Hotタブ用。いいね数+コメント数をheat_scoreとして返す。';
comment on column public.panda_questions.question_number is 'ユーザー向け表示用のQ番号。1始まりで投稿順に採番する。';

commit;
