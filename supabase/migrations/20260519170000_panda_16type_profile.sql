begin;

alter table public.panda_profiles
  add column if not exists panda_type_slug text,
  add column if not exists type_affection_pct smallint,
  add column if not exists type_thinking_pct smallint,
  add column if not exists type_action_pct smallint,
  add column if not exists type_life_pct smallint,
  add column if not exists diagnosed_16_at timestamptz;

alter table public.panda_profiles
  drop constraint if exists panda_profiles_type_affection_pct_check;

alter table public.panda_profiles
  add constraint panda_profiles_type_affection_pct_check
    check (type_affection_pct is null or type_affection_pct between 0 and 100),
  drop constraint if exists panda_profiles_type_thinking_pct_check,
  add constraint panda_profiles_type_thinking_pct_check
    check (type_thinking_pct is null or type_thinking_pct between 0 and 100),
  drop constraint if exists panda_profiles_type_action_pct_check,
  add constraint panda_profiles_type_action_pct_check
    check (type_action_pct is null or type_action_pct between 0 and 100),
  drop constraint if exists panda_profiles_type_life_pct_check,
  add constraint panda_profiles_type_life_pct_check
    check (type_life_pct is null or type_life_pct between 0 and 100);

commit;
