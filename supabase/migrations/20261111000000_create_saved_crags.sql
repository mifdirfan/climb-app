-- ============================================================================
-- Migration: create public.saved_crags
-- Purpose : Per-user bookmarks of outdoor crags, shown on
--           Profile > "Saved Crags & Topos".
-- Source  : CragDetailScreen bookmark toggle -> SavedCragRepository
-- Sink    : SavedCragsScreen (via savedCragsProvider)
-- ============================================================================

create table if not exists public.saved_crags (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  crag_id uuid not null references public.crags(id) on delete cascade,
  created_at timestamptz default now(),
  -- A climber can bookmark a given crag only once.
  constraint saved_crags_user_crag_unique unique (user_id, crag_id)
);

alter table public.saved_crags enable row level security;

-- B-tree indexes on foreign keys
create index if not exists idx_saved_crags_user_id on public.saved_crags(user_id);
create index if not exists idx_saved_crags_crag_id on public.saved_crags(crag_id);

-- RLS: bookmarks are private to their owner.
-- `(select auth.uid())` is evaluated once per statement instead of per row.
create policy "Users can view own saved crags"
  on public.saved_crags for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own saved crags"
  on public.saved_crags for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own saved crags"
  on public.saved_crags for delete
  using ((select auth.uid()) = user_id);

notify pgrst, 'reload schema';
