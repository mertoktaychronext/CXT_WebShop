## Context

- **Heute** (Codeunit 60329): Die Aktion "Upload Sales Price" auf Page 60322 ruft für jede freigegebene Prüfzeile `WriteBackAndArchive` und danach `CreateExternalInterfaceFile` auf. Letztere baut das JSON per RecordRef über alle Felder von "Sales Price" (BC-Feldnamen inkl. System-Felder) und hängt `"CXW Country Code"` an. `SendToApiInterface` sendet sofort und legt **danach** einen "Data Export Entry" (`SALESPRICE`) mit Endstatus an. Jede Zeile wird archiviert, egal welches Land.
- **Zielformat**: stammt aus NAV-Codeunit 82001. Dort wurden alle Felder von Tabelle 7002 in camelCase umgewandelt, teils nach Page 88006 benannt. `"profit"` ist die Umwandlung von `"Profit %"`, also ein Prozentwert.
- **ChronextBC-Verhalten** (Version 1.0.0.1):
  - `"Data Export Entry".OnInsert` setzt `Status := "Waiting to Process"`, **ohne Ausnahme**.
  - "Data Export Mgt." (50102) filtert **nur** auf `Status = "Waiting to Process"`, nicht auf `Destination Code`. Er sendet über "Data Export API Sender", der `"Data Export API Setup".Get("Destination Code")` braucht. Für `SALESPRICE` gibt es kein solches Setup.
  - Enum 50100 "Data Export Statuses" ist `Extensible = true`. Page 50108 "Data Export Entries" ist erweiterbar.
- **Page 60322** führt in `OnOpenPage` `Rec.DeleteAll()` auf der echten Tabelle aus. Prüfzeilen existieren also nur bis zum nächsten Öffnen der Page.
- **"Sales Price" kennt kein Land.** Länder mit gleicher Währung (z. B. DE und AT mit leerer Währung) schreiben in denselben "Sales Price"-Datensatz.
- **Vorgabe:** Das Archiv hält künftig nur noch den DE-Preis. Quellzeilen ohne Land werden nicht gesendet. "Data Export Entry" wird **nicht** per Tabellenerweiterung um Preisfelder ergänzt, sondern verweist nur per Schlüssel auf eine eigene Tabelle dieser Extension.

## Goals / Non-Goals

**Goals:**
- Preisstand jedes Landes zum Zeitpunkt der Freigabe dauerhaft in einer eigenen Tabelle.
- Versand entkoppelt über die Aufgabenwarteschlange, mit dem "Data Export Entry" als Warteschlange (nur Schlüssel und Status).
- JSON im vereinbarten Format (30 Schlüssel, feste Reihenfolge).
- Automatische Wiederholung bis zu einem einstellbaren Maximum, danach Stillstand bis zum manuellen Eingriff.
- Kein Versand und keine Statusänderung durch den ChronextBC-Job.

**Non-Goals:**
- Keine Tabellenerweiterung auf "Data Export Entry".
- Keine Änderung an HTTP-Request, Authentifizierung (inkl. SigV4), HTTP-Log oder "CXW API Interface Setup".
- Keine Bereinigung bereits archivierter Nicht-DE-Zeilen, sie bleiben stehen.
- Keine Aufbewahrungsregel (Retention Policy) für "CXW Sales Price Export" in diesem Change.
- Kein Anlegen des Job-Queue-Eintrags per Install- oder Upgrade-Codeunit.
- Keine Behebung des `DeleteAll()` in `OnOpenPage` von Page 60322.

## Decisions

### 1. Eigene Tabelle "CXW Sales Price Export" (60320) als Preisspeicher pro Land
Bei der Freigabe wird pro Prüfzeile genau ein Datensatz eingefügt:

| Feld | Typ | Quelle |
|---|---|---|
| 1 `"CXW Entry No."` | BigInteger, AutoIncrement, PK | – |
| 2 `"CXW Item No."` | Code[20] | Prüfzeile |
| 3 `"CXW Country Code"` | Code[10] | Prüfzeile |
| 4 `"CXW Currency Code"` | Code[10] | Prüfzeile |
| 5 `"CXW Starting Date"` / 6 `"CXW Starting Time"` | Date / Time | Prüfzeile |
| 7 `"CXW Ending Date"` / 8 `"CXW Ending Time"` | Date / Time | Prüfzeile |
| 9 `"CXW Unit Price"` | Decimal | Prüfzeile `"CXW Stock Price"` |
| 10 `"CXW Unit Price (LCY)"` | Decimal | berechnet bei Freigabe (`ResolveUnitPriceLCY`) |
| 11 `"CXW Non Stock Price"` | Decimal | Prüfzeile |
| 12 `"CXW Strike Price"` | Decimal | Prüfzeile |
| 13 `"CXW Recom. Retail Price"` | Decimal | Prüfzeile |
| 14 `"CXW Exchange Rate Amount"` / 15 `"CXW Exchange Rate Date"` | Decimal / Date | Prüfzeile |
| 16 `"CXW Reason Code"` | Enum "CXW Sales Price Reason Code" | Prüfzeile |
| 17 `"CXW Comment"` | Text[250] | Prüfzeile |
| 18 `"CXW Remark"` | Text[150] | Prüfzeile |
| 19 `"CXW Last Modified UserID"` / 20 `"CXW Last Modified Date"` | Code[50] / DateTime | Prüfzeile |
| 21 `"CXW Sales Price SystemId"` | Guid | `SystemId` des geschriebenen "Sales Price" |
| 22 `"CXW Data Export Entry No."` | BigInteger | Rückverweis auf den erzeugten "Data Export Entry" |
| 23 `"CXW Export Status"` | FlowField `lookup("Data Export Entry".Status where("Entry No." = field("CXW Data Export Entry No.")))` | nur Anzeige |

Schlüssel: PK `"CXW Entry No."`, zusätzlich `"CXW Item No.", "CXW Country Code", "CXW Currency Code"`. Freigabezeitpunkt und -benutzer kommen aus `SystemCreatedAt` und `SystemCreatedBy`.

- *Warum eigene Tabelle:* Das Archiv hält nur noch DE. Eine Tabellenerweiterung auf "Data Export Entry" ist nicht gewünscht. Die Prüfzeile verschwindet mit dem `DeleteAll()`. Nur eine eigene Tabelle hält den Preisstand pro Land, bis der Job gelaufen ist, und danach als Nachweis.
- *Warum Preis LCY schon bei der Freigabe:* Der Wert ist dann eingefroren. Der Fallback-Wechselkurs hängt nicht vom Zeitpunkt des Joblaufs ab.
- *Warum `SystemId` statt RecordId des "Sales Price":* `GetBySystemId` ist stabil gegen Umbenennungen des Schlüssels, z. B. ein geändertes Startdatum.
- *Alternative:* Das Archiv weiter für alle Länder befüllen und nur die Ansicht filtern. Das widerspricht der Vorgabe. Verworfen.
- *Alternative:* Das fertige JSON bei der Freigabe als Payload speichern. Die Preise wären dann nicht filterbar, und der Job würde nichts mehr generieren. Verworfen.

Dazu kommt Page 60320 "CXW Sales Price Export Entries" (List, nicht editierbar) mit allen Feldern, Drilldown auf den "Data Export Entry" und einer Navigation von Page 60322 dorthin.

### 2. "Data Export Entry" trägt nur Schlüssel und Status
Beim Freigeben: `Insert(true)` (setzt `Waiting to Process`), danach in derselben Transaktion `Status := "CXW Pending"` und `Modify(true)`, ohne `Commit` dazwischen. Belegt werden nur `Destination Code` = `SALESPRICE`, `Payload Format` = JSON, `FileName` = `SalesPrice_<Item>_<Currency>_<Country>.json` und `Source Record ID` = RecordId des "CXW Sales Price Export"-Datensatzes. Danach wird `"CXW Data Export Entry No."` im Exportdatensatz gesetzt.
- *Warum `CXW Pending` (enumextension 60300, Wert 60300):* Der ChronextBC-Job würde `Waiting to Process`-Einträge an sich ziehen, am fehlenden Setup scheitern und sie ohne Versand auf `Error` setzen.
- *Alternativen* (`Waiting to Process` mit Wiederholung, "Data Export API Setup" `SALESPRICE`, eigene Warteschlangentabelle statt "Data Export Entry") wurden verworfen, siehe Diskussion: Das verbraucht Versuche, SigV4 fehlt, oder es widerspricht dem Wunsch nach "Data Export Entry" als Matrix.

### 3. Archiv nur für das Archivland
Neues Setup-Feld `17 "CXW Archive Country Code"` (Code[10], `TableRelation = "Country/Region"`, `InitValue = 'DE'`). `WriteBackAndArchive` archiviert eine Zeile nur, wenn `"CXW Country Code"` = Archivland. Die Versionslogik bleibt unverändert.
- Ist das Feld leer (bestehender Setup-Datensatz nach dem Upgrade), bricht "Release Sales Prices" mit `TestField` ab, bevor eine Zeile verarbeitet wird.
- *Warum einstellbar statt fest `'DE'`:* keine feste Landeskennung im Code, Test in anderen Mandanten möglich.

### 4. Payload wird im Job gebaut, beim ersten Versuch
Der Job holt über `Source Record ID` (RecordRef → `SetTable`) den Exportdatensatz, dazu "Sales Price" per `GetBySystemId` und den Artikel. Er baut das JSON, wenn `Payload` noch keinen Wert hat, und speichert es mit `SetPayload`. Wiederholungen senden die gespeicherte Payload unverändert.

### 5. Feldherkunft im JSON

| Schlüssel | Quelle | Format |
|---|---|---|
| `itemNo`, `variantCode` | Artikel: "Old Item No." bzw. "Old Variant Code", sonst Artikelnr. bzw. Variantencode des "Sales Price", ohne Variante die Artikelnr. (wie Verfügbarkeitsexport, Codeunit 60347 `GetStockKeys`) | Text |
| `currencyCode`, `countryRegionCode` | Export | Text |
| `salesType`, `salesCode` | "Sales Price" | Ordinalzahl als Text (`"2"`) / Text |
| `startingDate`, `endingDate` | Export | `Format(…, 0, 9)`, `""` bei `0D` |
| `unitOfMeasureCode`, `minimumQuantity` | "Sales Price" | Text / Dezimal |
| `unitPrice` | Export `"CXW Unit Price"` | Dezimal |
| `priceIncludesVat`, `allowInvoiceDisc`, `allowLineDisc` | "Sales Price" | Boolean |
| `vatBusPostingGrPrice` | "Sales Price" | Text |
| `id` | Export `"CXW Sales Price SystemId"` | `Format(Guid)` → `{…}` in Großbuchstaben |
| `remark`, `comment` | Export | Text |
| `nonStockPrice`, `strikePriceInclVat`, `recomRetailPriceInclVat`, `unitPriceLcy` | Export | Dezimal |
| `lastModifiedUserID` | Export | Text |
| `lastModifiedDate` | Export | `Format(…, 0, 9)`, `""` bei `0DT` |
| `reasonCode` | Export | **Name** des Enum-Werts, nie leer |
| `startingTime`, `endingTime` | Export | `Format(…, 0, 9)`, `""` bei `0T` |
| `profit` | berechnet (Entscheidung 6) | Dezimal, Prozent |
| `unitCost` | `Item."Unit Cost"` | Dezimal |
| `vatProdPostingGroup` | `Item."VAT Prod. Posting Group"` | Text |

Reihenfolge wie in der Spec. Der AL-`JsonObject` behält die Einfügereihenfolge bei, Dezimalwerte erscheinen als `0` statt `0.0`. Wird "Sales Price" oder der Artikel nicht gefunden, wird der Eintrag auf `Error` gesetzt und kein Versand versucht.

### 6. `unitCost` und `profit`
```
unitCost = Item."Unit Cost"                                   (LCY)
vatPct   = VAT Posting Setup(Sales Price."VAT Bus. Posting Gr. (Price)", Item."VAT Prod. Posting Group")."VAT %"
           (0, falls nicht vorhanden)
netLcy   = unitPriceLcy / (1 + vatPct/100)
profit   = Round((netLcy − unitCost) / netLcy × 100, 0.01)    // 0, wenn netLcy = 0
```
Die Berechnung erfolgt beim ersten Versuch im Job (Stand Artikel zu diesem Zeitpunkt).

### 7. Auswahl und Wiederholung im Job
- Filter: `Destination Code = SALESPRICE` und (`Status = CXW Pending` oder `Status = Error` und `Attempt Count < Max`). Max kommt aus `16 "CXW Max. Export Attempts"` (`InitValue = 3`, `MinValue = 1`); `0` wird wie `3` behandelt.
- Jeder Eintrag wird isoliert verarbeitet (Worker-Codeunit per `Codeunit.Run` oder `[TryFunction]`), mit `Commit()` nach jedem Eintrag. Ein Laufzeitfehler setzt den Eintrag auf `Error`, erhöht `Attempt Count` und setzt `Last Attempt At` und `Error Message`.
- `SendToApiInterface` aktualisiert den übergebenen Eintrag (Status, Versuche, Zeitpunkte, Fehlertext), statt einen neuen anzulegen. Das HTTP-Log verweist weiter auf die `Entry No.`.
- Ist der Export deaktiviert oder der API-Code leer, endet der Job ohne Fehler und ohne Änderung.
- Der Job-Lauf endet **nicht** mit `Error`, wenn einzelne Einträge scheitern. Sonst würde der wiederkehrende Job-Queue-Eintrag nach seinen eigenen Versuchen stehen bleiben.

### 8. Freigabe-Aktion "Release Sales Prices" (Page 60322)
- Prüfungen: Setup vorhanden, `"CXW Price Export Active"`, `"CXW API Interface Code"`, `"CXW Archive Country Code"`.
- **Quellzeilen ohne Land** (`"CXW Country Code"` leer) werden vollständig übersprungen: kein Rückschreiben, kein Archiv, kein Exportdatensatz, kein Eintrag. Ihr Exportstatus bleibt unverändert, und sie zählen nicht in der Abschlussmeldung.
  - *Warum auch kein Rückschreiben:* Quellzeile und DE-Zeile (beide ohne Währung) schreiben in denselben "Sales Price"-Datensatz. Die DE-Zeile trägt den auf 10 aufgerundeten Preis, die Quellzeile den ungerundeten. Je nach Verarbeitungsreihenfolge würde die Quellzeile den DE-Preis überschreiben.
  - Gibt es freigegebene Quellzeilen, aber keine einzige freigegebene Länderzeile, bricht die Aktion mit dem Hinweis ab, zuerst "Add all Countries" auszuführen.
- Länderzeilen mit `Accept New Setup` und Status `Not Sent`/`Error` werden verarbeitet. Zeilen mit `Queued` (und Alt-Status `Sent`) nur nach Rückfrage.
- Pro Zeile als eine Einheit über eine Worker-Codeunit per `Codeunit.Run` (mit `Commit()` vor jedem Aufruf): Rückschreiben "Sales Price" → ggf. Archiv → Exportdatensatz → "Data Export Entry" → Rückverweis. Bei Erfolg Status `Queued`, bei Fehler `Error`. Bei einem Fehler entstehen weder Exportdatensatz noch Eintrag, alle Änderungen der Zeile werden zurückgerollt.
  - *Warum nicht `[TryFunction]` wie bisher:* Eine TryFunction rollt Datenbankschreibvorgänge nicht zurück. Ein Fehler nach dem Rückschreiben ließe einen halb geschriebenen Stand zurück, z. B. "Sales Price" geändert, aber kein Exportdatensatz. `Codeunit.Run` rollt die Transaktion der Zeile vollständig zurück.
- Abschlussmeldung: "%1 von %2 Preisen zur Übertragung eingeplant."

### 9. Manuelles Zurücksetzen: Page-Erweiterung auf 50108
`pageextension 60336` bekommt die Aktion "Requeue Sales Price". Sie wirkt nur auf ausgewählte Einträge mit `SALESPRICE` und `Error` und setzt `Status := CXW Pending`, `Attempt Count := 0` und `Error Message := ''`. Die Payload bleibt.

### 10. IDs und Berechtigungen
- Tabelle 60320, Page 60320, Codeunit 60332, enumextension 60300, pageextension 60336, Setup-Felder 16 und 17.
- `CXWChronWSAll`: `tabledata "CXW Sales Price Export" = RIMD`, `table`/`page "CXW Sales Price Export…" = X`, `codeunit "CXW Export Sales Price Job" = X`. "Data Export Entry" hat bereits `RIM`.

## Risks / Trade-offs

- [Kein Job-Queue-Eintrag eingerichtet] → Preise werden freigegeben, aber nie gesendet. Mitigation: Checkliste im Key-User-Handbuch.
- [Archivland im bestehenden Setup leer] → "Release Sales Prices" bricht mit einer klaren Meldung ab. Mitigation: Deploy-Schritt 3.
- [Nicht-DE-Preise nur noch in "CXW Sales Price Export"] → Wer bisher im Archiv nach Länderpreisen gesucht hat, muss die neue Liste nutzen. Mitigation: Navigation von Page 60322, Handbuch.
- [DE ist nicht als Land aktiviert] → Ohne DE-Länderzeile wird kein EUR-Preis mehr in "Sales Price" geschrieben, archiviert oder gesendet, weil die Quellzeile übersprungen wird. Mitigation: Hinweis im Key-User-Handbuch, DE muss "Verkaufspreis aktiviert" haben.
- [Tabelle "CXW Sales Price Export" wächst unbegrenzt] → Aufbewahrungsregel als Folge-Change.
- [Klick auf "Export Data" (Page 50108) bei einem SALESPRICE-Eintrag] → Kein Versand, der Eintrag geht auf `Error` und `Attempt Count` +1. Wiederherstellung per "Requeue Sales Price".
- [Empfänger erwartet noch das alte Format] → Breaking. Mitigation: Abstimmung vor dem Deploy.

## Migration Plan

1. Mit dem Empfänger das neue JSON-Format abstimmen.
2. Neue Version deployen. Der Schema-Sync ist unkritisch (neue Tabelle, neue Felder, neue Enum-Werte).
3. "CXW General Sales Price Setup": "Archive Country Code" auf `DE` setzen, "Max. Export Attempts" prüfen.
4. Job-Queue-Eintrag anlegen: Codeunit 60332, wiederkehrend, Status "Bereit".
5. Rollback: Vorversion deployen. Vorher alle `CXW Pending`-Einträge senden lassen oder auf `Error` setzen. Die neue Tabelle bleibt als Daten erhalten.

## Open Questions

- Die NAV-Dateinamenkonvention wird nicht übernommen. Ob der Empfänger den Dateinamen auswertet, ist mit ihm zu klären.
