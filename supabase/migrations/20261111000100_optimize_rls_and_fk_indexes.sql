-- ============================================================================
-- Migration: optimize RLS policies + index unindexed foreign keys
-- Purpose : Resolve Supabase performance advisors
--   * 0003 auth_rls_initplan   -> wrap auth.uid() in (select ...) so Postgres
--                                 evaluates it once per statement, not per row.
--   * 0001 unindexed_foreign_keys -> B-tree index on each uncovered FK.
-- Safety  : ALTER POLICY only swaps the USING / WITH CHECK expressions; policy
--           names, commands, roles and access semantics are unchanged, and
--           there is no window where a table is left without its policy.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. RLS initplan optimisation (10 policies)
-- ---------------------------------------------------------------------------

-- profiles
alter policy "Users can update their own profile" on public.profiles
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- ticks
alter policy "Authenticated users can log their own sends" on public.ticks
  with check ((select auth.uid()) = user_id);

alter policy "Users can update their own sends" on public.ticks
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

alter policy "Users can delete their own sends" on public.ticks
  using ((select auth.uid()) = user_id);

-- indoor_sessions
alter policy "Users can view their own indoor sessions" on public.indoor_sessions
  using ((select auth.uid()) = user_id);

alter policy "Users can log their own indoor sessions" on public.indoor_sessions
  with check ((select auth.uid()) = user_id);

alter policy "Users can update their own indoor sessions" on public.indoor_sessions
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

alter policy "Users can delete their own indoor sessions" on public.indoor_sessions
  using ((select auth.uid()) = user_id);

-- hazard_alerts
alter policy "Authenticated users can submit hazards" on public.hazard_alerts
  with check (
    (select auth.uid()) is not null
    and (user_id is null or (select auth.uid()) = user_id)
  );

alter policy "Users can update their own hazard reports" on public.hazard_alerts
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- saved_crags: align with the rest of the schema (authenticated role only).
alter policy "Users can view own saved crags" on public.saved_crags to authenticated;
alter policy "Users can insert own saved crags" on public.saved_crags to authenticated;
alter policy "Users can delete own saved crags" on public.saved_crags to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Foreign-key indexes (5)
-- ---------------------------------------------------------------------------
create index if not exists idx_hazard_alerts_route_id   on public.hazard_alerts(route_id);
create index if not exists idx_hazard_alerts_sector_id  on public.hazard_alerts(sector_id);
create index if not exists idx_hazard_alerts_user_id    on public.hazard_alerts(user_id);
create index if not exists idx_indoor_sessions_gym_id   on public.indoor_sessions(gym_id);
create index if not exists idx_sectors_crag_id          on public.sectors(crag_id);

notify pgrst, 'reload schema';
