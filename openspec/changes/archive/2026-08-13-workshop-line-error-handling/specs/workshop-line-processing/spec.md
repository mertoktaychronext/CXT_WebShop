## MODIFIED Requirements

### Requirement: Protokollierung von Verarbeitungsfehlern
Tritt bei der Verarbeitung einer Workshop Line ein Fehler auf, SHALL der Fehlertext im Feld `Last Error` der betroffenen Workshop Line gespeichert und der Status der Workshop Line auf `Error` gesetzt werden. Erfolgt danach eine erneute, erfolgreiche Verarbeitung derselben Workshop Line, SHALL `Last Error` geleert werden.

#### Scenario: Fehlertext und Status werden bei einem Fehler gesetzt
- **WHEN** die Verarbeitung einer Workshop Line mit Status `WS geprüft` mit einem Fehler abbricht
- **THEN** enthält `Last Error` dieser Workshop Line nach dem Lauf den aufgetretenen Fehlertext, und der Status der Workshop Line ist `Error`

#### Scenario: Last Error wird bei erfolgreicher Wiederverarbeitung geleert
- **WHEN** eine Workshop Line mit Status `Error` und gefülltem `Last Error` manuell auf Status `WS geprüft` zurückgesetzt und in einem folgenden Lauf erfolgreich verarbeitet wird
- **THEN** enthält `Last Error` dieser Workshop Line nach dem Lauf keinen Text mehr, und der Status ist `Verarbeitet`

## ADDED Requirements

### Requirement: Statuswechsel auf Error nur aus WS geprüft
Ein Statuswechsel einer Workshop Line auf `Error` SHALL nur zulässig sein, wenn der bisherige Status `WS geprüft` war. Jeder Versuch, den Status aus einem anderen Ausgangsstatus (`Neu` oder `Verarbeitet`) auf `Error` zu setzen, SHALL mit einem Fehler abgelehnt werden — unabhängig davon, ob die Änderung intern oder über die externe Workshop-API erfolgt.

#### Scenario: Wechsel aus WS geprüft auf Error ist erlaubt
- **WHEN** die Verarbeitung einer Workshop Line mit Status `WS geprüft` fehlschlägt
- **THEN** wird der Status der Workshop Line erfolgreich auf `Error` gesetzt

#### Scenario: Wechsel aus Neu auf Error wird blockiert
- **WHEN** versucht wird, den Status einer Workshop Line mit Status `Neu` direkt auf `Error` zu setzen
- **THEN** wird die Änderung mit einem Fehler abgelehnt und der Status bleibt `Neu`

#### Scenario: Rückkehr von Error zu WS geprüft bleibt möglich
- **WHEN** eine Workshop Line mit Status `Error` manuell auf Status `WS geprüft` zurückgesetzt wird
- **THEN** wird die Änderung zugelassen, damit die Zeile beim nächsten Job-Queue-Lauf erneut verarbeitet werden kann
