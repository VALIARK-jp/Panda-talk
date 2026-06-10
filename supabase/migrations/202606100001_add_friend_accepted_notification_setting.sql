begin;

alter table public.panda_notification_settings
  add column if not exists friend_accepted_enabled boolean not null default true;

update public.panda_notification_settings
set friend_accepted_enabled = coalesce(friend_accepted_enabled, friend_requests_enabled, true)
where friend_accepted_enabled is null;

commit;
