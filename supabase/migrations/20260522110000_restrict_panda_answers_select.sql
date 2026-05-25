begin;

drop policy if exists panda_answers_select_authenticated
  on public.panda_answers;

create policy panda_answers_select_own
  on public.panda_answers
  for select
  to authenticated
  using (auth.uid() = user_id);

create or replace function public.get_panda_question_stats(p_question_id uuid)
returns table (
  question_id uuid,
  count_a integer,
  count_b integer,
  total_count integer
)
language sql
security definer
set search_path = public
as $$
  select
    a.question_id,
    count(*) filter (where a.choice = 'a')::integer as count_a,
    count(*) filter (where a.choice = 'b')::integer as count_b,
    count(*)::integer as total_count
  from public.panda_answers a
  where a.question_id = p_question_id
  group by a.question_id
$$;

revoke all on function public.get_panda_question_stats(uuid) from public;
grant execute on function public.get_panda_question_stats(uuid) to anon, authenticated;

create or replace function public.get_my_panda_oddball_score()
returns table (
  user_id uuid,
  total_answer_count integer,
  minority_answer_count integer,
  oddball_score integer
)
language sql
security definer
set search_path = public
as $$
  with my_answers as (
    select id, user_id, question_id, choice
    from public.panda_answers
    where user_id = auth.uid()
  ),
  stats as (
    select *
    from public.panda_question_stats
    where question_id in (select question_id from my_answers)
  )
  select
    auth.uid() as user_id,
    count(a.id)::integer as total_answer_count,
    count(a.id) filter (
      where
        (s.count_a + s.count_b) > 1
        and s.count_a != s.count_b
        and (
          (a.choice = 'a' and s.count_a < s.count_b)
          or (a.choice = 'b' and s.count_b < s.count_a)
        )
    )::integer as minority_answer_count,
    case
      when count(a.id) = 0 then 0
      else round(
        (
          count(a.id) filter (
            where
              (s.count_a + s.count_b) > 1
              and s.count_a != s.count_b
              and (
                (a.choice = 'a' and s.count_a < s.count_b)
                or (a.choice = 'b' and s.count_b < s.count_a)
              )
          )::numeric / count(a.id)::numeric
        ) * 100
      )::integer
    end as oddball_score
  from my_answers a
  left join stats s on s.question_id = a.question_id
$$;

revoke all on function public.get_my_panda_oddball_score() from public;
grant execute on function public.get_my_panda_oddball_score() to authenticated;

commit;
