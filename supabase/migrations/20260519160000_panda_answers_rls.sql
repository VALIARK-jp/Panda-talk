-- panda_answers / panda_questions / panda_friendships: RLS は有効だがポリシーが無く
-- クライアント（anon + JWT）からの SELECT/INSERT が常に拒否されていた。
-- プロフィールの回答数・投稿数・友達数、および localhost 時の Supabase 直 POST 用。

begin;

create policy panda_answers_select_authenticated
  on public.panda_answers
  for select
  to authenticated
  using (true);

create policy panda_answers_insert_own
  on public.panda_answers
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy panda_answers_update_own
  on public.panda_answers
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy panda_questions_select_own
  on public.panda_questions
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy panda_friendships_select_involved
  on public.panda_friendships
  for select
  to authenticated
  using (auth.uid() = user_a_id or auth.uid() = user_b_id);

commit;
