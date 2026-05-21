-- 物理削除後に question_number を 1 始まりで欠番なく詰める。
-- 新規投稿は sequence（max 同期済み）で max+1 が付く。

begin;

-- 既存データの欠番を 1..N に整列（二段 UPDATE で UNIQUE 衝突を避ける）
with ordered as (
  select
    id,
    row_number() over (
      order by question_number asc, created_at asc, id asc
    ) as rn
  from public.panda_questions
)
update public.panda_questions q
set question_number = -o.rn
from ordered o
where q.id = o.id;

update public.panda_questions
set question_number = -question_number;

select setval(
  'public.panda_questions_question_number_seq',
  greatest(coalesce((select max(question_number) from public.panda_questions), 0), 1),
  (select count(*) > 0 from public.panda_questions)
);

create or replace function public.panda_questions_renumber_after_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.panda_questions
  set question_number = question_number - 1
  where question_number > old.question_number;

  perform setval(
    'public.panda_questions_question_number_seq',
    greatest(coalesce((select max(question_number) from public.panda_questions), 0), 1),
    (select count(*) > 0 from public.panda_questions)
  );

  return old;
end;
$$;

drop trigger if exists panda_questions_renumber_after_delete_trg on public.panda_questions;

create trigger panda_questions_renumber_after_delete_trg
after delete on public.panda_questions
for each row
execute function public.panda_questions_renumber_after_delete();

comment on function public.panda_questions_renumber_after_delete() is
  '質問削除後、残りの question_number を 1 始まりで詰め直し、sequence を max に同期する。';

comment on column public.panda_questions.question_number is
  'ユーザー向け Q 番号。1 始まり。削除すると後続が繰り上がる。';

commit;
