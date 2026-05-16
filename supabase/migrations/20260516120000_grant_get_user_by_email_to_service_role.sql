-- Edge Functions は service_role で PostgREST RPC を呼ぶ。
-- get_user_by_email は anon/authenticated/public から REVOKE 済みのため、
-- service_role への GRANT が無いと admin.rpc が permission denied になる。
grant execute on function public.get_user_by_email(text) to service_role;
