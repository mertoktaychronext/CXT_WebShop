# Key-User-Handbuch – SL Chronext Webshop (Verkaufspreisverwaltung & SellWatch)

## Über dieses Dokument

Dieses Handbuch richtet sich an Key User, die die Grundeinstellungen der Verkaufspreisverwaltung pflegen, Länder und Währungen für die Preiserzeugung freischalten, die externe Schnittstelle für den SellWatch-Online-Check konfigurieren und bei Problemen die erste Anlaufstelle für die Fachabteilung sind. Das Handbuch deckt beide, fachlich unabhängigen Teile der Erweiterung ab: die Verkaufspreisverwaltung und SellWatch (Ankaufsanfragen für gebrauchte Uhren).

## Grundeinstellungen (General Sales Price Setup)

Über die Seite **"General Sales Price Setup"** werden die Regeln hinterlegt, gegen die jeder importierte Preis geprüft wird:

| Einstellung | Bedeutung |
|---|---|
| Mindestmarge % | Preise mit einer geringeren Marge werden bei "Validate" mit einer Bemerkung markiert (Achtung: In der Webshop-Anzeige selbst wird ein Artikel bei Unterschreitung der Marge deaktiviert – siehe ToolTip auf dem Feld). |
| Schwellenwert Lagerpreis % | Ab welcher prozentualen Preiserhöhung gegenüber dem letzten Preis eine Bemerkung erzeugt wird. |
| Schwellenwert Nicht-Lagerpreis % | Analog für Nicht-Lagerartikel (aktuell nicht aktiv genutzt, siehe Entwicklerhandbuch). |
| Kat. 1–3 Nicht-Lager % / Lagerpreis von/bis | Vorbereitet für eine automatische Berechnung des Nicht-Lagerpreises je Preiskategorie. Diese Berechnung ist im laufenden Freigabe-Ablauf aktuell nicht automatisch eingebunden. |
| Preisexport aktiv | Muss aktiviert sein, damit die Aktion "Upload Sales Price" (Benutzerhandbuch) Preise an ein externes System senden kann. |
| API-Schnittstellencode | Legt fest, welche der unter "API Interface Setup" hinterlegten Schnittstellen für den Preisexport verwendet wird. |

Diese Einstellungen **müssen** befüllt sein (Mindestmarge %, Schwellenwert Lagerpreis %), sonst lassen sich Import, Prüfung und Freigabe nicht ausführen. Für "Upload Sales Price" müssen zusätzlich "Preisexport aktiv" und "API-Schnittstellencode" gesetzt sein.

## Externe Schnittstelle einrichten (API Interface Setup)

Über die Navigation-Schaltfläche **"API Interface Setup"** auf der Seite "General Sales Price Setup" gelangen Sie zur Verwaltung der externen Schnittstellen, an die Preise gesendet werden können:

| Feld | Bedeutung |
|---|---|
| Code | Eindeutiger Code der Schnittstelle – wird im Feld "API-Schnittstellencode" der Grundeinstellungen ausgewählt. |
| Description | Freitext-Beschreibung der Schnittstelle. |
| Endpoint URL | Die Ziel-URL, an die die Preisdaten per HTTP gesendet werden. Pflichtfeld, sobald die Schnittstelle aktiviert wird. |
| Auth Type | Art der Authentifizierung: Keine, API-Schlüssel (Header) oder Basisauthentifizierung. |
| API Key | Der API-Schlüssel bzw. das Token für die Authentifizierung. Wird verschlüsselt gespeichert und nach dem Speichern nicht mehr im Klartext angezeigt. Pflichtfeld, sobald eine Authentifizierungsart außer "Keine" gewählt wurde. |
| Source Table No. | Die Tabelle, für die diese Schnittstelle Daten überträgt (für den Preisexport: die Tabellennummer von "Sales Price"). |
| Active | Muss gesetzt sein, damit die Schnittstelle in den Grundeinstellungen auswählbar ist. Beim Aktivieren prüft das System automatisch, dass Endpoint URL und – falls nötig – API Key hinterlegt sind. |

> Ohne eine aktive, vollständig konfigurierte Schnittstelle schlägt "Upload Sales Price" fehl bzw. markiert betroffene Preiszeilen mit "Export Status" = "Error".

## Währungen für "Add all Currencies" freischalten

In den Stammdaten der **Währung** (Seite "Currencies") wurde folgendes Feld ergänzt:

| Feld | Bedeutung |
|---|---|
| Verkaufspreis aktiviert | Muss gesetzt sein, damit für diese Währung automatisch eine Preiszeile erzeugt wird, wenn "Add all Currencies" ausgeführt wird. |

> Ohne "Verkaufspreis aktiviert" wird eine Währung bei "Add all Currencies" nicht berücksichtigt.

## Land/Region – Zusatzangaben

In den Stammdaten von **Land/Region** (Seite "Countries/Regions") wurden folgende Felder ergänzt:

| Feld | Bedeutung |
|---|---|
| Verkaufspreis-Währungscode | Die Standard-Fremdwährung dieses Landes. Rein informativ hinterlegt. |
| Besteuerungsart | Vollbesteuerung, Differenzbesteuerung oder beides – aktuell nur informativ hinterlegt, ohne automatische Auswirkung auf die Preisberechnung. |
| Lieferzeit (Tage) | Informationsfeld, aktuell ohne automatische Auswirkung auf die Preisprüfung. |

> **Wichtig:** Die Freischaltung für "Add all Currencies" erfolgt seit der letzten Überarbeitung direkt auf der **Währung**, nicht mehr auf dem Land. Ein Land ohne "Verkaufspreis-Währungscode" kann trotzdem Preise erhalten, solange die zugehörige Währung aktiviert ist.

## Grundcode (Reason Code)

Jeder Preisänderung kann ein Grund zugeordnet werden: **CatMan**, **Einkauf** oder **Marketing**. Dies dient der Nachvollziehbarkeit, warum ein Preis geändert wurde, wird aber aktuell nicht weiter ausgewertet. Ohne explizite Auswahl wird "CatMan" als Standardwert verwendet.

## Workflows und Prozesse

Der reguläre Ablauf für die Fachabteilung ist: **Import → Validate → Approve → (optional) Add all Currencies → Upload Sales Price**. Als Key User sind Sie zuständig für die Rahmenbedingungen (Grundeinstellungen, Währungsfreischaltung, API-Schnittstelle), nicht für den täglichen Ablauf selbst (siehe Benutzerhandbuch).

Für SellWatch gibt es keinen von der Fachabteilung manuell ausgelösten Ablauf: Neue Ankaufsanfragen (Verkäufer-, Uhren- und Angebotsdaten) treffen automatisiert ein und werden automatisiert zu Lieferant und Einkaufsbestellung verarbeitet; die Fachabteilung sieht das Ergebnis nur lesend auf der Seite "SellWatch-Overview" (Benutzerhandbuch). Als Key User sind Sie hier zuständig für die Konfiguration der Online-Check-Schnittstelle (siehe unten) und für die Berechtigungsvergabe.

## SellWatch – Online-Check-Schnittstelle einrichten (API Interface Setup)

Der SellWatch-Online-Check (prüft, ob eine Uhr im SellWatch-Onlineshop sichtbar sein sollte) nutzt dieselbe Seite **"API Interface Setup"** wie der Preisexport der Verkaufspreisverwaltung (siehe oben) – jedoch immer den festen Schnittstellen-Code **`WOA`**. Legen Sie dort einen Eintrag mit Code `WOA` an bzw. pflegen Sie ihn:

| Feld | Bedeutung für SellWatch |
|---|---|
| Code | Muss exakt `WOA` lauten – dieser Code ist im SellWatch-Code fest hinterlegt und nicht änderbar. |
| Endpoint URL | Basis-URL des SellWatch-Online-Check-Endpunkts. Die tatsächliche Anfrage wird an `<Endpoint URL>/<Artikelnummer>/<Variantencode>/check` gesendet. |
| API Key | Wird als HTTP-Header `X-API-KEY` mitgesendet, verschlüsselt gespeichert. |
| Active | Muss gesetzt sein, sonst führt der Online-Check keinen Aufruf durch. |

> Anders als beim Preisexport der Verkaufspreisverwaltung gibt es für den Online-Check kein Auswahlfeld für den Schnittstellencode in den Grundeinstellungen – der Code `WOA` ist im Code fest verdrahtet.

> Fehlgeschlagene Aufrufe können Sie über die Seite **"SW Http Call Log"** nachvollziehen: Sie zeigt zu jedem Aufruf Erfolg/Fehlschlag, HTTP-Statuscode und Fehlermeldung, und erlaubt den Download des gesendeten Requests sowie der empfangenen Antwort als Textdatei (der API-Schlüssel wird im gespeicherten Request nicht im Klartext angezeigt).

## Datenmanagement

- **Sales Price / Archiv**: Bei jedem Ausführen von "Upload Sales Price" wird die freigegebene Preiszeile automatisch in die produktive Verkaufspreis-Tabelle (immer gültig für alle Kunden) sowie als neue, fortlaufend nummerierte Version in "Sales Price Archive" übernommen – auch bei einem erneuten Senden bereits übertragener Zeilen. Eine manuelle Pflege dieser beiden Tabellen ist nicht vorgesehen und nicht nötig.
- **Import/Export über Dateien**: Es existiert ein vorbereiteter, aber noch nicht angebundener Baustein für einen automatisierten, dateibasierten Preisimport. Dieser ist aktuell nicht Teil des produktiven Ablaufs (kein Job-Queue-Eintrag).
- **SellWatch-Ankaufsanfragen**: Die Tabellen hinter "SellWatch-Overview" sowie das Protokoll des Online-Checks ("SW Http Call Log") werden ausschließlich automatisiert befüllt; eine manuelle Pflege ist nicht vorgesehen und über die Seiten der Erweiterung auch nicht möglich (alle SellWatch-Seiten sind schreibgeschützt).

## Berechtigungen

Der Zugriff auf alle Objekte der Verkaufspreisverwaltung ist über das Permission Set **"CXWChronWSAll"** geregelt. Für SellWatch gilt das eigene Permission Set **"CXW SWChronWSAll"** (deckt "SellWatch-Overview", "SellWatch info" und "SW Http Call Log" sowie die zugrundeliegenden Tabellen ab). Beide Sets müssen den entsprechenden Benutzern bzw. Benutzergruppen noch zugewiesen werden, bevor diese die jeweiligen Seiten der Erweiterung nutzen können.

## Troubleshooting

| Problem | Ursache / Lösung |
|---|---|
| Import CSV lässt sich nicht ausführen | Grundeinstellungen (Mindestmarge %, Schwellenwert Lagerpreis %) sind nicht befüllt, oder die Liste enthält noch Preiszeilen aus einem vorherigen Durchlauf. |
| "Add all Currencies" erzeugt keine Zeile für eine bestimmte Währung | Prüfen Sie, ob für die Währung (Seite "Currencies") "Verkaufspreis aktiviert" gesetzt ist. |
| Ein Benutzer kann die Seiten der Verkaufspreisverwaltung nicht öffnen | Prüfen Sie, ob dem Benutzer das Permission Set "CXWChronWSAll" zugewiesen ist. |
| Ein Preis wird trotz korrekter Eingabe nicht mit Marge X% berechnet | Die kategoriebasierte Nicht-Lagerpreis-Berechnung ist aktuell nicht automatisch eingebunden – bitte an das Entwicklungsteam eskalieren, falls diese Funktion benötigt wird. |
| "Upload Sales Price" meldet, dass keine API-Schnittstelle hinterlegt ist bzw. bricht ab | Prüfen Sie in den Grundeinstellungen, ob "Preisexport aktiv" gesetzt und ein "API-Schnittstellencode" ausgewählt ist, und ob die zugehörige Schnittstelle unter "API Interface Setup" aktiv sowie vollständig konfiguriert (Endpoint URL, ggf. API Key) ist. |
| Einzelne Preiszeilen bleiben nach "Upload Sales Price" mit "Export Status" = "Error" stehen | Andere Zeilen im selben Lauf werden trotzdem weiterverarbeitet. Prüfen Sie die betroffene Zeile auf ungültige Werte (z. B. nicht existierender Währungscode) und lösen Sie den Upload für diese Zeile erneut aus. |
| Ein Benutzer kann die SellWatch-Seiten nicht öffnen | Prüfen Sie, ob dem Benutzer das Permission Set "CXW SWChronWSAll" zugewiesen ist. |
| Eine Uhr wird auf "SellWatch-Overview" nie als online markiert bzw. "SW Http Call Log" zeigt Fehlschläge | Prüfen Sie, ob unter "API Interface Setup" ein Eintrag mit Code `WOA` existiert, aktiv ist und Endpoint URL sowie API Key gesetzt sind. Details zum konkreten Fehler (Statuscode, Fehlermeldung) finden Sie auf der Seite "SW Http Call Log". |
| Zu einer SellWatch-Anfrage wird kein Lieferant/keine Bestellung angelegt | Die Anlage erfolgt vollautomatisiert im Hintergrund; es gibt keine Aktion, mit der Sie dies als Key User manuell anstoßen können. Prüfen Sie zunächst, ob die Anfrage überhaupt vollständig eingegangen ist, und eskalieren Sie sonst an das Entwicklungsteam. |

## Eskalationswege

Bei technischen Fragen, die über die reine Konfiguration hinausgehen (z. B. Fehlermeldungen, die im Benutzer- oder Key-User-Handbuch nicht erklärt sind, oder Wünsche nach Aktivierung der aktuell zurückgestellten Funktionen), wenden Sie sich an das Entwicklungsteam – siehe Entwicklerhandbuch.
