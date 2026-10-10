-- Schritt 2: Einladungen ohne persönliche E-Mail-Adressen.
-- Nach 01-grundstruktur.sql ausführen. Keine Spielstände werden gelöscht.
begin;
alter table public.fantasy_members add column if not exists login_name text;
create unique index if not exists fantasy_login_unique on public.fantasy_members(lower(login_name)) where login_name is not null;
create table if not exists public.fantasy_invites (
 token_hash text primary key,
 slot integer not null references public.fantasy_members(slot),
 expires_at timestamptz not null default now() + interval '7 days',
 used_at timestamptz
);
alter table public.fantasy_invites enable row level security;
revoke all on public.fantasy_invites from public,anon,authenticated;
grant select,insert,update,delete on public.fantasy_invites to service_role;
grant select,update on public.fantasy_members to service_role;
create or replace function public.fantasy_redeem_invite(p_hash text,p_user uuid,p_login text,p_name text)
returns integer language plpgsql security definer set search_path = '' as $$
declare inv public.fantasy_invites; member public.fantasy_members;
begin
 select * into inv from public.fantasy_invites where token_hash=p_hash for update;
 if not found or inv.used_at is not null or inv.expires_at <= now() then raise exception 'Einladung ungültig oder abgelaufen'; end if;
 select * into member from public.fantasy_members where slot=inv.slot for update;
 if member.user_id is not null then raise exception 'Liga-Platz bereits belegt'; end if;
 if p_login !~ '^[a-z0-9_]{3,24}$' or length(trim(p_name)) not between 1 and 32 then raise exception 'Name ungültig'; end if;
 update public.fantasy_members set user_id=p_user,login_name=p_login,name=trim(p_name) where slot=inv.slot;
 update public.fantasy_invites set used_at=now() where token_hash=p_hash;
 return inv.slot;
end $$;
revoke all on function public.fantasy_redeem_invite(text,uuid,text,text) from public,anon,authenticated;
grant execute on function public.fantasy_redeem_invite(text,uuid,text,text) to service_role;
create or replace function public.fantasy_make_invite(p_slot integer)
returns text language plpgsql security definer set search_path = '' as $$
declare token text;
begin
 if not exists(select 1 from public.fantasy_members where user_id=auth.uid() and role='admin') then raise exception 'Nur Admins'; end if;
 perform 1 from public.fantasy_members where slot=p_slot and user_id is null for update;
 if not found or p_slot not between 0 and 4 then raise exception 'Platz bereits belegt oder ungültig'; end if;
 update public.fantasy_invites set expires_at=now() where slot=p_slot and used_at is null;
 token=encode(extensions.gen_random_bytes(32),'hex');
 insert into public.fantasy_invites(token_hash,slot) values(encode(extensions.digest(token,'sha256'),'hex'),p_slot);
 return token;
end $$;
revoke all on function public.fantasy_make_invite(integer) from public,anon;
grant execute on function public.fantasy_make_invite(integer) to authenticated;
-- Begrenzung der Anmeldeversuche pro Login-Name.
create table if not exists public.fantasy_login_limits (
 key text primary key, started_at timestamptz not null, attempts integer not null
);
alter table public.fantasy_login_limits enable row level security;
revoke all on public.fantasy_login_limits from public,anon,authenticated;
create or replace function public.fantasy_auth_attempt(p_key text)
returns boolean language plpgsql security definer set search_path='' as $$
declare count_now integer;
begin
 insert into public.fantasy_login_limits(key,started_at,attempts) values(p_key,now(),1)
 on conflict(key) do update set
 attempts=case when fantasy_login_limits.started_at < now()-interval '15 minutes' then 1 else fantasy_login_limits.attempts+1 end,
 started_at=case when fantasy_login_limits.started_at < now()-interval '15 minutes' then now() else fantasy_login_limits.started_at end
 returning attempts into count_now;
 return count_now<=10;
end $$;
revoke all on function public.fantasy_auth_attempt(text) from public,anon,authenticated;
grant execute on function public.fantasy_auth_attempt(text) to service_role;

commit;
-- Dieser Link schaltet den ersten Admin frei. Wie ein Passwort behandeln.
-- Wiederholtes Ausführen erzeugt KEINEN zweiten Admin.
do $$ begin
 if exists(select 1 from public.fantasy_members where slot=5 and user_id is null) then
  update public.fantasy_invites set expires_at=now() where slot=5 and used_at is null;
 end if;
end $$;
with token as (select encode(extensions.gen_random_bytes(32),'hex') as value),
created as (
 insert into public.fantasy_invites(token_hash,slot)
 select encode(extensions.digest(value,'sha256'),'hex'),5 from token
 where exists(select 1 from public.fantasy_members where slot=5 and user_id is null)
 returning token_hash
)
select 'Admin-Einladung: '||value as admin_einladung from token where exists(select 1 from created);
