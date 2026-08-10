# Key-User-Handbuch – CHX.Webshop

## Über dieses Dokument

Dieses Handbuch richtet sich an Key User, die die Grundeinstellungen der Verkaufspreisverwaltung pflegen, Länder und Währungen für die Preiserzeugung freischalten, die SellWatch-Schnittstelle konfigurieren und bei Problemen die erste Anlaufstelle für die Fachabteilung sind.

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

## SellWatch-Schnittstelle einrichten

Die Freigabeprüfung, ob eine angekaufte Uhr online gehen darf ("Watch Online Approval"), nutzt **dieselbe** Schnittstellen-Verwaltung wie der Preisexport (Seite **"API Interface Setup"**, siehe oben). Legen Sie dort einen eigenen Eintrag mit **Code = `WOA`** an:

| Feld | Wert für SellWatch |
|---|---|
| Code | `WOA` (fest vorgegeben – wird so im Code gesucht) |
| Endpoint URL | Basis-URL der SellWatch-Prüf-API (der Pfad `/<Artikelnr.>/<Variantencode>/check` wird automatisch angehängt). |
| API Key | Der von SellWatch bereitgestellte API-Schlüssel. |
| Active | Muss gesetzt sein, sonst wird die Online-Freigabeprüfung stillschweigend übersprungen. |

> **Wichtig:** Anders als beim Preisexport wird das Feld **"Auth Type"** für diesen Eintrag nicht ausgewertet – der API-Schlüssel wird für SellWatch immer als Header `X-API-KEY` gesendet, unabhängig von der gewählten Authentifizierungsart. Es genügt, "Code", "Endpoint URL", "API Key" und "Active" zu pflegen.

Ohne diesen Eintrag (oder wenn er inaktiv ist bzw. kein API-Schlüssel hinterlegt ist) bricht die Freigabeprüfung ohne Fehlermeldung ab – die betroffene Uhr bleibt einfach unverändert.

**Jeder tatsächlich durchgeführte Aufruf** (erfolgreich oder fehlgeschlagen) wird auf der Seite **"SW Http Call Log"** protokolliert – dort lassen sich Request und Response je Eintrag als .txt-Datei herunterladen. Der API-Schlüssel erscheint darin nie im Klartext (nur als Platzhalter). Fehlgeschlagene Aufrufe werden zusätzlich per Telemetry gemeldet (für das Entwicklungsteam, siehe Entwicklerhandbuch).

## Grundcode (Reason Code)

Jeder Preisänderung kann ein Grund zugeordnet werden: **CatMan**, **Einkauf** oder **Marketing**. Dies dient der Nachvollziehbarkeit, warum ein Preis geändert wurde, wird aber aktuell nicht weiter ausgewertet. Ohne explizite Auswahl wird "CatMan" als Standardwert verwendet.

## Workflows und Prozesse

Der reguläre Ablauf für die Fachabteilung ist: **Import → Validate → Approve → (optional) Add all Currencies → Upload Sales Price**. Als Key User sind Sie zuständig für die Rahmenbedingungen (Grundeinstellungen, Währungsfreischaltung, API-Schnittstelle), nicht für den täglichen Ablauf selbst (siehe Benutzerhandbuch).

## Datenmanagement

- **Sales Price / Archiv**: Bei jedem Ausführen von "Upload Sales Price" wird die freigegebene Preiszeile automatisch in die produktive Verkaufspreis-Tabelle (immer gültig für alle Kunden) sowie als neue, fortlaufend nummerierte Version in "Sales Price Archive" übernommen – auch bei einem erneuten Senden bereits übertragener Zeilen. Eine manuelle Pflege dieser beiden Tabellen ist nicht vorgesehen und nicht nötig.
- **Import/Export über Dateien**: Es existiert ein vorbereiteter, aber noch nicht angebundener Baustein für einen automatisierten, dateibasierten Preisimport. Dieser ist aktuell nicht Teil des produktiven Ablaufs (kein Job-Queue-Eintrag).

## Berechtigungen

Der Zugriff ist über zwei getrennte Permission Sets geregelt, die den entsprechenden Benutzern bzw. Benutzergruppen noch zugewiesen werden müssen:

| Permission Set | Deckt ab |
|---|---|
| `SLChronWSAll` | Alle Objekte der Verkaufspreisverwaltung |
| `CXW SWChronWSAll` | Alle Objekte der SellWatch-Ankaufsintegration (SellWatch Vendor Info, Watch Online Approval, SW Http Call Log, SellWatch-Overview, SellWatch info) |

## Troubleshooting

| Problem | Ursache / Lösung |
|---|---|
| Import CSV lässt sich nicht ausführen | Grundeinstellungen (Mindestmarge %, Schwellenwert Lagerpreis %) sind nicht befüllt, oder die Liste enthält noch Preiszeilen aus einem vorherigen Durchlauf. |
| "Add all Currencies" erzeugt keine Zeile für eine bestimmte Währung | Prüfen Sie, ob für die Währung (Seite "Currencies") "Verkaufspreis aktiviert" gesetzt ist. |
| Ein Benutzer kann die Seiten der Erweiterung nicht öffnen | Prüfen Sie, ob dem Benutzer das passende Permission Set zugewiesen ist ("SLChronWSAll" für die Preisverwaltung, "CXW SWChronWSAll" für SellWatch). |
| Ein Preis wird trotz korrekter Eingabe nicht mit Marge X% berechnet | Die kategoriebasierte Nicht-Lagerpreis-Berechnung ist aktuell nicht automatisch eingebunden – bitte an das Entwicklungsteam eskalieren, falls diese Funktion benötigt wird. |
| "Upload Sales Price" meldet, dass keine API-Schnittstelle hinterlegt ist bzw. bricht ab | Prüfen Sie in den Grundeinstellungen, ob "Preisexport aktiv" gesetzt und ein "API-Schnittstellencode" ausgewählt ist, und ob die zugehörige Schnittstelle unter "API Interface Setup" aktiv sowie vollständig konfiguriert (Endpoint URL, ggf. API Key) ist. |
| Einzelne Preiszeilen bleiben nach "Upload Sales Price" mit "Export Status" = "Error" stehen | Andere Zeilen im selben Lauf werden trotzdem weiterverarbeitet. Prüfen Sie die betroffene Zeile auf ungültige Werte (z. B. nicht existierender Währungscode) und lösen Sie den Upload für diese Zeile erneut aus. |
| Eine Uhr wird nie für den Online-Verkauf freigegeben, obwohl sie es sein sollte | Zuerst die Seite **"SW Http Call Log"** öffnen und nach Einträgen zur betroffenen Uhr filtern (Spalte "Source Entry No" = Lfd. Nr. der Uhr auf "Watch Online Approval"): Gibt es dort einen Eintrag mit "Success" = Nein, zeigt "Error Message" bzw. der herunterladbare Request/Response die genaue Ursache (z. B. Netzwerkfehler, falscher HTTP-Status). Gibt es dort **gar keinen** Eintrag zur betroffenen Uhr, wurde der Aufruf nie ausgeführt — dann den API-Interface-Eintrag mit Code "WOA" prüfen (siehe oben): vorhanden, aktiv, API-Schlüssel und Endpoint URL gesetzt? Diese Konfigurationsprüfung bricht weiterhin ohne Log-Eintrag ab, wenn die Schnittstelle fehlt/inaktiv ist. |
| Neue SellWatch-Anfragen erscheinen nicht in "SellWatch-Overview" bzw. es wird nie automatisch ein Lieferant/eine Bestellung angelegt | Die Verarbeitung (Lieferanten-/Bestellanlage) muss aktuell separat angestoßen werden – es ist kein automatischer Job-Queue-Eintrag hinterlegt. Bitte an das Entwicklungsteam eskalieren (siehe Entwicklerhandbuch, "Bekannte Einschränkungen"). |

## Eskalationswege

Bei technischen Fragen, die über die reine Konfiguration hinausgehen (z. B. Fehlermeldungen, die im Benutzer- oder Key-User-Handbuch nicht erklärt sind, oder Wünsche nach Aktivierung der aktuell zurückgestellten Funktionen), wenden Sie sich an das Entwicklungsteam – siehe Entwicklerhandbuch.
