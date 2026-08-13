## ADDED Requirements

### Requirement: Job-Queue-Verarbeitung geprüfter Zeilen
Das System SHALL eine Job-Queue-fähige Codeunit bereitstellen, die alle Workshop Lines mit Status `WS geprüft` verarbeitet.

#### Scenario: Lauf ohne offene Zeilen
- **WHEN** die Verarbeitung ausgeführt wird und keine Workshop Line mit Status `WS geprüft` existiert
- **THEN** wird keine Zeile verändert und der Lauf endet ohne Fehler

### Requirement: Wareneingang bei bestätigter Echtheit
Bei `Genuine = true` SHALL die Verarbeitung für die zugehörige Purchase Order ausschließlich den Wareneingang buchen (keine Rechnung).

#### Scenario: Erfolgreicher Wareneingang
- **WHEN** eine Workshop Line mit Status `WS geprüft` und `Genuine = true` verarbeitet wird
- **THEN** wird für die zugehörige Purchase Line `Qty. to Receive` auf die Bestellmenge gesetzt, ausschließlich der Wareneingang gebucht (kein Invoice), und die Workshop Line erhält Status `Verarbeitet`

### Requirement: Übernahme der Attribute in Standard-Artikelattribute
Bei `Genuine = true` SHALL die Verarbeitung befüllte Attributfelder der Workshop Line in die BC-Standard-Artikelattribute des zugehörigen Artikels übernehmen, über eine zentrale, austauschbare Zuordnung Attributfeld → Attributname.

#### Scenario: Übernahme befüllter Attribute
- **WHEN** eine Workshop Line mit `Genuine = true` verarbeitet wird und `Attribute 1` einen Wert enthält
- **THEN** wird für den zugehörigen Artikel ein Item-Attribute-Value-Mapping mit dem zugeordneten Attributnamen und dem Wert von `Attribute 1` angelegt oder aktualisiert; fehlende Item-Attribute oder -Values werden dabei automatisch als Typ Text angelegt

#### Scenario: Leere Attributfelder werden übersprungen
- **WHEN** eine Workshop Line mit `Genuine = true` verarbeitet wird und `Attribute 5` leer ist
- **THEN** wird für `Attribute 5` kein Item-Attribute-Value-Mapping angelegt oder verändert

### Requirement: Stornierung bei widerlegter Echtheit
Bei `Genuine = false` SHALL die Verarbeitung die zugehörige Purchase Order stornieren (löschen, ggf. nach Reopen), sofern noch kein Wareneingang gebucht wurde.

#### Scenario: Stornierung im Standardfall
- **WHEN** eine Workshop Line mit Status `WS geprüft` und `Genuine = false` verarbeitet wird und die zugehörige Purchase Order genau eine Purchase Line hat
- **THEN** wird die Purchase Order gelöscht, die Workshop Line bleibt bestehen und erhält Status `Verarbeitet`

### Requirement: Fehlerisolation pro Zeile
Ein Fehler bei der Verarbeitung einer Workshop Line SHALL die Verarbeitung der übrigen Workshop Lines im selben Lauf nicht verhindern.

#### Scenario: Eine fehlerhafte Zeile blockiert andere Zeilen nicht
- **WHEN** im selben Lauf eine Workshop Line beim Verarbeiten einen Fehler auslöst (z. B. fehlgeschlagene Buchung) und eine weitere Workshop Line fehlerfrei verarbeitbar ist
- **THEN** wird die fehlerfreie Workshop Line erfolgreich verarbeitet und erhält Status `Verarbeitet`, während die fehlerhafte Workshop Line ihren bisherigen Status behält

### Requirement: Protokollierung von Verarbeitungsfehlern
Tritt bei der Verarbeitung einer Workshop Line ein Fehler auf, SHALL der Fehlertext im Feld `Processing Error` der betroffenen Workshop Line gespeichert werden.

#### Scenario: Fehlertext wird gespeichert
- **WHEN** die Verarbeitung einer Workshop Line mit einem Fehler abbricht
- **THEN** enthält `Processing Error` dieser Workshop Line nach dem Lauf den aufgetretenen Fehlertext, und der Status der Workshop Line bleibt `WS geprüft`

### Requirement: Löschverhalten der Workshop Line
Eine Workshop Line im Status `Verarbeitet` SHALL nicht gelöscht werden, wenn die zugehörige Purchase Line gelöscht wird. Eine Workshop Line im Status `Neu` oder `WS geprüft` SHALL beim Löschen der zugehörigen Purchase Line automatisch mitgelöscht werden.

#### Scenario: Verarbeitete Workshop Line bleibt nach PO-Löschung bestehen
- **WHEN** eine Purchase Line mit zugehöriger Workshop Line im Status `Verarbeitet` gelöscht wird (z. B. im Rahmen der Stornierung)
- **THEN** bleibt die Workshop Line mit Status `Verarbeitet` bestehen

#### Scenario: Offene Workshop Line wird mitgelöscht
- **WHEN** eine Purchase Line mit zugehöriger Workshop Line im Status `Neu` oder `WS geprüft` gelöscht wird
- **THEN** wird die zugehörige Workshop Line ebenfalls gelöscht
