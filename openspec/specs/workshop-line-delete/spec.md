# workshop-line-delete Specification

## Purpose
TBD - created by archiving change workshop-line-delete. Update Purpose after archive.
## Requirements
### Requirement: Werkstattzeilen auf der Seite „Workshop Lines“ löschen
Die Seite „Workshop Lines“ (Page 60338) SHALL das Löschen von Werkstattzeilen erlauben. Werkstattzeilen in den Status „New“ und „Error“ SHALL von Benutzern mit dem Berechtigungssatz „CXW Workshop Delete“ gelöscht werden können.

#### Scenario: Neue Werkstattzeile löschen
- **WHEN** ein Benutzer mit „CXW Workshop Delete“ auf der Seite „Workshop Lines“ eine Werkstattzeile im Status „New“ löscht
- **THEN** ist die Werkstattzeile gelöscht

#### Scenario: Werkstattzeile mit Fehler löschen
- **WHEN** ein Benutzer mit „CXW Workshop Delete“ eine Werkstattzeile im Status „Error“ löscht
- **THEN** ist die Werkstattzeile gelöscht

### Requirement: Geprüfte und verarbeitete Werkstattzeilen sind nicht löschbar
Eine Werkstattzeile im Status „WS checked“ oder „Processed“ SHALL NOT gelöscht werden können, weder über die Seite noch per Code mit ausgeführtem Trigger. Der Versuch SHALL mit einer Fehlermeldung abgebrochen werden, die erklärt, dass Werkstattzeilen nur in den Status „New“ und „Error“ gelöscht werden können. Das automatische Mitlöschen beim Löschen der Einkaufszeile (TabExt 60321) ist davon nicht betroffen; dort bleiben verarbeitete Zeilen wie bisher bestehen.

#### Scenario: Löschen einer geprüften Zeile wird abgelehnt
- **WHEN** ein Benutzer mit „CXW Workshop Delete“ eine Werkstattzeile im Status „WS checked“ löscht
- **THEN** erscheint eine Fehlermeldung und die Werkstattzeile bleibt unverändert bestehen

#### Scenario: Löschen einer verarbeiteten Zeile wird abgelehnt
- **WHEN** ein Benutzer mit „CXW Workshop Delete“ eine Werkstattzeile im Status „Processed“ löscht
- **THEN** erscheint eine Fehlermeldung und die Werkstattzeile bleibt unverändert bestehen

### Requirement: Löschen nur mit eigenem Berechtigungssatz
Das System SHALL einen zuweisbaren Berechtigungssatz „CXW Workshop Delete“ bereitstellen, der alle Rechte von „CXW Workshop All“ enthält und zusätzlich das direkte Löschrecht auf „CXW Workshop Line“ gewährt. Der Berechtigungssatz „CXW Workshop All“ SHALL auf „CXW Workshop Line“ nur ein indirektes Löschrecht gewähren. Benutzer ohne „CXW Workshop Delete“ SHALL Werkstattzeilen auf der Seite „Workshop Lines“ nicht löschen können.

#### Scenario: Benutzer ohne Löschrecht
- **WHEN** ein Benutzer, dem nur „CXW Workshop All“ zugewiesen ist, auf der Seite „Workshop Lines“ eine Werkstattzeile im Status „New“ löscht
- **THEN** wird das Löschen mit einer Berechtigungsmeldung abgelehnt und die Werkstattzeile bleibt bestehen

#### Scenario: Mitlöschen beim Löschen der Bestellung ohne Löschrecht
- **WHEN** ein Benutzer, dem nur „CXW Workshop All“ zugewiesen ist, eine Einkaufszeile löscht, zu der eine Werkstattzeile im Status „New“ existiert
- **THEN** werden Einkaufszeile und Werkstattzeile ohne Berechtigungsfehler gelöscht

#### Scenario: Verarbeitung „nicht echt“ in der Job Queue
- **WHEN** die Verarbeitung (Codeunit 60331) unter einem Benutzer mit „CXW Workshop All“ eine nicht echte Werkstattzeile verarbeitet und dabei die Bestellung löscht
- **THEN** läuft die Verarbeitung ohne Berechtigungsfehler, die verarbeitete Werkstattzeile bleibt bestehen

### Requirement: Einkaufszeile wird beim Löschen zurückgesetzt
Beim Löschen einer Werkstattzeile SHALL das System die zugehörige Einkaufszeile (gleiche Belegart, Belegnummer und Zeilennummer) zurücksetzen: „Sent to Workshop“ SHALL Nein und „Manufacturer Serial No.“ SHALL leer sein. Existiert die Einkaufszeile nicht mehr, SHALL das Löschen der Werkstattzeile ohne Fehler erfolgen.

#### Scenario: Einkaufszeile ist danach wieder offen
- **WHEN** der Benutzer die Werkstattzeile zu Bestellung „B-1“, Zeile 10000 löscht
- **THEN** ist auf der Einkaufszeile „B-1“/10000 „Sent to Workshop“ Nein, „Manufacturer Serial No.“ leer, und die Felder der Zeile sind auf der Bestellung wieder bearbeitbar

#### Scenario: Erneutes Senden nach dem Löschen
- **WHEN** der Benutzer die Werkstattzeile einer Einkaufszeile gelöscht hat und anschließend auf der Bestellung „Send to Workshop“ ausführt
- **THEN** wird die Einkaufszeile wieder zur Verarbeitung angeboten (Ankunftsabfrage) und bei Bestätigung eine neue Werkstattzeile angelegt

#### Scenario: Einkaufszeile existiert nicht mehr
- **WHEN** der Benutzer eine Werkstattzeile löscht, deren Einkaufszeile nicht mehr existiert
- **THEN** wird die Werkstattzeile ohne Fehlermeldung gelöscht

### Requirement: Artikelverfolgung und Seriennr.-Information bleiben erhalten
Beim Löschen einer Werkstattzeile SHALL das System die Seriennummer in der Artikelverfolgung der Einkaufszeile und die Seriennr.-Information (inkl. Herstellernummer) NICHT löschen oder ändern. Ein erneutes „Send to Workshop“ SHALL diese Seriennummer wiederverwenden und keine neue Nummer aus der Nummernserie ziehen.

#### Scenario: Seriennummer wird wiederverwendet
- **WHEN** eine Werkstattzeile mit Seriennummer „SN-0001“ gelöscht und die Einkaufszeile erneut an die Werkstatt gesendet wird
- **THEN** trägt die neue Werkstattzeile die Seriennummer „SN-0001“, und die Seriennr.-Information öffnet sich mit der zuvor erfassten Herstellernummer

### Requirement: Kein Löschen über das Werkstatt-API
Das Werkstatt-API `workshopLines` (Page 60339) SHALL weiterhin kein Löschen erlauben.

#### Scenario: DELETE über das API wird abgelehnt
- **WHEN** die Werkstatt einen DELETE-Aufruf auf eine Werkstattzeile im API `workshopLines` sendet
- **THEN** wird der Aufruf abgelehnt und die Werkstattzeile bleibt bestehen

