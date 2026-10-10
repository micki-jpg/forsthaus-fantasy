begin;
alter table public.fantasy_invites add column if not exists purpose text not null default 'invite' check(purpose in ('invite','reset'));
create or replace function public.fantasy_manage_link(p_slot integer,p_action text)
returns text language plpgsql security definer set search_path='' as $$
declare m public.fantasy_members; token text;
begin
 if not exists(select 1 from public.fantasy_members where user_id=auth.uid() and role='admin') then raise exception 'Nur Admins'; end if;
 select * into m from public.fantasy_members where slot=p_slot for update;
 if not found or p_slot not between 0 and 4 then raise exception 'Ungültiger Spielerplatz'; end if;
 if p_action not in ('invite','reset','revoke') then raise exception 'Ungültige Aktion'; end if;
 if p_action='invite' and m.user_id is not null then raise exception 'Bereits registriert. Reset verwenden.'; end if;
 if p_action='reset' and m.user_id is null then raise exception 'Noch nicht registriert.'; end if;
 update public.fantasy_invites set expires_at=now() where slot=p_slot and used_at is null;
 if p_action='revoke' then return null; end if;
 token=encode(extensions.gen_random_bytes(32),'hex');
 insert into public.fantasy_invites(token_hash,slot,purpose,expires_at)
 values(encode(extensions.digest(token,'sha256'),'hex'),p_slot,p_action,now()+case when p_action='reset' then interval '1 day' else interval '7 days' end);
 return token;
end $$;
create or replace function public.fantasy_link_status()
returns table(slot integer,name text,registered boolean,login_name text,link_type text,expires_at timestamptz)
language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.fantasy_members where user_id=auth.uid() and role='admin') then raise exception 'Nur Admins'; end if;
 return query select m.slot,m.name,m.user_id is not null,m.login_name,i.purpose,i.expires_at
 from public.fantasy_members m left join lateral (
 select f.purpose,f.expires_at from public.fantasy_invites f
 where f.slot=m.slot and f.used_at is null and f.expires_at>now() order by f.expires_at desc limit 1
 ) i on true where m.role='player' order by m.slot;
end $$;
create or replace function public.fantasy_consume_reset(p_hash text)
returns uuid language plpgsql security definer set search_path='' as $$
declare inv public.fantasy_invites; uid uuid;
begin
 select * into inv from public.fantasy_invites where token_hash=p_hash for update;
 if not found or inv.purpose<>'reset' or inv.used_at is not null or inv.expires_at<=now() then raise exception 'Reset-Link ungültig'; end if;
 select user_id into uid from public.fantasy_members where slot=inv.slot and role='player' for update;
 if uid is null then raise exception 'Konto nicht registriert'; end if;
 update public.fantasy_invites set used_at=now() where token_hash=p_hash;
 return uid;
end $$;
revoke all on function public.fantasy_manage_link(integer,text),public.fantasy_link_status() from public,anon;
grant execute on function public.fantasy_manage_link(integer,text),public.fantasy_link_status() to authenticated;
revoke all on function public.fantasy_consume_reset(text) from public,anon,authenticated;
grant execute on function public.fantasy_consume_reset(text) to service_role;
-- Der alte Einladungsweg bleibt kompatibel und nutzt dieselbe Prüfung.
create or replace function public.fantasy_make_invite(p_slot integer)
returns text language sql security invoker set search_path='' as $$ select public.fantasy_manage_link(p_slot,'invite'); $$;
commit;
select 'Einladungsverwaltung bereit' as ergebnis;
