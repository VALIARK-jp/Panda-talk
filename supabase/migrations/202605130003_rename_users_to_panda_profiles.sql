begin;

alter table if exists public.users rename to panda_profiles;

do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'users_pkey'
      and conrelid = 'public.panda_profiles'::regclass
  ) then
    alter table public.panda_profiles
      rename constraint users_pkey to panda_profiles_pkey;
  end if;

  if exists (
    select 1
    from pg_constraint
    where conname = 'users_email_key'
      and conrelid = 'public.panda_profiles'::regclass
  ) then
    alter table public.panda_profiles
      rename constraint users_email_key to panda_profiles_email_key;
  end if;

  if exists (
    select 1
    from pg_constraint
    where conname = 'users_username_key'
      and conrelid = 'public.panda_profiles'::regclass
  ) then
    alter table public.panda_profiles
      rename constraint users_username_key to panda_profiles_username_key;
  end if;

  if exists (
    select 1
    from pg_constraint
    where conname = 'users_username_format'
      and conrelid = 'public.panda_profiles'::regclass
  ) then
    alter table public.panda_profiles
      rename constraint users_username_format to panda_profiles_username_format;
  end if;

  if exists (
    select 1
    from pg_constraint
    where conname = 'users_name_not_blank'
      and conrelid = 'public.panda_profiles'::regclass
  ) then
    alter table public.panda_profiles
      rename constraint users_name_not_blank to panda_profiles_name_not_blank;
  end if;
end $$;

alter index if exists public.idx_users_username_prefix
  rename to idx_panda_profiles_username_prefix;

drop trigger if exists set_users_updated_at on public.panda_profiles;
drop trigger if exists set_panda_profiles_updated_at on public.panda_profiles;
create trigger set_panda_profiles_updated_at
before update on public.panda_profiles
for each row execute function public.set_updated_at();

comment on table public.panda_profiles is 'Panda Talk用プロフィール。Supabase Auth UIDと1:1で紐づく。';

commit;
