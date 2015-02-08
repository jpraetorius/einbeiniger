# Der halbautomatische Einbeinige (für WRINT)

**Der halbautomatische Einbeinige**(DhE) ist ein Tool, mit dem die Anrufer der Sendereihe "Ferngespräche" für die Sendungssammlung [WRINT](http://wrint.de) verwaltet werden können.

Sie ist basierend auf [Sinatra](http://www.sinatrarb.com/) und [MongoDB](http://http://www.mongodb.org/) gebaut und verwaltet einfach nur ein paar Kernangaben der Anrufer.

Neben Sinatra und MongoDB steht DhE auf den folgenden technologischen Schultern:
 * [Flatstrap](http://littlesparkvt.com/flatstrap/index.html) – für die GUIs
 * [jQuery](http://jquery.com) – für das Javascript
 * [FontAwesome](http://fortawesome.github.com/Font-Awesome/) – für den Iconfont
 * [BootstrapSwitch](https://github.com/nostalgiaz/bootstrap-switch) – für fancy Switches
 * [jQuery Tags](https://github.com/xoxco/jQuery-Tags-Input) – für fancy Tags
 und ein kleinerer Haufen von Ruby Gems.

## Funktion/Oberfläche
Die Oberfläche von DhE teilt sich in zwei Teile: das Frontend und das Backend.
### Frontend
Das Frontend enthält nur zwei Seiten: die allgemeine Willkommensseite und die Anmeldung als Hörer. Ist das Annehmen von neuen Anmeldungen gesperrt (per Einstellung im Backend), so steht die Anmeldeseite nicht zur Verfügung.
### Backend
In das Backend gelangt man, indem man sich im Menü ganz oben rechts anmeldet. Angemeldete Nutzer sehen an dieser Stelle Ihren Nutzernamen und ein kleines Dropdown-Menü.
Das Backend selber hat drei Unterfunktionen
* Übersicht: zeigt kurz die aktuelle Konfiguration und die eingegangenen Anmeldungen
* Anmeldungen: listet die Anmeldungen auf, erlaubt das Suchen und Löschen von Anmeldungen
* Einstellungen: enthält die Settings für die Applikation _und_ den angemeldeten User. Hier können diese entsprechend abgeändert werden.

#### Anmeldungen
Die Übersichtsseite der Anmeldungen ist als Haupt-Tool beim Senden gedacht (oder bei der Vorbereitung auf eine Sendung). Per Default werden hier alle Anmeldungen (aufsteigend nach dem Anmeldedatum sortiert) angezeigt. Dabei werden nur eine Handvoll von Daten zur Orientierung angezeigt. Die vollen Details eines Eintrags lassen sich über das Lupen-Symbol aufrufen.

Über das Löschsymbol lassen sich Einträge als zum Löschen markieren, ein erneuter Klick nimmt diese Markierung zurück. Über den Button 'Markierte löschen' werden die markierten Einträge gelöscht.

Die Suchmaske erlaubt es in den vorhandenen Anmeldungen zu suchen. Dabei kann nach dem Namen des Hörenden gesucht werden (diese Suche ist unscharf und findet den Suchstring auch als Wortteil; die Suche nach 'test' findet also 'test', 'test2', 'tester' und auch 'attest'). Ausserdem kann nach Tags gesucht werden (mehrere Tags können per Komma oder Leerzeichen getrennt werden). Wird in beiden Feldern etwas eingegeben, so werden die Parameter per _UND_ verknüpft, es werden also nur die Einträge gefunden, die allen Bedingungen entsprechen.

Tags zu Anmeldungen lassen sich in der Detailansicht vergeben. Sie dienen der Markierung von Anmeldungen in der Sendungsvorbereitung (und dann dem späteren Wiederauffinden). Ein neues Tag fügt man einfach in der Textbox hinzu, das Tag wird per &lt;Return&gt; abgeschlossen.

## Setup
`bundle install` sollte die benötigten Ruby Dependencies installieren. Daneben wird eine auf dem Standard-Port (`27017`) laufende MongoDB Instanz erwartet, die keine weitere Authentisierung benötigt und auf `localhost` (respektive `127.0.0.1`) bindet..
## MongoDB
Die Datenbank die die Applikation verwendet heisst 'einbeiniger'
Sie legt darin drei Collections für Daten an:
* `settings` – für Einstellungen der Applikation
* `users` – für die eingerichteten User
* `registrations` – für die Anmeldungen von Hörern

Die DB laesst sich ueber den inkludierten Rakefile via `rake db_create` anlegen.

Um auf das Backend zuzugreifen muss es in der Collection `users` mindestens einen User geben. Da dessen Password BCrypt gehasht vorliegen muss, ist es momentan am einfachsten diesen über den Rake-Task `create_user` anzulegen. Der Name des Users und das Passwort werden dabei auf der Console abgefragt. Das Passwort kann hinterher im Backend angepasst werden.

### Settings
`settings` enthält die Einstellungen zu den 'beweglichen' Teilen der Applikation. Jedes einzelne Applikationssetting wird dabei als einzelnes Dokument gespeichert, das ein `name` => `value` Paar enthält. Bisher gibt es die folgenden Settings:

- `registration_open`: Gibt an, ob die Registrierung als Anrufer möglich ist, oder nicht – `true|false`
- `next_date`: Gibt das Datum der nächsten geplanten Sendung an. Dieses wird auf der Startseite angezeigt und schaltet automatisch die Registrierung ein, falls dieses Datum nicht weiter als drei Tage in der Zukunft liegt.

### Users
Todo

### Registrations
Todo

## Sinatra App
Die zusätzlich zu Sinatra eingebundenen Gems dienen vor allem der Absicherung der Applikation. So kommt [RackProtection](https://github.com/rkh/rack-protection) zum Einsatz, so dass neben den Basiseinstellungen auch AuthTokens beim submitten der Forms notwendig sind. Ausserdem wird auf erubis gesetzt, bei dem das automatische HTML-Escaping der Ausgabe eingeschaltet ist.

