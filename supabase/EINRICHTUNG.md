# Anmeldung ohne persönliche E-Mail – Einrichtung

Status: Anmeldung und einmalige Einladungen sind vorbereitet, noch nicht auf Supabase veröffentlicht. Die bestehende index.html bleibt die lokale Spielvorschau. Die komplette Live-Anbindung der Spielaktionen folgt separat. Anmeldung allein synchronisiert keine Picks oder Punkte.

1. 02-einladungen.sql nach der Grundstruktur im SQL Editor ausführen. Den ausgegebenen Admin-Einladungscode privat speichern. Ein erneutes Ausführen ersetzt die ungenutzte Admin-Einladung. Keine Ausgabe bedeutet: Admin bereits zugeordnet.
2. In Supabase eine Edge Function namens fantasy-auth erstellen und den Inhalt aus functions/fantasy-auth/index.ts einsetzen. Die Funktion muss ohne vorgeschaltete JWT-Pflicht erreichbar sein, da Login und Registrierung vor einer Sitzung erfolgen. Intern werden Einladung und Passwort geprüft. Die Server-Schlüssel kommen aus Supabases Standard-Umgebungsvariablen und gehören niemals in Browserdateien.
3. Funktion veröffentlichen. Die Standardvariablen SUPABASE_URL, SUPABASE_ANON_KEY und SUPABASE_SERVICE_ROLE_KEY müssen vorhanden sein. Wenn der Dienst meldet, dass Schlüssel fehlen, nicht als öffentliche Konfiguration eintragen.
4. anmeldung.html unter derselben Website wie die App bereitstellen. Für den ersten Admin #invite=CODE an deren URL anhängen. Registrierung selbst durchführen. Dieser Link ist ein Zugangsschlüssel und darf nicht öffentlich geteilt werden.
5. Im Admin-Bereich der Anmeldeseite persönliche Einladungen für unbesetzte Spielerplätze erzeugen. localhost-Links sind nur für lokale Tests. Für Signal die veröffentlichte HTTPS-Website verwenden.
6. Auf getrennten Sitzungen Registrierung, verbrauchten Link, falsche Passwörter, Login und fehlende Adminrechte prüfen. Anschließend die Live-Spielanbindung einrichten.

Einladungen gelten 7 Tage, ersetzen ältere offene Einladungen desselben Platzes und werden atomar verbraucht. Passwörter verwaltet Supabase Auth. Technische, nicht zustellbare Adressen werden aus Login-Namen abgeleitet; keine persönliche E-Mail nötig, kein Mailversand. Anmeldung ist auf 10 Versuche pro Login innerhalb von 15 Minuten begrenzt. Passwort-Wiederherstellung per Admin-Link ist noch nicht implementiert.

Lokale Syntaxprüfungen bestanden. SQL, Edge Function und Auth-Fluss sind noch nicht im echten Projekt geprüft. Diese Anleitung ist keine Bestätigung eines bereits aktiven Live-Betriebs.

## Schritt 5 – Live-Spielbetrieb

05-live-liga.sql im SQL Editor ausführen. index.html verwendet jetzt denselben Supabase-Login wie anmeldung.html und den gemeinsam gespeicherten Spielstand. Die bisherigen lokalen Test-Picks werden nicht hochgeladen. prototype-local.html bewahrt die lokale Testversion.

Serverfunktionen prüfen Rollen, den aktuellen Revisionsstand, Snake-Reihenfolge, Team-Limits und vollständige Kader mittels Max-Flow. Nur fünf registrierte Spieler können ausgelost werden. Verdeckte Lose werden im Snapshot maskiert und sind per RLS nicht direkt lesbar. Realtime meldet Änderungen an fantasy_league; danach lädt die App einen konsistenten Snapshot. Ein zusätzlicher Abruf alle 15 Sekunden und bei Rückkehr zum Tab fängt verpasste Meldungen ab. Dialoge bleiben beim Aktualisieren erhalten.

Getestet mit einer lokalen PostgreSQL-Umgebung (PGlite): SQL-Anlage, RLS, Admin-Prüfung, Revisionskonflikt, Reihenfolge, 20-Pick-Draft, Kategorie/Quellen, Votes, einmalige Freigabe und Folge >=2. Auth-Kennung und Kryptofunktionen wurden dort als Testumgebung nachgebildet; echte Supabase-Authentifizierung und WebSocket-Übertragung müssen nach Installation mit zwei getrennten Browser-Sitzungen geprüft werden.

Noch nicht veröffentlicht auf GitHub Pages. Keine Freunde mit localhost-Links einladen.
