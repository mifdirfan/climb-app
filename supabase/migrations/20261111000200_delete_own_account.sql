-- Self-service account deletion.
--
-- The client (anon/authenticated key) cannot delete from auth.users, so the app
-- calls this SECURITY DEFINER function via `rpc('delete_own_account')`.
-- It only ever deletes the caller (auth.uid()); there is no user-id parameter
-- to tamper with.
--
-- Cascade (see schema.sql / saved_crags migration):
--   auth.users -> public.profiles (on delete cascade)
--     -> ticks, indoor_sessions, saved_crags (on delete cascade)
--     -> topos.uploaded_by, hazard_alerts.user_id (on delete set null: shared
--        community data is kept, anonymised)

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

notify pgrst, 'reload schema';
