## ADDED Requirements

### Requirement: Custom API für Workshop Line
Das System SHALL eine Custom API v1.0 (`workshopLine` / `workshopLines`) auf Basis der Tabelle "Workshop Line" bereitstellen, über die ein externer Workshop offene Zeilen lesen und Prüfergebnisse zurückschreiben kann.

#### Scenario: Workshop liest offene Zeilen
- **WHEN** der Workshop einen GET-Request auf `workshopLines` mit Filter `status eq 'Neu'` ausführt
- **THEN** liefert die API alle Workshop Lines mit Status `Neu` inklusive Schlüsselfeldern, `itemNo`, `manufacturerSerialNo`, `status`, `genuine`, `attribute1`–`attribute10` und `systemId`

### Requirement: Rückschreiben des Prüfergebnisses
Der Workshop SHALL über PATCH die Felder `attribute1`–`attribute10`, `genuine` und `status` einer Workshop Line schreiben können.

#### Scenario: Workshop schreibt Prüfergebnis zurück
- **WHEN** der Workshop eine Workshop Line per PATCH mit befüllten Attributfeldern, `genuine = true` und `status = 'WS geprüft'` aktualisiert
- **THEN** werden die Attributfelder, das Genuine-Flag und der Status auf der Workshop Line übernommen und `Checked At` wird auf den aktuellen Zeitstempel gesetzt

### Requirement: Kein Insert/Delete über die API
Die API SHALL das Anlegen und Löschen von Workshop Lines durch den Workshop verhindern.

#### Scenario: Insert-Versuch über die API
- **WHEN** der Workshop einen POST-Request zum Anlegen einer neuen Workshop Line über die API sendet
- **THEN** lehnt die API die Anfrage mit einem Fehler ab und es wird keine Workshop Line angelegt

#### Scenario: Delete-Versuch über die API
- **WHEN** der Workshop einen DELETE-Request auf eine bestehende Workshop Line über die API sendet
- **THEN** lehnt die API die Anfrage mit einem Fehler ab und die Workshop Line bleibt bestehen

### Requirement: Gesperrte Statusrückschritte
Die API SHALL verhindern, dass der Status einer Workshop Line von `WS geprüft` zurück auf `Neu` oder von `Verarbeitet` auf einen anderen Status geändert wird.

#### Scenario: Rückschritt von "WS geprüft" auf "Neu" wird blockiert
- **WHEN** der Workshop eine Workshop Line im Status `WS geprüft` per PATCH auf Status `Neu` zurücksetzt
- **THEN** lehnt die API die Änderung mit einem Fehler ab und der Status bleibt `WS geprüft`

#### Scenario: Statuswechsel weg von "Verarbeitet" wird blockiert
- **WHEN** der Workshop eine Workshop Line im Status `Verarbeitet` per PATCH auf einen anderen Status ändert
- **THEN** lehnt die API die Änderung mit einem Fehler ab und der Status bleibt `Verarbeitet`

### Requirement: Setzen von "Checked At" bei Statuswechsel
Beim Wechsel des Status einer Workshop Line auf `WS geprüft` SHALL das Feld `Checked At` automatisch auf den aktuellen Zeitpunkt gesetzt werden, unabhängig davon, ob die Änderung über die API oder innerhalb von BC erfolgt.

#### Scenario: Checked At wird beim Statuswechsel gesetzt
- **WHEN** der Status einer Workshop Line von `Neu` auf `WS geprüft` wechselt
- **THEN** enthält `Checked At` nach der Änderung den aktuellen Zeitstempel
