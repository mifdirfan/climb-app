-- ============================================================
-- PERFORMANCE INDEXES
-- ============================================================

create index idx_indoor_sessions_user on public.indoor_sessions(user_id);
create index idx_indoor_sessions_gym on public.indoor_sessions(gym_id);
create index idx_sectors_crag on public.sectors(crag_id);
create index idx_routes_sector on public.routes(sector_id);
create index idx_ticks_user on public.ticks(user_id);
create index idx_ticks_route on public.ticks(route_id);
create index idx_hazard_sector on public.hazard_alerts(sector_id);