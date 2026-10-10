-- Nur den unbesetzten fünften Platz umbenennen.
update public.fantasy_members
set name = 'Spielerin 5'
where slot = 4 and user_id is null and name = 'Hasan';
