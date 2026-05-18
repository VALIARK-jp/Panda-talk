-- クライアントから自分の panda_profiles 行を読む／作る／更新（Worker なしの実機開発用）。
-- 他ユーザーのプロフィール参照は引き続き API（service role）経由を想定。

create policy panda_profiles_select_own
  on public.panda_profiles
  for select
  to authenticated
  using (auth.uid() = id);

create policy panda_profiles_insert_own
  on public.panda_profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

create policy panda_profiles_update_own
  on public.panda_profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);
