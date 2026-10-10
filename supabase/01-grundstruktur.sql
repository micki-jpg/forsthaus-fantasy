-- Forsthaus Fantasy: Schritt 1. Nur Struktur, keine Test-Picks importieren.
-- Im Supabase SQL Editor als Projekt-Administrator ausführen.
begin;
create schema if not exists fantasy_private;
revoke all on schema fantasy_private from public;
grant usage on schema fantasy_private to authenticated;

create table if not exists public.fantasy_league (
 id integer primary key check (id = 1),
 name text not null,
 draft_open boolean not null default false,
 start_episode integer not null default 2 check (start_episode = 2)
);
create table if not exists public.fantasy_members (
 slot integer primary key check (slot between 0 and 5),
 user_id uuid unique references auth.users(id),
 name text not null check (length(trim(name)) between 1 and 32),
 role text not null check (role in ('player','admin')),
 avatar text,
 onboarding_complete boolean not null default false,
 check ((slot between 0 and 4 and role = 'player') or (slot = 5 and role = 'admin'))
);
create table if not exists public.fantasy_teams (
 id integer primary key check (id between 0 and 10), name text not null
);
create table if not exists public.fantasy_lottery (
 card integer primary key check (card between 0 and 4),
 rank integer not null unique check (rank between 0 and 4),
 player_slot integer not null unique references public.fantasy_members(slot) check (player_slot between 0 and 4),
 revealed boolean not null default false
);
create table if not exists public.fantasy_picks (
 pick_number integer primary key check (pick_number between 1 and 20),
 player_slot integer not null references public.fantasy_members(slot) check (player_slot between 0 and 4),
 team_id integer not null references public.fantasy_teams(id),
 created_at timestamptz not null default now(),
 unique (player_slot, team_id)
);
create table if not exists public.fantasy_proposals (
 id uuid primary key default gen_random_uuid(),
 team_id integer not null references public.fantasy_teams(id),
 episode integer not null check (episode >= 2),
 category integer not null check (category between 0 and 6),
 note text not null check (length(trim(note)) between 1 and 200),
 source_url text,
 status text not null default 'pending' check (status in ('pending','accepted','rejected')),
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create unique index if not exists fantasy_proposal_active_unique
 on public.fantasy_proposals(team_id,episode,category) where status <> 'rejected';
create table if not exists public.fantasy_votes (
 proposal_id uuid not null references public.fantasy_proposals(id),
 player_slot integer not null references public.fantasy_members(slot) check (player_slot between 0 and 4),
 value integer not null check (value in (-1,1)),
 primary key(proposal_id,player_slot)
);
create table if not exists public.fantasy_events (
 id uuid primary key default gen_random_uuid(),
 proposal_id uuid unique references public.fantasy_proposals(id),
 team_id integer not null references public.fantasy_teams(id),
 episode integer not null check (episode >= 2),
 category integer not null check (category between 0 and 6),
 points integer not null,
 note text not null default '',
 source_url text,
 created_at timestamptz not null default now()
);
-- Nur bereits zugeordnete Konten dürfen die Liga lesen.
create or replace function fantasy_private.is_member()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.fantasy_members where user_id = auth.uid()); $$;
revoke all on function fantasy_private.is_member() from public, anon;
grant execute on function fantasy_private.is_member() to authenticated;
-- Verdeckte Lose bleiben bis zum Aufdecken verborgen.
-- Schreibzugriff folgt in Schritt 2 über geprüfte Server-Funktionen.
do $$
declare t text;
begin
 foreach t in array array['fantasy_league','fantasy_members','fantasy_teams','fantasy_lottery','fantasy_picks','fantasy_proposals','fantasy_votes','fantasy_events'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on table public.%I from anon, authenticated',t);
  execute format('grant select on table public.%I to authenticated',t);
  execute format('drop policy if exists league_member_read on public.%I',t);
  if t = 'fantasy_lottery' then
   execute format('create policy league_member_read on public.%I for select to authenticated using ((select fantasy_private.is_member()) and revealed)',t);
  else
   execute format('create policy league_member_read on public.%I for select to authenticated using ((select fantasy_private.is_member()))',t);
  end if;
 end loop;
end $$;
insert into public.fantasy_league(id,name) values(1,'Forsthaus Fantasy League') on conflict do nothing;
insert into public.fantasy_members(slot,name,role) values
 (0,'Spielerin 1','player'),(1,'Spielerin 2','player'),(2,'Spielerin 3','player'),
 (3,'Spielerin 4','player'),(4,'Spielerin 5','player'),(5,'Admin','admin') on conflict do nothing;
insert into public.fantasy_teams(id,name) values
 (0,'Beverly & Elsa'),(1,'Susi & Norbert'),(2,'Simone & Alex'),
 (3,'Philisha Conditioner & Shira'),(4,'Phillip & Rafael'),(5,'Butti & Sophie'),
 (6,'Julia & Ebru'),(7,'Peter & Alisa'),(8,'Lisa & Geri'),(9,'Krappi & Vanessa'),(10,'Julian & Tom')
 on conflict do nothing;
commit;
select 'Grundstruktur bereit. 5 Spielerplätze + 1 Admin, 11 Teams. Noch keine Konten zugeordnet.' as ergebnis;
