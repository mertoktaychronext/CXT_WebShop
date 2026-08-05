# Schwachstellen- und Cleanup-Bericht — SL Chronext Webshop

**Erstellt am:** 2026-08-04
**Durchgeführt als:** Senior-Developer-Review (Code-Cleanup, Sicherheits-/Robustheitsprüfung, UI-Erreichbarkeit)
**Umfang:** Gesamte AL-Codebasis (16 Objekte + 2 neue Page Extensions + 1 neues Permission Set)

Dieser Bericht dokumentiert alle im Review gefundenen Probleme. Wo eine Behebung risikolos und eindeutig war, wurde sie direkt umgesetzt (siehe Spalte "Status"). Bei Punkten, die eine fachliche Entscheidung erfordern, wurde bewusst **nicht** eigenmächtig entschieden — diese sind als "Nur dokumentiert" markiert.

---

## Kritisch

| # | Finding | Datei(en) | Status |
|---|---|---|---|
| K1 | **Fehlende UI-Anbindung für Table Extension 51000** ("SL Country Region"): Die Felder `Sales Price Activated`, `Sales Price Currency Code`, `Taxation Type`, `Delivery Time` existierten in der Tabelle, waren aber über die Benutzeroberfläche nirgends erreichbar — es gab keine Page Extension auf die Standard-Country/Region-Seite. Ohne diese Felder funktioniert "Add all Currencies" nur für zufällig schon befüllte Länder. | `src/PageExtensions/PagExt51000.SLCountryRegionCard.al` | ✅ Behoben (neue Page Extension) |
| K2 | **Fehlende UI-Anbindung für Table Extension 51001** ("SL Sales Price"): Die Felder `Reason Code`, `Comment`, `Remark`, `Recom. Retail Price incl. VAT`, `Strike-Price incl. VAT`, `Country/Region Code`, `Unit Price (LCY)`, `Unit Price (LCY) incl. VAT` waren ebenso nirgends im UI sichtbar/editierbar. **Konkrete Auswirkung:** `Unit Price (LCY)` wird von keiner Prozedur automatisch befüllt — der Preisvergleich in `fnValidate` (Page 51001) verglich de facto immer gegen 0, weil das Feld nirgends gepflegt werden konnte. | `src/PageExtensions/PagExt51001.SLSalesPrices.al` | ✅ Behoben (neue Page Extension) |
| K3 | **Kein Permission Set vorhanden.** Ohne ein zuweisbares Permission Set können normale Benutzer (ohne SUPER-Berechtigung) auf keines der Objekte dieser Extension zugreifen — unabhängig davon, wie gut sie im UI verlinkt sind. | `src/PermissionSets/SLChronWSAll.permissionset.al` | ✅ Behoben (Permission Set `SLChronWSAll` deckt alle Objekte der Extension ab, muss aber noch einer Benutzergruppe zugewiesen werden) |
| K4 | **CSV-Spaltenreihenfolge wurde nicht geprüft** (`EvaluateHeaderRow` in Codeunit 51001): Es wurde nur geprüft, ob jeder Spaltenname irgendwo in der erlaubten Menge vorkommt, nicht ob er an der von `ProcessLine` erwarteten **Position** steht. Eine CSV-Datei mit vertauschten Spalten (z. B. "Variant Code" vor "Item No.") hätte die Prüfung unbemerkt bestanden — die Werte wären aber positionsbasiert falschen Feldern zugewiesen worden (z. B. eine Variantencode-Spalte wäre stillschweigend als Artikelnummer interpretiert worden). Das ist eine stille Datenintegritätslücke, kein Absturz. | `src/Codeunits/Codeunit51001.SLImportSalesPrices.al` | ✅ Behoben (prüft jetzt Anzahl + exakte Reihenfolge) |

## Wichtig

| # | Finding | Datei(en) | Status |
|---|---|---|---|
| W1 | **Seiten 51000/51001/51002 waren nicht über die Business-Central-Suche ("Tell Me") auffindbar** — keine der drei Seiten hatte `UsageCategory`/`ApplicationArea` auf Seitenebene gesetzt. Ein Benutzer, der die exakte URL/den Objektnamen nicht kennt, hätte sie nie gefunden. | `Pag51000`, `Pag51001`, `Pag51002` | ✅ Behoben |
| W2 | **Keine Navigation von der zentralen Arbeitsliste (Page 51001) zu Setup oder Archiv.** Nutzer mussten wissen, dass "General Sales Price Setup" und "Sales Price Archive" überhaupt existieren, um sie separat zu suchen. | `Pag51001.SLSalesPriceCheckingList.al` | ✅ Behoben (neue Navigation-Actions) |
| W3 | **`Message('...'); Error('');`-Antipattern** im `OnValidate`-Trigger von "Accept New Setup" (Table 51001): zeigt eine Meldung an und bricht dann mit einer **leeren** Fehlermeldung ab — erzeugt in modernem AL einen unnötigen leeren Fehlerdialog. | `Tab51001.SLSalesPriceChecking.al` | ✅ Behoben (durch einzelnen aussagekräftigen `Error(...)` ersetzt) |
| W5 | **Toter Code**: leerer, wirkungsloser `OnValidate`-Trigger auf "Stock Price" (Table 51001, kompletter Trigger-Inhalt war bereits im NAV-Original auskommentiert); No-Op-Funktion `CheckEntries` (durch globales `IF (TRUE) THEN EXIT;` bereits wirkungslos) samt drei toten Aufrufen; ~100 Zeilen vollständig auskommentierte Action "Upload Sales Price", die auf die inzwischen gelöschte Codeunit 51000 verwies, samt dadurch verwaister Variablen (`g_recSP2`, `TXT000`, `SalesPriceArchive`, `CountToUpload`). | `Tab51001.SLSalesPriceChecking.al`, `Pag51001.SLSalesPriceCheckingList.al` | ✅ Entfernt/bereinigt |
| W6 | **Hardcodierter Benutzername als Autorisierungsprüfung** (`IF UserId <> 'SGALLIPELLI' THEN ERROR(...)`) fand sich in der jetzt entfernten Action "Upload Sales Price". Anti-Pattern: Berechtigungen gehören in Permission Sets, nicht in hartcodierte Benutzernamen im Code. Da der Code bereits vollständig auskommentiert war, bestand kein akutes Risiko — **wichtig für die Zukunft**: falls die Upload-Funktionalität neu gebaut wird, dieses Muster nicht wiederverwenden. | *(bereits entfernter Code, nur zur Kenntnis)* | 📝 Nur dokumentiert |

## Nice-to-have / offene Punkte (fachliche Entscheidung nötig)

| # | Finding | Empfehlung |
|---|---|---|
| N1 | **`DataClassification = ToBeClassified`** auf nahezu allen Feldern aller sechs Tabellen — das ist ein Platzhalter, keine finale Klassifizierung. Insbesondere `"Last Modified UserID"`/`"Approved By"`/`"User ID"` sollten vermutlich `EndUserIdentifiableInformation` sein (DSGVO-relevant). Nicht eigenmächtig geändert, da dies eine Entscheidung der/des Datenschutzbeauftragten sein sollte. | Vor Produktivsetzung durchgehen und pro Feld final klassifizieren. |
| N2 | **Keine automatisierten Tests** vorhanden (bereits im Entwicklerhandbuch vermerkt). Die Spec `openspec/specs/sales-price-currency-copy/spec.md` bietet 10 fertige Testszenarien als Ausgangspunkt. | Testcodeunit auf Basis der Spec erstellen. |
| N3 | **Codeunit 51001 (automatisierter Dateiimport) ist an keiner Stelle terminiert** — kein Job-Queue-Eintrag, kein Trigger. Der Baustein ist vollständig implementiert, aber isoliert. | Falls benötigt: Job-Queue-Eintrag ergänzen (siehe Skill `building-bc-job-queues`), sonst als bewusst zurückgestellt dokumentieren. |
| N4 | **Keine Validierung, dass die Artikelnummer beim CSV-Import tatsächlich existiert** (Xmlport setzt das Feld direkt, ohne `Validate()` — die vorhandene `TableRelation` wird dadurch nicht durchgesetzt). Ein Tippfehler in der CSV fällt erst bei "Validate" auf, nicht bereits beim Import. | Optional: `TestField`/`Get`-Prüfung auf Item direkt im Xmlport ergänzen, falls frühere Fehlermeldung gewünscht ist. |
| N5 | **Keine Größenbeschränkung/Row-Limit beim CSV-Import.** Eine sehr große Datei würde vollständig in eine temporäre Tabelle eingelesen, bevor überhaupt eine Prüfung stattfindet (Codeunit 51001, `ProcessFile`). Bei normalem Nutzungsmuster (interner Preis-Import) ist das Risiko gering, für einen öffentlich zugänglichen Upload-Kanal wäre eine Grenze sinnvoll. | Falls dieser Kanal je extern zugänglich gemacht wird: Zeilenlimit/Dateigrößenprüfung ergänzen. |
| N6 | **Keine Sperre gegen parallele Imports/Verarbeitung.** `WriteSalesPrices` sperrt die Ziel-Tabelle einmalig zu Beginn (`LockTable()`), zwei gleichzeitig laufende Importe könnten sich dennoch überschneiden, da der automatisierte Dateiimport (Codeunit 51001) und der manuelle CSV-Import (Xmlport 51000) unabhängig voneinander auf dieselbe Zwischenablage-Tabelle wirken können. | Bei produktivem Parallelbetrieb beider Importwege genauer betrachten. |

---

## Zusammenfassung der durchgeführten Änderungen

**Neue Dateien:**
- `src/PageExtensions/PagExt51000.SLCountryRegionCard.al`
- `src/PageExtensions/PagExt51001.SLSalesPrices.al`
- `src/PermissionSets/SLChronWSAll.permissionset.al`

**Geänderte Dateien:**
- `src/Pages/Pag51000.SLGeneralSalesPriceSetup.al` — UsageCategory/ApplicationArea ergänzt
- `src/Pages/Pag51001.SLSalesPriceCheckingList.al` — Navigation-Actions, UsageCategory, toter Code entfernt, Fehlerbehandlung ergänzt
- `src/Pages/Pag51002.SLSalesPriceArchive.al` — UsageCategory/ApplicationArea ergänzt
- `src/Tables/Tab51001.SLSalesPriceChecking.al` — toter Trigger entfernt, Error-Antipattern bereinigt
- `src/Codeunits/Codeunit51001.SLImportSalesPrices.al` — CSV-Spaltenreihenfolge-Bugfix

**Wichtiger Hinweis:** Die beiden neuen Page Extensions enthalten Annahmen über Standard-Seitennamen (`"Countries/Regions"`, `"Sales Prices"`), die in dieser Umgebung nicht gegen ein vollständiges BC-Symbolpaket verifiziert werden konnten. Bitte vor dem ersten Compile in VS Code prüfen (siehe TODO-Kommentare in den jeweiligen Dateien).
