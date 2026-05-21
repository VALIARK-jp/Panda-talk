-- 異端児スコア: 1問のみの回答は多数派、同票は両方多数派
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
from public.panda_profiles u
left join public.panda_answers a on a.user_id = u.id
left join stats s on s.question_id = a.question_id
group by u.id;

comment on view public.panda_user_oddball_scores is
  'プロフィール用。少数派回答率（1票のみ・同票は多数派扱い）。';
