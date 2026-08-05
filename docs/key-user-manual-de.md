# Key-User-Handbuch – SL Chronext Webshop (Verkaufspreisverwaltung)

## Über dieses Dokument

Dieses Handbuch richtet sich an Key User, die die Grundeinstellungen der Verkaufspreisverwaltung pflegen, Länder und Währungen für die Preiserzeugung freischalten und bei Problemen die erste Anlaufstelle für die Fachabteilung sind.

## Grundeinstellungen (General Sales Price Setup)

Über die Seite **"General Sales Price Setup"** werden die Regeln hinterlegt, gegen die jeder importierte Preis geprüft wird:

| Einstellung | Bedeutung |
|---|---|
| Mindestmarge % | Preise mit einer geringeren Marge werden bei "Validate" mit einer Bemerkung markiert (Achtung: In der Webshop-Anzeige selbst wird ein Artikel bei Unterschreitung der Marge deaktiviert – siehe ToolTip auf dem Feld). |
| Schwellenwert Lagerpreis % | Ab welcher prozentualen Preiserhöhung gegenüber dem letzten Preis eine Bemerkung erzeugt wird. |
| Schwellenwert Nicht-Lagerpreis % | Analog für Nicht-Lagerartikel (aktuell nicht aktiv genutzt, siehe Entwicklerhandbuch). |
| Kat. 1–3 Nicht-Lager % / Lagerpreis von/bis | Vorbereitet für eine automatische Berechnung des Nicht-Lagerpreises je Preiskategorie. Diese Berechnung ist im laufenden Freigabe-Ablauf aktuell nicht automatisch eingebunden. |
| Preisexport aktiv | Schalter für einen zukünftigen automatisierten Preisexport an externe Systeme (siehe Entwicklerhandbuch, Baustein ist noch nicht produktiv). |

Diese Einstellungen **müssen** befüllt sein (Mindestmarge %, Schwellenwert Lagerpreis %), sonst lassen sich Import, Prüfung und Freigabe nicht ausführen.

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

Der reguläre Ablauf für die Fachabteilung ist: **Import → Validate → Approve → (optional) Add all Currencies**. Als Key User sind Sie zuständig für die Rahmenbedingungen (Grundeinstellungen, Währungsfreischaltung), nicht für den täglichen Ablauf selbst (siehe Benutzerhandbuch).

## Datenmanagement

- **Archiv**: Über die Seite "Sales Price Archive" lassen sich verarbeitete Preise nachträglich einsehen. Eine automatische Befüllung dieses Archivs beim Freigabeschritt ist im aktuellen Stand **nicht** aktiv (siehe Entwicklerhandbuch).
- **Import/Export über Dateien**: Es existiert ein vorbereiteter, aber noch nicht angebundener Baustein für einen automatisierten, dateibasierten Preisimport. Dieser ist aktuell nicht Teil des produktiven Ablaufs (kein Job-Queue-Eintrag).

## Berechtigungen

Der Zugriff auf alle Objekte dieser Erweiterung ist über das Permission Set **"SLChronWSAll"** geregelt. Dieses muss den entsprechenden Benutzern bzw. Benutzergruppen noch zugewiesen werden, bevor sie die Seiten der Erweiterung nutzen können.

## Troubleshooting

| Problem | Ursache / Lösung |
|---|---|
| Import CSV lässt sich nicht ausführen | Grundeinstellungen (Mindestmarge %, Schwellenwert Lagerpreis %) sind nicht befüllt, oder die Liste enthält noch Preiszeilen aus einem vorherigen Durchlauf. |
| "Add all Currencies" erzeugt keine Zeile für eine bestimmte Währung | Prüfen Sie, ob für die Währung (Seite "Currencies") "Verkaufspreis aktiviert" gesetzt ist. |
| Ein Benutzer kann die Seiten der Erweiterung nicht öffnen | Prüfen Sie, ob dem Benutzer das Permission Set "SLChronWSAll" zugewiesen ist. |
| Ein Preis wird trotz korrekter Eingabe nicht mit Marge X% berechnet | Die kategoriebasierte Nicht-Lagerpreis-Berechnung ist aktuell nicht automatisch eingebunden – bitte an das Entwicklungsteam eskalieren, falls diese Funktion benötigt wird. |

## Eskalationswege

Bei technischen Fragen, die über die reine Konfiguration hinausgehen (z. B. Fehlermeldungen, die im Benutzer- oder Key-User-Handbuch nicht erklärt sind, oder Wünsche nach Aktivierung der aktuell zurückgestellten Funktionen), wenden Sie sich an das Entwicklungsteam – siehe Entwicklerhandbuch.
