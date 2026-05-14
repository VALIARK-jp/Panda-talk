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
    where email = user_email
    limit 1
  );
end;
$$;

revoke execute on function public.get_user_by_email(text) from anon, authenticated, public;
