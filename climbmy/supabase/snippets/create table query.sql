-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Profiles
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  display_name text,
  avatar_url text,
  grade_system text default 'french',
  created_at timestamptz default now()
);

-- 2. Crags
create table public.crags (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  state text not null,
  approach_notes text,
  parking_lat double precision,
  parking_long double precision,
  access text,
  created_at timestamptz default now()
);

-- 3. Sectors
create table public.sectors (
  id uuid default gen_random_uuid() primary key,
  crag_id uuid references public.crags(id) on delete cascade not null,
  name text not null,
  description text,
  created_at timestamptz default now()
);

-- 4. Routes
create table public.routes (
  id uuid default gen_random_uuid() primary key,
  sector_id uuid references public.sectors(id) on delete cascade not null,
  name text not null,
  grade text not null,
  route_type text check (route_type in ('sport', 'boulder', 'trad')) default 'sport',
  bolt_count integer default 0,
  height_meters double precision,
  description text,
  created_at timestamptz default now()
);

-- 5. Topos
create table public.topos (
  id uuid default gen_random_uuid() primary key,
  sector_id uuid references public.sectors(id) on delete cascade not null,
  image_url text not null,
  uploaded_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

-- 6. Ticks
create table public.ticks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  route_id uuid references public.routes(id) on delete cascade not null,
  tick_type text check (tick_type in ('onsight', 'flash', 'redpoint', 'toprope')) not null,
  notes text,
  climbed_at date default current_date,
  created_at timestamptz default now()
);

-- 7. Hazard Alerts
create table public.hazard_alerts (
  id uuid default gen_random_uuid() primary key,
  sector_id uuid references public.sectors(id) on delete cascade not null,
  route_id uuid references public.routes(id) on delete cascade,
  user_id uuid references public.profiles(id),
  hazard_type text check (hazard_type in ('wasps', 'loose_rock', 'bad_bolt', 'other')) not null,
  description text not null,
  status text default 'active',
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.crags enable row level security;
alter table public.sectors enable row level security;
alter table public.routes enable row level security;
alter table public.topos enable row level security;
alter table public.ticks enable row level security;
alter table public.hazard_alerts enable row level security;

-- Public read policies for guidebook
create policy "Allow public read crags" on public.crags for select using (true);
create policy "Allow public read sectors" on public.sectors for select using (true);
create policy "Allow public read routes" on public.routes for select using (true);
create policy "Allow public read topos" on public.topos for select using (true);
create policy "Allow public read hazards" on public.hazard_alerts for select using (true);