# Forsthaus Fantasy 2026 – Handy-Version mit News

Die Vorschau enthält die neue Überschrift „Die Alm ruft. Jawoi Bebe“, eine an das Holzschild der Show angelehnte Farbgebung mit Rot und Creme, sachliche Bedienungstexte und einen News-Reiter. Die bisherige GitHub-Seite wurde noch nicht geändert.

In der Liga-Übersicht drehen sich die elf Team-Karten beim Darüberfahren mit der Maus. Am Handy oder mit Tastatur öffnet „Team-Info“ die Rückseite; „Zurück“ oder Escape zeigt wieder das Foto. Die Kurzprofile sind aus der offiziellen Joyn-Cast-Vorstellung zusammengefasst und haben jeweils einen Quellenlink. Verdeckte Seiten sind für Tastatur und Screenreader deaktiviert. Bei reduzierter Bewegung wechselt die Seite ohne Dreh-Animation.

Das Dashboard zeigt die fünf Liga-Mitglieder mit ihren gewählten Profilbildern. Ohne Auswahl erscheint ein Fragezeichen im Holz-Rot-Creme-Stil.

## Eigene Profilbilder

Nach der Anmeldung als Liga-Mitglied oben das Konto-Symbol öffnen oder unter Kader „Profilbild wählen“ antippen. Eines der 15 Bilder wählen und mit „Profilbild speichern“ übernehmen. Schließen ohne Speichern verwirft die Auswahl. „Initiale verwenden“ stellt die bisherige Darstellung wieder her. Mehrere Mitglieder dürfen dasselbe Motiv verwenden.

Die Fan-Auswahl stammt aus den österreichischen Staffeln 2024 und 2025: Specki, Natascha, Jazz Gitti, Carmen, Roland, Dominic, Hansi, Julia, Maxa Million, Selina, Manuela, Christian, Ferry, Marvin und Otto Konrad. Welche Personen besonders lustig sind, ist eine subjektive Auswahl. Namen und Staffelzugehörigkeit sind über die offiziellen Joyn-Cast-Informationen geprüft. Die Fotos stammen aus offiziellen ATV-/Joyn-Cast-Bildern von Bernhard Eder Photography; die App zeigt jeweils einen Gesichtsausschnitt, ohne die Originalfotos zu verändern.

Das gewählte Motiv erscheint auf dem Dashboard, oben im Konto und in der Rangliste. Änderungen betreffen nur das angemeldete Mitglied. Das Profilbild wird lokal gespeichert und bei eingerichteter Cloud mit derselben Saison geteilt. Bestehende Saison-Dateien ohne Profilbild bleiben gültig. Der gesamte Ordner `assets/avatars/` muss zusammen mit der App veröffentlicht werden; er ist im ZIP enthalten. Die Bilder werden nicht zur Anmeldung benötigt und geben keinen Zugriff auf andere Konten.

## Show-News

Der Reiter liest einen automatisch erzeugten News-Datenstand mit kurzen Originalüberschriften, Veröffentlichungsdatum und Link zum Artikel. Quellen sind ausschließlich die österreichische Joyn-Show-Seite und die offizielle Cast-Seite der Staffel 2026. Artikel aus der deutschen Version und explizite Rückblicke auf ältere Staffeljahre werden nicht aufgenommen. Die Liste ist nach Veröffentlichungsdatum sortiert; das Datum des Quellenabrufs wird separat angezeigt.

„Show & Umfeld“ umfasst auch Meldungen zur Premiere mit früheren Teilnehmern. „Aktuelle Teams“ zeigt nur sicher zuordenbare Meldungen zu den elf Teams. Ein mehrdeutiger einzelner Vorname reicht nicht für eine Team-Zuordnung.

Überschriften und Bilder sind zuerst ausgeblendet. Einzelne Meldungen oder alle Überschriften können eingeblendet werden. Dadurch lassen sich Spoiler vor eurem zeitversetzten Schauen vermeiden. Es gibt keine erfundenen Meldungen oder generierten Artikelzusammenfassungen.

Die Vorschau enthält 15 direkt von den Originalartikeln geprüfte Meldungen. Für die automatische Aktualisierung auf GitHub gehören diese Dateien gemeinsam ins Repository:

- `index.html`: die App mit einem eingebetteten ersten News-Datenstand.
- `news.json`: der News-Datenstand, den die App lädt.
- `tools/update_news.py`: liest die offiziellen Quellen und prüft die Artikel-Metadaten.
- `.github/workflows/pages-news.yml`: aktualisiert und veröffentlicht die App mit GitHub Pages.

Alle Dateien mit den richtigen Ordnern sind im ZIP-Paket enthalten. Nur `index.html` hochzuladen ergibt eine Vorschau mit gespeicherten Meldungen, aber noch keinen automatischen News-Abruf.

## Automatische News auf GitHub aktivieren

1. Das ZIP entpacken und seine Dateien unter Beibehaltung der Ordner ins Repository auf `main` übernehmen.
2. Unter **Settings → Pages → Build and deployment → Source** die Quelle **GitHub Actions** auswählen.
3. Unter **Actions → App und Show-News aktualisieren → Run workflow** den ersten Lauf starten bzw. den durch den Upload ausgelösten Lauf prüfen.

Der Workflow läuft anschließend ungefähr stündlich, zur Minute 17. GitHub kann geplante Läufe verzögern und deaktiviert sie bei öffentlichen Repositories nach 60 Tagen ohne Repository-Aktivität. Ein ausgeschalteter Workflow lässt sich unter Actions wieder aktivieren. Es werden keine zusätzlichen API-Schlüssel für die News benötigt.

Bei einem fehlgeschlagenen Quellenabruf wird die bestehende Website nicht durch einen leeren oder älteren News-Datenstand ersetzt. Bei einem Ladefehler auf dem Handy bleibt der gespeicherte Stand sichtbar, mit Datum und Fehlermeldung. Ein älterer Server-Datenstand überschreibt keinen neueren lokalen Stand.

Die GitHub-Automatik ist vorbereitet; der Quellenabruf ist lokal geprüft. Der Workflow wurde noch nicht in deinem Repository ausgeführt oder aktiviert. Die lokale Vorschau lädt die aktuell erstellte `news.json`; der stündliche Quellenabruf beginnt erst nach der GitHub-Einrichtung.

## Festgelegte Regeln

- 11 offiziell bestätigte österreichische Forsthaus-Duos, Staffel 5 (2026).
- 5 Liga-Mitglieder, darunter Hasan; die übrigen Namen sind editierbare Platzhalter.
- 4 verschiedene Duos pro Person, 20 Picks insgesamt.
- Jedes Duo höchstens in 2 Kadern. Beide Besitzer erhalten die vollen Team-Punkte.
- 4 Snake-Runden. Die Startreihenfolge wird vor dem Öffnen über fünf verdeckte Lose ausgelost und gespeichert.
- Ein Pick wird gesperrt, wenn danach nicht mehr alle fünf vollständige Kader bekommen könnten. Die Karte zeigt dann „Für weitere Picks reserviert“.
- Der Draft startet geschlossen. Der Admin öffnet ihn nach eurem Schauen am Sonntag, 11. Oktober 2026.
- Die Wertung beginnt ab Folge 2. Folge 1 lässt sich nicht als Punkteereignis speichern.
- Kein Import der alten Test-Picks oder Test-Punkte.

## Vorschau ausprobieren

Die HTML-Datei im Browser öffnen oder die lokale Vorschau in Codex ansehen. Ohne Cloud-Konfiguration speichert sie nur auf dem jeweiligen Gerät.

Unter „Admin“ anmelden. Die anfänglichen Test-Zugänge sind:

| Mitglied | PIN |
| --- | --- |
| Spielerin 1 | 1111 |
| Spielerin 2 | 2222 |
| Spielerin 3 | 3333 |
| Spielerin 4 | 4444 |
| Hasan | 5555 |

Anfängliches Admin-Passwort: `admin123`. Namen und Zugänge bitte vor dem echten Start in der Verwaltung ändern.

## Vor dem gemeinsamen Start

1. Die vier übrigen Namen ergänzen und die Zugänge festlegen.
2. Das vollständige App-Paket im GitHub-Repository übernehmen und die GitHub-Pages-Veröffentlichung abwarten.
3. Für die neue Saison einen eigenen JSONBin anlegen. Bin-ID und Schlüssel im Admin-Bereich eintragen. „Diese Saison in Cloud schreiben“ initialisiert den konfigurierten Bin und ersetzt dessen Inhalt.
4. Auf jedem weiteren Gerät denselben Bin und Schlüssel konfigurieren und „Cloud laden“ wählen. Nicht auf diesen Geräten die Saison neu initialisieren.
5. Am Sonntag nach Folge 1 im Draft „Auslosung ansehen“ wählen. Als Admin „Auslosung starten“ bestätigen und die fünf Lose nacheinander aufdecken. Anschließend in der Verwaltung „Draft öffnen“ wählen. Danach wählen alle in der gespeicherten Reihenfolge.

## Auslosungs-Minispiel

Unter **Draft → Auslosung ansehen → Demo ausprobieren** lässt sich die Ziehung mit fünf Beispielnamen testen. Die Demo verändert keine Liga-Daten und wird nicht gespeichert.

Die echte Auslosung legt alle fünf Startplätze zufällig fest, bevor das erste Los aufgedeckt wird. Jedes Los zeigt beim Antippen einen Namen und dessen Startplatz. Der Admin kann die Lose in beliebiger Reihenfolge aufdecken; die Auswahl beeinflusst das Ergebnis nicht. Ein Neuladen setzt die gespeicherte Ziehung fort und lost nicht erneut. Bei eingerichteter Cloud wird auch der Ziehungsstand geteilt.

Nur das neu aufgedeckte Los bekommt eine Dreh-Animation. Bereits aufgedeckte Lose behalten ihre Darstellung auch bei weiteren Aufdeck-Aktionen und den anschließenden Speichervorgängen.

Erst nach allen fünf Losen kann der Admin den Draft separat öffnen. Runden 1 und 3 folgen der ausgelosten Reihenfolge; Runden 2 und 4 laufen rückwärts. Eine vorhandene Startreihenfolge aus dieser App-Version bleibt gültig.

Die App lädt konfigurierte Cloud-Daten beim Seitenstart. Außerhalb der Verwaltung und offener Dialoge prüft sie Änderungen alle 15 Sekunden. Auf größeren Bildschirmen lässt sich über den Cloud-Status zusätzlich aktualisieren; auf dem Handy über den Admin-Bereich.

## Grenzen der ersten Version

Die JSONBin-Anbindung wurde vorbereitet, aber nicht mit einem echten Liga-Bin getestet. Browser-PINs und JSONBin-Schlüssel sind wie in der bisherigen App keine serverseitige Zugriffskontrolle. Der öffentlich im bisherigen GitHub-Code enthaltene Master-Key sollte vor dem echten Start ersetzt werden; diese neue Datei enthält ihn nicht.

Vor dem Schreiben prüft die App, ob sich die Cloud-Daten inzwischen geändert haben. JSONBin bietet hier jedoch keinen atomaren gemeinsamen Draft: exakt gleichzeitige Schreibvorgänge können weiterhin kollidieren. Für verlässlichen parallelen Betrieb ist eine Cloud-Datenbank mit serverseitiger Anmeldung und atomaren Picks der nächste Schritt.

Team-Bilder werden direkt aus den offiziellen Joyn-Bildquellen geladen. Bei fehlender Internetverbindung bleiben Namen und Bedienung nutzbar. Bilder: Bernhard Eder / ATV; keine nachgebauten oder erfundenen Kandidatenporträts.

## Geprüft

500 simulierte vollständige Drafts mit wechselnder Reihenfolge und Picks, Pool-Kapazitäten, doppelte Team-Auswahl, Sackgassen, Snake-Reihenfolge, Wertung ab Folge 2, Punkte für beide Besitzer, Rücknahme über die Pick-Historie und geteilte Ränge bei Punktgleichheit. Handy-Ansicht bei 390 Pixeln, Navigation und Admin-Anmeldung im Browser geprüft. Der echte Draft blieb geschlossen.

News zusätzlich geprüft: Quellenbegrenzung auf Österreich/Joyn, Artikel-Datumsangaben, Zuordnung aller elf Teams, Spoiler-Ausblendung inklusive Bilder, Filter, Aktualisierung, Verhalten bei leeren/offline/älteren Datenständen und sichere Behandlung externer Inhalte. Handy-Ansichten bei 320, 390 und 430 Pixeln geprüft.

Auslosung zusätzlich geprüft: 500 simulierte Ziehungen, eindeutige Plätze, beliebige Aufdeck-Reihenfolge, Schutz vor erneutem Auslosen, gespeicherter Zwischenstand, Draft-Sperre bis zum letzten Los, bisherige Datenstände, isolierte Demo und Zufallsziehung ohne Modulo-Verzerrung. Die Demo wurde im Browser vollständig durchgespielt; die echte Liga wurde nicht ausgelost.

Karten und Animation zusätzlich geprüft: Erhaltung bereits aufgedeckter Los-Elemente bei erneutem Rendern, Animation ausschließlich für das nächste Los, Trennung unterschiedlicher Ziehungen, elf Liga-Rückseiten, unveränderte Draft-Auswahl, Maus-/Touch-Verhalten und inaktive Rückseiten. Handy-Ansichten bei 320 und 390 Pixeln ohne horizontales Überlaufen geprüft; Team-Info und Escape im Browser ausprobiert.

## Offizielle Besetzung

[Senderbestätigung, 24. September 2026](https://www.prosiebensat1puls4.com/n/fhrs5-paar11-cast/)

[Joyn-Cast-Übersicht mit Paarbildern](https://www.joyn.at/bts/serien/forsthaus-rampensau/forsthaus-rampensau-diese-reality-stars-wagen-den-kampf-um-den-titel-rampensau2026-166109)

[Joyn-News zur österreichischen Show](https://www.joyn.at/bts/serien/forsthaus-rampensau)

[GitHub: eigene Pages-Workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)

[GitHub: geplante Workflow-Läufe](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule)

## Erster Login

Nach der ersten Anmeldung führt ein kurzer Einstieg durch Begrüßung, Namen und Bild sowie drei Spielregeln. Änderungen werden erst mit „Ab in die Liga“ gespeichert. „Später einrichten“ schließt ohne Speicherung; der Einstieg erscheint beim nächsten Login wieder. Die Regeln können übersprungen werden. Im Profil öffnet „Name ändern / Einführung ansehen“ den Ablauf erneut.

Euer eigenes transparentes Logo wird im Header und Welcome-Screen verwendet: `assets/fantasy-league-logo.png`. Diese Datei muss mit veröffentlicht werden.

## Team-Auswertung und Ereignisvorschläge

Im Liga-Dashboard lassen sich Kategorie, Folge und Vergleich (Punkte oder Ereignisanzahl) wählen. Die Balken und Führungsanzeige berücksichtigen nur verbuchte Ereignisse; ein Team öffnet seine Details. Bei Gleichstand werden alle führenden Teams genannt.

Unter Verlauf können Mitglieder Ereignisse ab Folge 2 vorschlagen und ihre eine Stimme pro Vorschlag ändern. Der Admin übernimmt oder verwirft Vorschläge. Aus sichtbaren News öffnet der Admin „Ereignis für Wertung prüfen“; Team, Folge, Ereignis und Beobachtung müssen geprüft werden. Die Quelle bleibt erhalten. Es erfolgt keine automatische Interpretation von Artikeln. Pro Team/Folge/Kategorie wird ein bestehender offener oder bestätigter Vorschlag verwendet. Eine Bestätigung kann nur einmal Punkte verbuchen. Vorschläge werden zusammen mit der Saison lokal bzw. über die vorhandene Cloud gespeichert. Alte Saison-Dateien bleiben gültig.
