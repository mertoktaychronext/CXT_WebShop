# Key-User-Handbuch – SL Chronext Webshop (Verkaufspreisverwaltung)

## Über dieses Dokument

Dieses Handbuch richtet sich an Key User, die die Grundeinstellungen der Verkaufspreisverwaltung pflegen, Länder für den Preisexport freischalten und bei Problemen die erste Anlaufstelle für die Fachabteilung sind.

## Grundeinstellungen (General Sales Price Setup)

Über die Seite **"General Sales Price Setup"** werden die Regeln hinterlegt, gegen die jeder importierte Preis geprüft wird:

| Einstellung | Bedeutung |
|---|---|
| Mindestmarge % | Preise mit einer geringeren Marge werden bei "Validate" mit einer Bemerkung markiert (Achtung: In der Webshop-Anzeige selbst wird ein Artikel bei Unterschreitung der Marge deaktiviert – siehe ToolTip auf dem Feld). |
| Schwellenwert Lagerpreis % | Ab welcher prozentualen Preiserhöhung gegenüber dem letzten Preis eine Bemerkung erzeugt wird. |
| Schwellenwert Nicht-Lagerpreis % | Analog für Nicht-Lagerartikel (aktuell nicht aktiv genutzt, siehe Entwicklerhandbuch). |
| Kat. 1–3 Nicht-Lager % / Lagerpreis von/bis | Vorbereitet für eine automatische Berechnung des Nicht-Lagerpreises je Preiskategorie. Diese Berechnung ist im laufenden Betrieb aktuell nicht aktiviert. |
| Preisexport aktiv | Schalter für einen zukünftigen automatisierten Preisexport an externe Systeme (siehe Entwicklerhandbuch, Baustein ist noch nicht produktiv). |

Diese Einstellungen **müssen** befüllt sein (Mindestmarge %, Schwellenwert Lagerpreis %), sonst lassen sich Import, Prüfung und Freigabe nicht ausführen.

## Länder für den Preisexport freischalten

In den Stammdaten von **Land/Region** wurden folgende Felder ergänzt:

| Feld | Bedeutung |
|---|---|
| Verkaufspreis aktiviert | Muss gesetzt sein, damit für dieses Land automatisch Preise (z. B. über "Add all Currencies") erzeugt werden können. |
| Verkaufspreis-Währungscode | Die Währung, in der Preise für dieses Land geführt werden. Länder mit derselben Währung erhalten bei "Add all Currencies" dieselbe (eine) Preiszeile. |
| Besteuerungsart | Vollbesteuerung, Differenzbesteuerung oder beides – aktuell nur informativ hinterlegt, ohne automatische Auswirkung auf die Preisberechnung. |
| Lieferzeit (Tage) | Informationsfeld, aktuell ohne automatische Auswirkung auf die Preisprüfung. |

> Ohne "Verkaufspreis aktiviert" wird ein Land bei "Add all Currencies" nicht berücksichtigt.

## Grundcode (Reason Code)

Jeder Preisänderung kann ein Grund zugeordnet werden: **CatMan**, **Einkauf** oder **Marketing**. Dies dient der Nachvollziehbarkeit, warum ein Preis geändert wurde, wird aber aktuell nicht weiter ausgewertet.

## Workflows und Prozesse

Der reguläre Ablauf für die Fachabteilung ist: **Import → Validate → Approve → (optional) Add all Currencies**. Als Key User sind Sie zuständig für die Rahmenbedingungen (Grundeinstellungen, Länderfreischaltung), nicht für den täglichen Ablauf selbst (siehe Benutzerhandbuch).

### Modus "Non DE Price"

Die Preisliste kennt zwei Modi: deutsche Preise (Grundlage für "Add all Currencies") und internationale Preise. Ein Sachbearbeiter kann nur einen Modus gleichzeitig bearbeiten; das System verhindert aktiv das Mischen beider Modi in derselben Liste.

## Datenmanagement

- **Archiv**: Über die Seite "Sales Price Archive" lassen sich verarbeitete Preise nachträglich einsehen. Eine automatische Befüllung dieses Archivs beim Freigabeschritt ist im aktuellen Stand **nicht** aktiv (siehe Entwicklerhandbuch, Punkt "Upload Sales Price").
- **Import/Export über Dateien**: Es existiert ein vorbereiteter, aber noch nicht angebundener Baustein für einen automatisierten, dateibasierten Preisimport/-export. Dieser ist aktuell nicht Teil des produktiven Ablaufs.

## Troubleshooting

| Problem | Ursache / Lösung |
|---|---|
| Import CSV lässt sich nicht ausführen | Grundeinstellungen (Mindestmarge %, Schwellenwert Lagerpreis %) sind nicht befüllt, oder die Liste enthält noch Preiszeilen aus einem vorherigen Durchlauf. |
| "Add all Currencies" ist ausgegraut | Der Schalter "Non DE Price" ist aktiv – die Aktion steht nur im deutschen Preismodus zur Verfügung. |
| "Add all Currencies" erzeugt keine Zeilen für ein bestimmtes Land | Prüfen Sie, ob für das Land "Verkaufspreis aktiviert" gesetzt und eine Verkaufspreis-Währung hinterlegt ist. |
| Ein Preis wird trotz korrekter Eingabe nicht mit Marge X% berechnet | Die kategoriebasierte Nicht-Lagerpreis-Berechnung ist aktuell nicht aktiv – bitte an den Entwickler/das Projektteam eskalieren, falls diese Funktion benötigt wird. |

## Eskalationswege

Bei technischen Fragen, die über die reine Konfiguration hinausgehen (z. B. Fehlermeldungen, die im Benutzer- oder Key-User-Handbuch nicht erklärt sind, oder Wünsche nach Aktivierung der aktuell zurückgestellten Funktionen), wenden Sie sich an das Entwicklungsteam – siehe Entwicklerhandbuch.
