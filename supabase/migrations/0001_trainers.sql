-- =============================================================================
-- Pokemon Battle Arena — trainers + pokedex scaffold
-- =============================================================================
-- HOW TO APPLY (pick one):
--
-- A) Supabase Dashboard (no CLI required)
--    1. Open https://supabase.com/dashboard → your project → SQL Editor
--    2. Paste this entire file and click Run
--
-- B) Supabase CLI
--    Install (if missing):
--      npm install -g supabase
--      # or:  scoop install supabase   (Windows)
--      # or:  brew install supabase/tap/supabase  (macOS)
--    Then from the repo root:
--      supabase link --project-ref YOUR_PROJECT_REF
--      supabase db push
--
-- NOTE: An earlier prototype used `public.trainers(id, data jsonb)`. This migration
-- upgrades that shape to columnar profile fields while preserving `game_data` for
-- optional full-save cloud sync.
-- =============================================================================

create table if not exists public.trainers (
  id uuid primary key references auth.users(id) on delete cascade,
  trainer_name text not null default 'TRAINER' check (char_length(trainer_name) <= 12),
  avatar_key text not null default 'default_trainer',
  level integer not null default 1,
  xp integer not null default 0,
  wins integer not null default 0,
  losses integer not null default 0,
  win_streak integer not null default 0,
  game_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.trainers add column if not exists trainer_name text;
alter table public.trainers add column if not exists avatar_key text;
alter table public.trainers add column if not exists level integer;
alter table public.trainers add column if not exists xp integer;
alter table public.trainers add column if not exists wins integer;
alter table public.trainers add column if not exists losses integer;
alter table public.trainers add column if not exists win_streak integer;
alter table public.trainers add column if not exists game_data jsonb;
alter table public.trainers add column if not exists created_at timestamptz;
alter table public.trainers add column if not exists updated_at timestamptz;

-- Migrate legacy `data` jsonb blob → profile columns + game_data (no-op if absent).
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'trainers' and column_name = 'data'
  ) then
    execute $migrate$
      update public.trainers set
        trainer_name = coalesce(nullif(trainer_name, ''), coalesce(data->>'name', 'TRAINER')),
        avatar_key = coalesce(nullif(avatar_key, ''), 'default_trainer'),
        level = coalesce(level, nullif(data->>'level', '')::int, 1),
        xp = coalesce(xp, 0),
        wins = coalesce(wins, 0),
        losses = coalesce(losses, 0),
        win_streak = coalesce(win_streak, 0),
        game_data = coalesce(nullif(game_data, '{}'::jsonb), data, '{}'::jsonb),
        created_at = coalesce(created_at, now()),
        updated_at = coalesce(updated_at, now())
    $migrate$;
    alter table public.trainers drop column data;
  end if;
end $$;

update public.trainers set
  trainer_name = coalesce(nullif(trainer_name, ''), 'TRAINER'),
  avatar_key = coalesce(nullif(avatar_key, ''), 'default_trainer'),
  level = coalesce(level, 1),
  xp = coalesce(xp, 0),
  wins = coalesce(wins, 0),
  losses = coalesce(losses, 0),
  win_streak = coalesce(win_streak, 0),
  game_data = coalesce(game_data, '{}'::jsonb),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

alter table public.trainers
  alter column trainer_name set default 'TRAINER',
  alter column trainer_name set not null,
  alter column avatar_key set default 'default_trainer',
  alter column avatar_key set not null,
  alter column level set default 1,
  alter column level set not null,
  alter column xp set default 0,
  alter column xp set not null,
  alter column wins set default 0,
  alter column wins set not null,
  alter column losses set default 0,
  alter column losses set not null,
  alter column win_streak set default 0,
  alter column win_streak set not null,
  alter column game_data set default '{}'::jsonb,
  alter column game_data set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

alter table public.trainers enable row level security;

drop policy if exists "Trainers can view their own profile" on public.trainers;
create policy "Trainers can view their own profile"
  on public.trainers for select
  using (auth.uid() = id);

drop policy if exists "Trainers can insert their own profile" on public.trainers;
create policy "Trainers can insert their own profile"
  on public.trainers for insert
  with check (auth.uid() = id);

drop policy if exists "Trainers can update their own profile" on public.trainers;
create policy "Trainers can update their own profile"
  on public.trainers for update
  using (auth.uid() = id);

drop policy if exists "trainers_select_own" on public.trainers;
drop policy if exists "trainers_insert_own" on public.trainers;
drop policy if exists "trainers_update_own" on public.trainers;
drop policy if exists "trainers_delete_own" on public.trainers;

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trainers_set_updated_at on public.trainers;
create trigger trainers_set_updated_at
  before update on public.trainers
  for each row execute function public.set_updated_at();

create table if not exists public.pokedex_entries (
  trainer_id uuid references public.trainers(id) on delete cascade,
  pokemon_id integer not null,
  discovery_state text not null default 'undiscovered',
  primary key (trainer_id, pokemon_id)
);
alter table public.pokedex_entries enable row level security;

drop policy if exists "Trainers manage their own pokedex" on public.pokedex_entries;
create policy "Trainers manage their own pokedex"
  on public.pokedex_entries for all
  using (auth.uid() = trainer_id);
