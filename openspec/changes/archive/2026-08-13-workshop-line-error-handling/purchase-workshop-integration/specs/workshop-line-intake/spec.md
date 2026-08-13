## ADDED Requirements

### Requirement: Aktion "Send to Workshop" auf der Purchase-Order-Page
Die Purchase-Order-Page SHALL eine Aktion "Send to Workshop" anbieten, die alle Zeilen der aktuellen Purchase Order mit `Type = Item`, `Quantity <> 0` und `Sent to Workshop = false` nacheinander verarbeitet.

#### Scenario: Aktion ohne verarbeitbare Zeilen
- **WHEN** der Nutzer "Send to Workshop" auf einer Purchase Order ausführt, die keine Zeile mit `Type = Item`, `Quantity <> 0` und `Sent to Workshop = false` enthält
- **THEN** es wird keine Workshop Line angelegt und keine Zeile verändert

### Requirement: Ankunftsabfrage pro Zeile
Für jede zu verarbeitende Purchase Line SHALL die Aktion einen Confirm-Dialog anzeigen, der abfragt, ob der Artikel angekommen ist.

#### Scenario: Artikel nicht angekommen
- **WHEN** der Nutzer die Ankunftsabfrage für eine Zeile mit "Nein" beantwortet
- **THEN** wird `Not Arrived` auf der Purchase Line auf `true` gesetzt, keine Workshop Line für diese Zeile angelegt, und die Zeile bleibt für einen späteren Lauf der Aktion verfügbar

#### Scenario: Erneuter Lauf nach vorheriger Nichtankunft
- **WHEN** eine Purchase Line mit `Not Arrived = true` erneut mit "Send to Workshop" verarbeitet und die Ankunftsabfrage diesmal mit "Ja" beantwortet wird
- **THEN** wird `Not Arrived` auf `false` zurückgesetzt und die Zeile normal weiterverarbeitet (Seriennummer-Erfassung, Workshop-Line-Anlage)

### Requirement: Pflichteingabe der Herstellerseriennummer
Bei bestätigter Ankunft SHALL die Aktion die Herstellerseriennummer über einen modalen Eingabedialog abfragen; eine leere Eingabe oder ein Abbruch des Dialogs SHALL dazu führen, dass diese Zeile nicht weiterverarbeitet wird.

#### Scenario: Gültige Seriennummer eingegeben
- **WHEN** der Nutzer im Eingabedialog eine nicht-leere Herstellerseriennummer bestätigt
- **THEN** wird die Seriennummer in `Manufacturer Serial No.` der Purchase Line gespeichert, `Sent to Workshop` auf `true` gesetzt und eine Workshop Line für diese Zeile angelegt

#### Scenario: Leere Eingabe oder Abbruch
- **WHEN** der Nutzer den Eingabedialog ohne Wert bestätigt oder abbricht
- **THEN** wird für diese Zeile eine Fehlermeldung angezeigt, keine Workshop Line angelegt, `Sent to Workshop` bleibt unverändert, und die Verarbeitung der übrigen Zeilen der Purchase Order wird fortgesetzt

### Requirement: Anlage der Workshop Line
Für jede erfolgreich verarbeitete Purchase Line SHALL genau eine Workshop Line mit den Schlüsselfeldern der Purchase Line, `Item No.`, der erfassten Herstellerseriennummer und Status `Neu` angelegt werden.

#### Scenario: Workshop Line übernimmt Purchase-Line-Schlüssel
- **WHEN** eine Workshop Line für eine Purchase Line angelegt wird
- **THEN** stimmen `Document Type`, `Document No.` und `Line No.` der Workshop Line mit denen der Purchase Line überein, und `Item No.` sowie `Manufacturer Serial No.` werden aus der Purchase Line übernommen

### Requirement: Keine doppelte Übertragung
Eine Purchase Line, deren `Sent to Workshop` bereits `true` ist, SHALL von der Aktion "Send to Workshop" nicht erneut verarbeitet werden.

#### Scenario: Bereits übertragene Zeile wird übersprungen
- **WHEN** "Send to Workshop" auf einer Purchase Order mit einer Zeile ausgeführt wird, deren `Sent to Workshop = true` ist
- **THEN** wird für diese Zeile weder die Ankunftsabfrage noch die Seriennummer-Eingabe angezeigt und keine zusätzliche Workshop Line angelegt

### Requirement: Sperrung der Purchase Line nach Übertragung
Eine Purchase Line, deren `Sent to Workshop = true` ist, SHALL auf der Purchase-Order-Subform nicht mehr editierbar sein.

#### Scenario: Übertragene Zeile ist nicht mehr editierbar
- **WHEN** der Nutzer eine Purchase Order öffnet, die eine Zeile mit `Sent to Workshop = true` enthält
- **THEN** sind die Felder dieser Zeile auf der Subform schreibgeschützt und können nicht bearbeitet werden

#### Scenario: Nicht übertragene Zeile bleibt editierbar
- **WHEN** der Nutzer eine Purchase Order öffnet, die eine Zeile mit `Sent to Workshop = false` enthält
- **THEN** bleiben die Felder dieser Zeile wie gewohnt editierbar
