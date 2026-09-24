## Context

- **SalesPrice-Export heute** (Codeunit 60329): `CreateExternalInterfaceFile` baut das JSON, fügt einen Datensatz in "CXW Sales Price Outbound File" (60314) ein (Status `New`) und ruft `SendToApiInterface` auf. Dieses setzt den Status auf `Processed`/`Error` und schreibt über `LogHttpCall` einen "CXW Http Call Log" mit Verweis auf 60314. Die Konfiguration kommt aus "CXW General Sales Price Setup" → "CXW API Interface Setup" (inkl. AWS SigV4, SOAPAction).
- **Verfügbarkeitsexport** (Codeunit 60347): nutzt ChronextBC "Data Export API Setup" für die Konfiguration und legt **nach** erfolgreichem Versand einen "Data Export Entry" mit Status `Processed` an (`CreateProcessedDataExportEntry`).
- **ChronextBC-Verhalten, das beachtet werden muss:**
  - `"Data Export Entry".OnInsert` setzt `Status := "Waiting to Process"` immer, und `"Created At"`, falls leer.
  - "Data Export Mgt." (50102) verarbeitet alle Einträge mit `Status = "Waiting to Process"` und sendet sie über "Data Export API Sender" (50109). Dieser holt die Konfiguration per `"Data Export API Setup".Get("Destination Code")`.
  - Die Aktion "Export Data" auf Page 50108 sendet den markierten Eintrag unabhängig vom Status erneut über denselben Sender.
- Getroffene Entscheidung: **nur das Protokoll** wird umgestellt, die Konfiguration bleibt bei "CXW API Interface Setup".

## Goals / Non-Goals

**Goals:**
- Der SalesPrice-Export protokolliert jeden Übertragungsversuch in "Data Export Entry", auf dieselbe Weise wie der Verfügbarkeitsexport.
- Kein doppelter Versand durch den ChronextBC-Job.
- "CXW Http Call Log" verweist auf den neuen Eintrag; alte Log-Einträge bleiben nutzbar.

**Non-Goals:**
- Kein Wechsel der Konfiguration auf "Data Export API Setup" und keine Nutzung von "Data Export API Sender" oder des Enums "Authorization Type".
- Keine Änderung an JSON-Inhalt, HTTP-Request, Authentifizierung, Export-Status der Prüfzeile, Rückschreiben oder Archiv.
- Keine Migration der Altdaten aus 60314 nach "Data Export Entry".
- Kein Umbau des Verfügbarkeitsexports (z. B. gemeinsamer Helper), siehe Offene Fragen.

## Decisions

### 1. Erst senden, dann "Data Export Entry" mit Endstatus anlegen
`CreateExternalInterfaceFile` baut das JSON und den Dateinamen und ruft `SendToApiInterface(JsonText, FileName, SalesPrice.RecordId)` auf. `SendToApiInterface` sendet, merkt sich das Ergebnis (Erfolg, HTTP-Status, Fehlertext, Request- und Response-Text) und legt **danach** über einen neuen Helper `CreateDataExportEntry(...)` den Eintrag an: `Init` → Felder → `Insert` → `SetPayload` → `Status := Processed/Error` → `Modify`. Erst dann wird `LogHttpCall` mit der neuen `"Entry No."` geschrieben.

- *Warum:* Der Eintrag existiert nur mit Endstatus. Das `Waiting to Process` aus `OnInsert` wird im selben Aufruf überschrieben, bevor committet wird, also sieht der ChronextBC-Job es nie. Das entspricht dem Muster in Codeunit 60347.
- *Alternative:* wie bisher zuerst einfügen und dann nach dem Senden ändern. Dann stünde der Eintrag während des HTTP-Aufrufs (bis 30 s) im Status `Waiting to Process`. Bei einem Commit in einer Subscriber-Kette wäre ein doppelter Versand möglich. Verworfen.
- *Laufzeitfehler vor dem Senden* (Setup fehlt, `TestField`): Wie heute bricht die Aktion ab und es entsteht kein Eintrag. Das entspricht dem bisherigen Verhalten, weil die Seite den Aufruf nicht kapselt und dabei alles zurückgerollt wird.

### 2. Feldbelegung "Data Export Entry"
| Feld | Wert |
|---|---|
| `Destination Code` | `SALESPRICE` (Label, `Locked = true`) |
| `Payload Format` | `JSON` |
| `Payload` | JSON-Text über `SetPayload` |
| `FileName` | `SalesPrice_<Item No.>_<Currency Code>_<Country Code>.json`, wie bisher |
| `Source Record ID` | `SalesPrice.RecordId()` (zurückgeschriebener Standard-Verkaufspreis) |
| `Status` | `Processed` bei Erfolg, sonst `Error` |
| `Attempt Count` | 1 |
| `Last Attempt At` | `CurrentDateTime` |
| `Processed At` | nur bei Erfolg |
| `Error Message` | `HTTP <code>: <response>` bzw. Netzwerkfehlertext, gekürzt auf `MaxStrLen` |

- *Warum `SALESPRICE` statt eines echten Setup-Codes:* Es gibt keinen "Data Export API Setup"-Datensatz dafür. Klickt jemand auf Page 50108 bei einem SalesPrice-Eintrag auf "Export Data", schlägt `"Data Export API Setup".Get` im ChronextBC-Sender fehl. Der Eintrag bekommt dann einen Error-Log und einen höheren Versuchszähler, **ohne** dass ein zweiter, anders authentifizierter Request rausgeht. Das ist das gewünschte, sichere Verhalten.
- *Source Record ID auf "Sales Price" statt auf die Prüfzeile:* Die Signatur von `CreateExternalInterfaceFile` bleibt unverändert. Das Land steht in Dateiname und Payload.

### 3. HTTP-Log verweist auf "Data Export Entry"
`LogHttpCall` erhält statt des Outbound-Datensatzes die `Entry No.` des "Data Export Entry" und setzt `"CXW Source Table No." := Database::"Data Export Entry"`. Die `TableRelation` von `"CXW Source Entry No"` (Tab 60302) bekommt einen weiteren Zweig `if ("CXW Source Table No." = const(50103)) "Data Export Entry"."Entry No."`. Der Zweig für 60314 bleibt für Alt-Einträge bestehen.
- `"Entry No."` ist BigInteger, `"CXW Source Entry No"` ist Integer. Das ist dieselbe Konstellation wie bisher bei 60314 (auch BigInteger) und daher unkritisch.

### 4. Tabelle 60314 auf Obsolete Pending statt löschen
`ObsoleteState = Pending`, `ObsoleteReason = 'Replaced by ChronextBC table "Data Export Entry" (Destination Code SALESPRICE).'`, `ObsoleteTag = '27.0.0.3'`.
- *Warum:* Eine PTE-Tabelle direkt zu löschen würde beim Schema-Sync ihre Daten und die Relation der Alt-Logs verlieren. Die Entfernung (`Removed`) folgt in einem späteren Release. Die Rechte im Permission Set bleiben bis dahin bestehen.
- Enum 60333 "CXW Ext Interface File Status" bleibt, weil "CXW Sales Price Inbound File" (60315) es weiter nutzt.

### 5. Berechtigungen
`CXWChronWSAll`: `tabledata "Data Export Entry" = RIM` und `table "Data Export Entry" = X`. Das ist analog zu `CXWWorkshopAll`, dort aber ohne `D`, weil der Export keine Einträge löscht.

## Risks / Trade-offs

- [Key User klickt auf Page 50108 bei einem SalesPrice-Fehlereintrag auf "Export Data"] → Es geht kein Request raus (kein Setup `SALESPRICE`), aber der Eintrag erhält einen ChronextBC-Error-Log. Mitigation: Im Key-User-Handbuch festhalten, dass Wiederholungen nur über "Upload Sales Price" laufen.
- [Jemand legt später ein "Data Export API Setup" mit Code `SALESPRICE` an] → Dann würde "Export Data" tatsächlich senden, allerdings ohne SigV4. Mitigation: Hinweis in der Entwickler-Doku, dass dieser Code reserviert ist.
- [Obsolete-Pending-Warnungen (AL0432) beim Kompilieren, weil 60302 und das Permission Set noch auf 60314 verweisen] → Die Warnungen sind so gewollt und werden mit der späteren Entfernung behoben.
- [Abhängigkeit zu ChronextBC wächst] → Die Abhängigkeit ist in `app.json` bereits vorhanden. Wird ChronextBC ersetzt, müssen dann zwei Exporte angepasst werden statt einem.

## Migration Plan

1. Neue Version mit Obsolete-Pending-Tabelle deployen. Der Schema-Sync ist unkritisch, weil keine Tabelle oder Feld entfernt wird.
2. Altdaten in 60314 bleiben lesbar (über Tabellenansicht oder Alt-Logs). Es findet keine Migration statt.
3. Rollback: Vorversion deployen. Neue "Data Export Entry"-Datensätze mit `SALESPRICE` bleiben als reine Protokolldaten in ChronextBC liegen und haben keinen Einfluss.

## Open Questions

- Soll auf Page 60322 (Checking List) eine Aktion "Export Entries" ergänzt werden, die Page 50108 gefiltert auf `SALESPRICE` öffnet? Das ist nicht Teil dieses Changes und kann bei Bedarf ergänzt werden.
- Sollen SalesPrice- und Verfügbarkeitsexport später einen gemeinsamen Helper zum Anlegen von "Data Export Entry" nutzen? Das ist bewusst ausgeklammert, um den Verfügbarkeitsexport nicht anzufassen.
