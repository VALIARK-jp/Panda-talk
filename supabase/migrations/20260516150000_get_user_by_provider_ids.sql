-- プロバイダ ID で既存 auth ユーザーを引く（メール表現がログインごとに変わる Apple / LINE 対策）。
-- メールのみでの検索だと同じ利用者でもヒットせず createUser ＝新規扱いになる。

create or replace function public.get_user_by_apple_id(apple_sub text)
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select id
  from auth.users
  where coalesce(raw_app_meta_data->>'apple_id', '') = coalesce(trim(apple_sub), '')
  limit 1;
$$;

create or replace function public.get_user_by_line_id(line_uid text)
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select id
  from auth.users
  where coalesce(raw_app_meta_data->>'line_id', '') = coalesce(trim(line_uid), '')
  limit 1;
$$;

revoke execute on function public.get_user_by_apple_id(text) from anon, authenticated, public;
revoke execute on function public.get_user_by_line_id(text) from anon, authenticated, public;

grant execute on function public.get_user_by_apple_id(text) to service_role;
grant execute on function public.get_user_by_line_id(text) to service_role;
