# workshop-lines-purchase-order-drilldown Specification

## Purpose
Anzeige der Anzahl Werkstattzeilen auf der Einkaufsbestellung (FlowField „No. of Workshop Lines“) mit DrillDown auf die gefilterte Seite „Workshop Lines“ sowie Meldung bzw. Rückfrage bei erneutem „Send to Workshop“, wenn für die Bestellung bereits Werkstattzeilen existieren.
## Requirements
### Requirement: Anzahl Werkstattzeilen auf der Einkaufsbestellung
Der Einkaufskopf SHALL ein nicht editierbares FlowField „No. of Workshop Lines“ (Anzahl Werkstattzeilen) besitzen, das die Datensätze in „CXW Workshop Line“ zählt, deren Belegart und Belegnummer der Belegart und Nummer des Einkaufskopfs entsprechen. Das Feld SHALL auf der Seite „Purchase Order“ (Einkaufsbestellung) angezeigt werden. Der Wert 0 SHALL als leeres Feld dargestellt werden.

#### Scenario: Bestellung ohne Werkstattzeilen
- **WHEN** der Benutzer eine Einkaufsbestellung öffnet, für die keine Werkstattzeilen existieren
- **THEN** ist das Feld „No. of Workshop Lines“ leer

#### Scenario: Bestellung mit Werkstattzeilen
- **WHEN** der Benutzer eine Einkaufsbestellung öffnet, für die zwei Werkstattzeilen existieren
- **THEN** zeigt das Feld „No. of Workshop Lines“ den Wert 2

#### Scenario: Anzahl aktualisiert sich nach „Send to Workshop“
- **WHEN** der Benutzer auf einer Bestellung ohne Werkstattzeilen „Send to Workshop“ ausführt und dabei eine Werkstattzeile angelegt wird
- **THEN** zeigt das Feld „No. of Workshop Lines“ nach Abschluss der Aktion den Wert 1

#### Scenario: Werkstattzeilen anderer Bestellungen zählen nicht mit
- **WHEN** für Bestellung „B-1“ eine Werkstattzeile und für Bestellung „B-2“ drei Werkstattzeilen existieren und der Benutzer Bestellung „B-1“ öffnet
- **THEN** zeigt das Feld „No. of Workshop Lines“ den Wert 1

### Requirement: Werkstattzeilen aus der Bestellung aufrufen
Ein Klick (DrillDown) auf das Feld „No. of Workshop Lines“ SHALL die Seite „Workshop Lines“ (Page 60338) öffnen, gefiltert auf Belegart und Belegnummer der aktuellen Einkaufsbestellung.

#### Scenario: DrillDown öffnet gefilterte Werkstattzeilen
- **WHEN** der Benutzer auf Bestellung „B-1“ mit zwei Werkstattzeilen auf den Wert im Feld „No. of Workshop Lines“ klickt
- **THEN** öffnet sich die Seite „Workshop Lines“ und zeigt genau die zwei Werkstattzeilen der Bestellung „B-1“

#### Scenario: DrillDown ohne Werkstattzeilen
- **WHEN** der Benutzer auf einer Bestellung ohne Werkstattzeilen den DrillDown des Feldes auslöst
- **THEN** öffnet sich die Seite „Workshop Lines“ ohne Datensätze

### Requirement: Hinweis bei erneutem „Send to Workshop“
Vor der Verarbeitung SHALL die Aktion „Send to Workshop“ prüfen, ob für die Einkaufsbestellung bereits Werkstattzeilen existieren. Existieren Werkstattzeilen und keine Artikelzeile mit Menge ungleich 0, die noch nicht an die Werkstatt gesendet wurde, SHALL das System eine Meldung anzeigen, dass für die Bestellung bereits Werkstattzeilen existieren und keine weiteren Zeilen zu senden sind, und SHALL keine Zeile verarbeiten. Existieren Werkstattzeilen und mindestens eine solche offene Artikelzeile, SHALL das System mit Angabe der Anzahl vorhandener Werkstattzeilen nachfragen, ob die übrigen Zeilen gesendet werden sollen; lehnt der Benutzer ab, SHALL keine Zeile verarbeitet werden. Existieren keine Werkstattzeilen, SHALL die Aktion ohne zusätzliche Meldung wie bisher ablaufen.

#### Scenario: Alle Zeilen bereits gesendet
- **WHEN** für die Bestellung Werkstattzeilen existieren, alle Artikelzeilen bereits „Sent to Workshop“ sind und der Benutzer „Send to Workshop“ ausführt
- **THEN** erscheint eine Meldung, dass bereits Werkstattzeilen existieren und keine weiteren Zeilen zu senden sind, und es wird keine Ankunftsabfrage gestellt

#### Scenario: Offene Zeilen vorhanden, Benutzer bestätigt
- **WHEN** für die Bestellung zwei Werkstattzeilen existieren, eine weitere Artikelzeile noch nicht gesendet ist, der Benutzer „Send to Workshop“ ausführt und die Rückfrage bestätigt
- **THEN** wird die Rückfrage mit dem Hinweis auf zwei vorhandene Werkstattzeilen angezeigt und anschließend nur die noch nicht gesendete Zeile wie bisher verarbeitet

#### Scenario: Offene Zeilen vorhanden, Benutzer lehnt ab
- **WHEN** für die Bestellung Werkstattzeilen existieren, eine Artikelzeile noch nicht gesendet ist, der Benutzer „Send to Workshop“ ausführt und die Rückfrage mit „Nein“ beantwortet
- **THEN** wird keine Zeile verarbeitet, keine Ankunftsabfrage gestellt und keine Werkstattzeile angelegt

#### Scenario: Erster Aufruf ohne Werkstattzeilen
- **WHEN** für die Bestellung keine Werkstattzeilen existieren und der Benutzer „Send to Workshop“ ausführt
- **THEN** erscheint keine zusätzliche Meldung und die Verarbeitung beginnt direkt mit der Ankunftsabfrage der ersten Zeile

