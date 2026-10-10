-- Schritt 5: gemeinsame Liga, geprüfte Schreibaktionen, Realtime.
begin;
alter table public.fantasy_league add column if not exists revision integer not null default 0;
alter table public.fantasy_league add column if not exists lottery_started_at timestamptz;
-- Keine Schreibrechte für Browser. Alle Änderungen gehen durch fantasy_action.
create or replace function fantasy_private.can_complete(p_picks jsonb)
returns boolean language plpgsql set search_path='' as $$
declare cap integer[][]:=array_fill(0,array[18,18]); own boolean[][]:=array_fill(false,array[5,11]); pc integer[]:=array_fill(0,array[5]); tc integer[]:=array_fill(0,array[11]); p jsonb; i integer;j integer;u integer;v integer;head integer; flow integer:=0;need integer:=0; parent integer[];queue integer[];
begin
 for p in select value from jsonb_array_elements(p_picks) loop
  i=(p->>'playerId')::integer+1;j=(p->>'teamId')::integer+1;
  if i not between 1 and 5 or j not between 1 and 11 or own[i][j] then return false;end if;
  own[i][j]=true;pc[i]=pc[i]+1;tc[j]=tc[j]+1;
 end loop;
 for i in 1..5 loop
  if pc[i]>4 then return false;end if;
  cap[1][i+1]=4-pc[i];need=need+4-pc[i];
  for j in 1..11 loop if not own[i][j] then cap[i+1][j+6]=1;end if;end loop;
 end loop;
 for j in 1..11 loop if tc[j]>2 then return false;end if;cap[j+6][18]=2-tc[j];end loop;
 loop
  parent=array_fill(0,array[18]);parent[1]=-1;queue=array[1];head=1;
  while head<=coalesce(array_length(queue,1),0) and parent[18]=0 loop
   u=queue[head];head=head+1;
   for v in 2..18 loop if parent[v]=0 and cap[u][v]>0 then parent[v]=u;queue=array_append(queue,v);end if;end loop;
  end loop;
  exit when parent[18]=0;
  v=18;while v<>1 loop u=parent[v];cap[u][v]=cap[u][v]-1;cap[v][u]=cap[v][u]+1;v=u;end loop;
  flow=flow+1;
 end loop;
 return flow=need;
end $$;
revoke all on function fantasy_private.can_complete(jsonb) from public,anon,authenticated;

create or replace function public.fantasy_snapshot()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare l public.fantasy_league; me public.fantasy_members; result jsonb; ord integer[]:=array_fill(-1,array[5]); ranks integer[]:=array_fill(-1,array[5]); used_players integer[]:='{}';used_ranks integer[]:='{}';r record;i integer;j integer;shown integer[]:='{}';
begin
 select * into me from public.fantasy_members where user_id=auth.uid();if not found then raise exception 'Bitte mit Liga-Zugang anmelden';end if;
 select * into l from public.fantasy_league where id=1;
 -- Nur aufgedeckte Zuordnungen ausliefern. Platzhalter verraten keine verdeckten Lose.
 for r in select * from public.fantasy_lottery where revealed loop
  ord[r.rank+1]=r.player_slot;ranks[r.card+1]=r.rank;used_players=array_append(used_players,r.player_slot);used_ranks=array_append(used_ranks,r.rank);shown=array_append(shown,r.card);
 end loop;
 for i in 1..5 loop
  if ord[i]=-1 then for j in 0..4 loop if not j=any(used_players) then ord[i]=j;used_players=array_append(used_players,j);exit;end if;end loop;end if;
  if ranks[i]=-1 then for j in 0..4 loop if not j=any(used_ranks) then ranks[i]=j;used_ranks=array_append(used_ranks,j);exit;end if;end loop;end if;
 end loop;
 select jsonb_build_object('version',2,'revision',l.revision,'adminPin','','startEpisode',2,'draftOpen',l.draft_open,
 'players',(select jsonb_agg(jsonb_build_object('id',slot,'name',name,'pin','','avatar',avatar,'onboardingComplete',onboarding_complete,'onboardingVersion',case when onboarding_complete then 2 else 0 end) order by slot) from public.fantasy_members where role='player'),
 'teams',(select jsonb_agg(jsonb_build_object('id',id,'name',name) order by id) from public.fantasy_teams),
 'order',case when l.lottery_started_at is null then '[]'::jsonb else to_jsonb(ord) end,
 'lottery',case when l.lottery_started_at is null then null else jsonb_build_object('cardRanks',ranks,'revealed',shown,'startedAt',l.lottery_started_at) end,
 'picks',coalesce((select jsonb_agg(jsonb_build_object('playerId',player_slot,'teamId',team_id,'at',created_at) order by pick_number) from public.fantasy_picks),'[]'),
 'events',coalesce((select jsonb_agg(jsonb_build_object('id',id,'teamId',team_id,'episode',episode,'category',category,'points',points,'note',note,'proposalId',proposal_id,'source',case when source_url is null then null else jsonb_build_object('url',source_url) end,'at',created_at) order by created_at,id) from public.fantasy_events),'[]'),
 'proposals',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'teamId',p.team_id,'episode',p.episode,'category',p.category,'note',p.note,'status',p.status,'source',case when p.source_url is null then null else jsonb_build_object('url',p.source_url) end,'votes',coalesce((select jsonb_object_agg(v.player_slot::text,v.value) from public.fantasy_votes v where v.proposal_id=p.id),'{}'::jsonb)) order by p.created_at,p.id) from public.fantasy_proposals p),'[]'),
 'account',jsonb_build_object('slot',me.slot,'role',me.role,'name',me.name)) into result;
 return result;
end $$;
revoke all on function public.fantasy_snapshot() from public,anon;
grant execute on function public.fantasy_snapshot() to authenticated;

create or replace function public.fantasy_action(p_revision integer,p_action text,p_data jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare l public.fantasy_league; me public.fantasy_members; n integer;cp integer;tid integer;ep integer;cat integer;pts integer;pid uuid; r record; prop public.fantasy_proposals; plist jsonb; player_order integer[];card_order integer[];avatar_value text; note_value text;source_value text;
begin
 select * into me from public.fantasy_members where user_id=auth.uid();if not found then raise exception 'Bitte anmelden';end if;
 select * into l from public.fantasy_league where id=1 for update;
 if p_revision<>l.revision then raise exception 'Die Liga wurde inzwischen aktualisiert. Bitte erneut versuchen.';end if;
 if p_action not in ('profile','pick','proposal','vote') and me.role<>'admin' then raise exception 'Nur Admins';end if;
 if p_action='profile' then
  if me.role<>'player' then raise exception 'Nur Spielerprofile';end if;
  avatar_value=p_data->>'avatar';
  if avatar_value is not null and avatar_value not in ('specki','natascha','jazz-gitti','carmen','roland','dominic','hansi','julia','maxa-million','selina','manuela','christian','ferry','marvin','otto-konrad') then raise exception 'Ungültiges Profilbild';end if;
  update public.fantasy_members set name=trim(p_data->>'name'),avatar=avatar_value,onboarding_complete=coalesce((p_data->>'onboardingComplete')::boolean,onboarding_complete) where slot=me.slot;
 elsif p_action='lottery_start' then
  if l.lottery_started_at is not null then raise exception 'Bereits ausgelost';end if;
  if exists(select 1 from public.fantasy_members where role='player' and user_id is null) then raise exception 'Zuerst alle fünf Spielerplätze registrieren';end if;
  select array_agg(i order by encode(extensions.gen_random_bytes(16),'hex')) into player_order from generate_series(0,4) i;
  select array_agg(i order by encode(extensions.gen_random_bytes(16),'hex')) into card_order from generate_series(0,4) i;
  for n in 1..5 loop insert into public.fantasy_lottery(card,rank,player_slot) values(n-1,card_order[n],player_order[card_order[n]+1]);end loop;
  update public.fantasy_league set lottery_started_at=now() where id=1;
 elsif p_action='lottery_reveal' then
  update public.fantasy_lottery set revealed=true where card=(p_data->>'card')::integer and not revealed;
  if not found then raise exception 'Los nicht verfügbar';end if;
 elsif p_action='draft_toggle' then
  if (select count(*) from public.fantasy_lottery where revealed)<>5 then raise exception 'Zuerst alle Lose aufdecken';end if;
  if (select count(*) from public.fantasy_picks)=20 then raise exception 'Draft abgeschlossen';end if;
  update public.fantasy_league set draft_open=not draft_open where id=1;
 elsif p_action='pick' then
  select count(*) into n from public.fantasy_picks;
  if not l.draft_open or n>=20 then raise exception 'Draft nicht geöffnet';end if;
  select player_slot into cp from public.fantasy_lottery where rank=case when (n/5)%2=0 then n%5 else 4-n%5 end;
  if cp is null or (me.role<>'admin' and me.slot<>cp) then raise exception 'Du bist nicht am Pick';end if;
  tid=(p_data->>'teamId')::integer;
  select coalesce(jsonb_agg(jsonb_build_object('playerId',player_slot,'teamId',team_id)),'[]'::jsonb) into plist from public.fantasy_picks;
  if not fantasy_private.can_complete(plist||jsonb_build_array(jsonb_build_object('playerId',cp,'teamId',tid))) then raise exception 'Team nicht verfügbar oder für vollständige Kader reserviert';end if;
  insert into public.fantasy_picks(pick_number,player_slot,team_id) values(n+1,cp,tid);
  if n=19 then update public.fantasy_league set draft_open=false where id=1;end if;
 elsif p_action='undo' then
  delete from public.fantasy_picks where pick_number=(select max(pick_number) from public.fantasy_picks);
  if not found then raise exception 'Keine Picks';end if;
  update public.fantasy_league set draft_open=true where id=1;
 elsif p_action in ('proposal','event') then
  tid=(p_data->>'teamId')::integer;ep=(p_data->>'episode')::integer;cat=(p_data->>'category')::integer;
  if ep<2 or cat not between 0 and 6 then raise exception 'Folge oder Kategorie ungültig';end if;
  note_value=coalesce(p_data->>'note','');source_value=p_data->>'sourceUrl';
  if source_value is not null and source_value !~ '^https://www[.]joyn[.]at/' then raise exception 'Ungültige News-Quelle';end if;
  if p_action='proposal' then
   insert into public.fantasy_proposals(team_id,episode,category,note,source_url,created_by) values(tid,ep,cat,note_value,source_value,auth.uid()) returning id into pid;
   if me.role='player' then insert into public.fantasy_votes values(pid,me.slot,1);end if;
  else
   pts=(p_data->>'points')::integer;
   if pts is null or abs(pts)>1000 then raise exception 'Ungültige Punkte';end if;
   insert into public.fantasy_events(team_id,episode,category,points,note,source_url) values(tid,ep,cat,pts,note_value,source_value);
  end if;
 elsif p_action='vote' then
  if me.role<>'player' then raise exception 'Nur Spieler stimmen ab';end if;
  pid=(p_data->>'id')::uuid;
  if not exists(select 1 from public.fantasy_proposals where id=pid and status='pending') then raise exception 'Vorschlag abgeschlossen';end if;
  insert into public.fantasy_votes(proposal_id,player_slot,value) values(pid,me.slot,(p_data->>'value')::integer) on conflict(proposal_id,player_slot) do update set value=excluded.value;
 elsif p_action='moderate' then
  pid=(p_data->>'id')::uuid;select * into prop from public.fantasy_proposals where id=pid for update;
  if not found or prop.status<>'pending' then raise exception 'Vorschlag abgeschlossen';end if;
  if (p_data->>'accept')::boolean then
   pts=(array[15,10,5,5,5,-3,-15])[prop.category+1];
   insert into public.fantasy_events(proposal_id,team_id,episode,category,points,note,source_url) values(pid,prop.team_id,prop.episode,prop.category,pts,prop.note,prop.source_url);
   update public.fantasy_proposals set status='accepted' where id=pid;
  else update public.fantasy_proposals set status='rejected' where id=pid;end if;
 elsif p_action='event_delete' then
  delete from public.fantasy_events where id=(p_data->>'id')::uuid returning proposal_id into pid;
  if not found then raise exception 'Ereignis bereits entfernt';end if;
  if pid is not null then update public.fantasy_proposals set status='pending' where id=pid;end if;
 else raise exception 'Unbekannte Aktion';end if;
 update public.fantasy_league set revision=revision+1 where id=1;
 return public.fantasy_snapshot();
end $$;
revoke all on function public.fantasy_action(integer,text,jsonb) from public,anon;
grant execute on function public.fantasy_action(integer,text,jsonb) to authenticated;
-- Registrierung und Profiländerungen senden ebenfalls ein Live-Signal.
create or replace function fantasy_private.member_changed()
returns trigger language plpgsql security definer set search_path='' as $$
begin update public.fantasy_league set revision=revision+1 where id=1;return new;end $$;
revoke all on function fantasy_private.member_changed() from public,anon,authenticated;
drop trigger if exists fantasy_member_live on public.fantasy_members;
create trigger fantasy_member_live after update on public.fantasy_members
for each row when (old is distinct from new) execute function fantasy_private.member_changed();
-- Revision ist das einzige Live-Signal. Die App lädt danach einen konsistenten Snapshot.
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='fantasy_league') then
  alter publication supabase_realtime add table public.fantasy_league;
 end if;
end $$;
commit;
select 'Live-Funktionen bereit. Test-Picks wurden nicht importiert.' as ergebnis;
