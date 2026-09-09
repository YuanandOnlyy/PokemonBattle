-- Run this in the Supabase SQL editor for project tmlgvlstwsgmnkmwloty
-- Required by PokemonBattleArenaSwiftUI SupabaseService.

-- 1) Trainers save blob (one row per auth user)
create table if not exists public.trainers (
  id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create or replace function public.set_trainers_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trainers_set_updated_at on public.trainers;
create trigger trainers_set_updated_at
before update on public.trainers
for each row execute function public.set_trainers_updated_at();

alter table public.trainers enable row level security;

drop policy if exists "trainers_select_own" on public.trainers;
create policy "trainers_select_own"
  on public.trainers for select
  using (auth.uid() = id);

drop policy if exists "trainers_insert_own" on public.trainers;
create policy "trainers_insert_own"
  on public.trainers for insert
  with check (auth.uid() = id);

drop policy if exists "trainers_update_own" on public.trainers;
create policy "trainers_update_own"
  on public.trainers for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "trainers_delete_own" on public.trainers;
create policy "trainers_delete_own"
  on public.trainers for delete
  using (auth.uid() = id);

-- 2) Enable Anonymous sign-ins in the dashboard:
--    Authentication → Providers → Anonymous → Enable
-- Without this, SupabaseService.ensureSignedIn() cannot obtain a user id.
