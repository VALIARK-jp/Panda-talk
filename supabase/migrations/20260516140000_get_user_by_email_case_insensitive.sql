-- GoTrue はメールを小文字で保持することがある一方、クライアント／IdP からは大文字混じりで届く。
-- 厳密一致だけだと既存ユーザーが見つからず createUser が「already registered」になる。
create or replace function public.get_user_by_email(user_email text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
begin
  return (
    select id
    from auth.users
    where lower(trim(coalesce(email, ''))) = lower(trim(coalesce(user_email, '')))
    limit 1
  );
end;
$$;
