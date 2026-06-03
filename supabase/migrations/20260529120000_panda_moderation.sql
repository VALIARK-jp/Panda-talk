-- UGC moderation: content reports and user blocks (App Store Guideline 1.2)

do $$
begin
  create type public.panda_report_target_type as enum ('question', 'user');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.panda_content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.panda_profiles(id) on delete cascade,
  target_type public.panda_report_target_type not null,
  target_id text not null,
  reason text not null,
  detail text,
  created_at timestamptz not null default now()
);

create index if not exists idx_panda_content_reports_reporter
  on public.panda_content_reports (reporter_id, created_at desc);

create index if not exists idx_panda_content_reports_target
  on public.panda_content_reports (target_type, target_id);

create table if not exists public.panda_user_blocks (
  blocker_id uuid not null references public.panda_profiles(id) on delete cascade,
  blocked_id uuid not null references public.panda_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint panda_user_blocks_not_self check (blocker_id <> blocked_id)
);

create index if not exists idx_panda_user_blocks_blocked
  on public.panda_user_blocks (blocked_id);

alter table public.panda_content_reports enable row level security;
alter table public.panda_user_blocks enable row level security;

comment on table public.panda_content_reports is 'UGC通報（質問・ユーザー）。運営は service_role で参照。';
comment on table public.panda_user_blocks is 'ユーザーブロック。blocker が blocked を非表示にする。';
