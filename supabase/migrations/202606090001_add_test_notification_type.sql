begin;

do $$
begin
  alter type public.notification_type add value 'test';
exception
  when duplicate_object then null;
end $$;

commit;
