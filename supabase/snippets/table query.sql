-- ============================================================
-- ClimbMY Database Schema (Optimized)
-- ============================================================

create extension if not exists "uuid-ossp";

-- Drop legacy triggers if any exist
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- ============================================================
-- 1. CORE IDENTITY & PROFILES
-- ============================================================

create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  display_name text,
  avatar_url text,
  grade_system text default 'v_scale' check (grade_system in ('french', 'v_scale')),
  created_at timestamptz default now()
);

-- Idempotent trigger for auth signups
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data->>'username',
    coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'full_name', 'Climber'),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- 2. UNIFIED VENUES (Indoor Gyms & Outdoor Crags)
-- ============================================================

create table public.crags (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  venue_type text not null default 'indoor' check (venue_type in ('outdoor', 'indoor')),
  state text not null,
  
  -- Indoor-specific attributes
  address text,
  operating_hours text,
  phone text,
  instagram text,
  grading_scale jsonb default '[]'::jsonb, -- e.g., [{"label": "Yellow", "hex": "#FACC15", "v_min": 0, "v_max": 1}]
  
  -- Outdoor-specific attributes
  approach_notes text,
  parking_lat double precision,
  parking_long double precision,
  access_restrictions text,
  
  created_at timestamptz default now()
);

-- ============================================================
-- 3. INDOOR TRAINING DOMAIN (Session Logging)
-- ============================================================

create table public.indoor_sessions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  gym_id uuid references public.crags(id) on delete cascade not null,
  session_date date default current_date not null,
  duration_minutes integer,
  felt_grade text check (felt_grade in ('easy', 'average', 'hard', 'limit')),
  rating integer check (rating >= 1 and rating <= 5),
  notes text,
  grade_tallies jsonb default '{}'::jsonb not null, -- e.g., {"Yellow": 4, "Blue": 2}
  created_at timestamptz default now()
);

-- ============================================================
-- 4. OUTDOOR GUIDEBOOK DOMAIN (Permanent Geography)
-- ============================================================

create table public.sectors (
  id uuid default gen_random_uuid() primary key,
  crag_id uuid references public.crags(id) on delete cascade not null,
  name text not null,
  description text,
  created_at timestamptz default now()
);

create table public.routes (
  id uuid default gen_random_uuid() primary key,
  sector_id uuid references public.sectors(id) on delete cascade not null,
  name text not null,
  grade text not null,
  route_type text not null default 'boulder' check (route_type in ('boulder', 'sport', 'trad')),
  is_active boolean default true,
  description text,
  created_at timestamptz default now()
);

create table public.topos (
  id uuid default gen_random_uuid() primary key,
  sector_id uuid references public.sectors(id) on delete cascade not null,
  image_url text not null,
  uploaded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now()
);

create table public.ticks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  route_id uuid references public.routes(id) on delete cascade not null,
  tick_type text not null check (tick_type in ('flash', 'send', 'onsight', 'dab', 'repeat', 'project')),
  notes text,
  climbed_at date default current_date not null,
  created_at timestamptz default now()
);

create table public.hazard_alerts (
  id uuid default gen_random_uuid() primary key,
  sector_id uuid references public.sectors(id) on delete cascade not null,
  route_id uuid references public.routes(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  hazard_type text not null check (hazard_type in ('wasps', 'loose_rock', 'bad_bolt', 'other')),
  description text not null,
  status text default 'active' check (status in ('active', 'resolved')),
  created_at timestamptz default now()
);



-- ============================================================
-- 5. ROW LEVEL SECURITY (RLS) & POLICIES
-- ============================================================

alter table public.profiles enable row level security;
alter table public.crags enable row level security;
alter table public.sectors enable row level security;
alter table public.routes enable row level security;
alter table public.topos enable row level security;
alter table public.indoor_sessions enable row level security;
alter table public.ticks enable row level security;
alter table public.hazard_alerts enable row level security;

-- Public Guidebook Access
create policy "Allow public read on profiles" on public.profiles for select using (true);
create policy "Allow users to update own profile" on public.profiles for update using (auth.uid() = id);

create policy "Allow public read on crags" on public.crags for select using (true);
create policy "Allow public read on sectors" on public.sectors for select using (true);
create policy "Allow public read on routes" on public.routes for select using (true);
create policy "Allow public read on topos" on public.topos for select using (true);
create policy "Allow public read on hazard_alerts" on public.hazard_alerts for select using (true);

-- User-Scoped Indoor Sessions (Private logs)
create policy "Users can view own indoor sessions" on public.indoor_sessions for select using (auth.uid() = user_id);
create policy "Users can insert own indoor sessions" on public.indoor_sessions for insert with check (auth.uid() = user_id);
create policy "Users can update own indoor sessions" on public.indoor_sessions for update using (auth.uid() = user_id);
create policy "Users can delete own indoor sessions" on public.indoor_sessions for delete using (auth.uid() = user_id);

-- User-Scoped Outdoor Ticks
create policy "Users can view all ticks" on public.ticks for select using (true);
create policy "Users can insert own ticks" on public.ticks for insert with check (auth.uid() = user_id);
create policy "Users can update own ticks" on public.ticks for update using (auth.uid() = user_id);
create policy "Users can delete own ticks" on public.ticks for delete using (auth.uid() = user_id);

-- Community Hazards
create policy "Authenticated users can submit hazards" on public.hazard_alerts for insert with check (auth.role() = 'authenticated');
create policy "Users can update own hazards" on public.hazard_alerts for update using (auth.uid() = user_id);

-- ============================================================
-- 6. REFRESH SCHEMA CACHE
-- ============================================================

notify pgrst, 'reload schema';