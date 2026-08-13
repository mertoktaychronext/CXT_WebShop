## 1. Datenmodell

- [x] 1.1 Enum 60337 "CXW Workshop Line Status" (`src/Enums/Enum60337.CXWWorkshopLineStatus.al`): neuen Wert `3; "Error"` mit Caption 'Error' ergänzen.
- [x] 1.2 Tabelle 60318 "CXW Workshop Line" (`src/Tables/Tab60318.CXWWorkshopLine.al`): Feld 23 von `"CXW Processing Error"` zu `"CXW Last Error"` umbenennen, Caption zu 'Last Error' anpassen (Editable = false, Text[250] unverändert).
- [x] 1.3 `OnModify`-Trigger in Tab60318 um Regel ergänzen: Wechsel auf `"CXW Status"::Error` nur zulassen, wenn `xRec."CXW Status" = "CXW Status"::"WS checked"` war; sonst `Error(StatusRegressionErr, xRec."CXW Status", "CXW Status")` wie bei den bestehenden Regressionsregeln.

## 2. Verarbeitung

- [x] 2.1 Codeunit 60331 "CXW Process Workshop Lines" (`src/Codeunits/Codeunit60331.CXWProcessWorkshopLines.al`), `ProcessLineWithErrorHandling`: im Fehlerfall zusätzlich zum Schreiben von `GetLastErrorText()` in `"CXW Last Error"` den Status auf `"CXW Status"::Error` setzen, vor `Modify()` + `Commit()`.
- [x] 2.2 `ProcessGenuineLine`: unmittelbar vor dem abschließenden `WorkshopLine.Modify()` (Status := Processed) zusätzlich `"CXW Last Error" := ''` setzen.
- [x] 2.3 `ProcessNonGenuineLine`: unmittelbar vor dem `WorkshopLine.Modify()` (Status := Processed, vor dem PO-Löschen) zusätzlich `"CXW Last Error" := ''` setzen.
- [x] 2.4 Prüfen, dass alle Referenzen auf `"CXW Processing Error"` im gesamten Projekt (Codeunit 60331, ggf. Page 60338) auf `"CXW Last Error"` umgestellt sind (Suche nach `CXW Processing Error` sollte danach keine Treffer mehr liefern).

## 3. UI

- [x] 3.1 Page 60338 "CXW Workshop Lines" (`src/Pages/Pag60338.CXWWorkshopLines.al`) prüfen: falls dort `"CXW Processing Error"` als Feld/Filter referenziert wird, auf `"CXW Last Error"` umstellen; Status-Filter/-Anzeige funktioniert automatisch mit dem neuen Enum-Wert `Error`, keine Änderung nötig, sofern kein hartcodierter Status-Filter existiert, der `Error` ausschließen würde.

## 4. Übersetzungen

- [x] 4.1 `Translations/CHX.Webshop.g.xlf` wurde durch einen zwischenzeitlichen Kompiliervorgang bereits regeneriert (enthält Last Error/Error-Einträge). `Translations/CHX.Webshop.de-DE.xlf` per `managing-bc-translations`-Skill synchronisiert: NAB-Tool-Vorschläge für 'Letzter Fehler', 'Fehler', 'Neu', 'Verarbeitet' geprüft und übernommen (Prefix entfernt), fehlende Übersetzung 'WS geprüft' für 'WS checked' ergänzt (war zuvor `[NAB: NOT TRANSLATED]`). Alle 436 Trans-Units zwischen g.xlf und de-DE.xlf abgeglichen, keine leeren Targets, keine Waisen, valides XML.

## 5. Dokumentation

- [x] 5.1 `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`, Abschnitt "Workshop-Ankaufsprüfung": Beschreibung von Enum 60337 (neuer Wert Error) und Tab60318 (Feld Last Error statt Processing Error) sowie Codeunit 60331 (Statussetzung im Fehlerfall) aktualisiert.

## 6. Prüfung

- [x] 6.1 AL-Extension kompiliert fehlerfrei — verifiziert per `al compile` (Microsoft AL Compiler 18.0.37.11445) gegen die lokal vorhandenen Symbolpakete in `.alpackages`: 50/50 Dateien, 0 Fehler, 1 vorbestehende Warnung (AL0603, Codeunit60330, nicht Teil dieser Änderung). Zusätzlich wurde zwischenzeitlich außerhalb dieser Session in VS Code kompiliert (erkennbar an der bereits vor diesem Check regenerierten `Translations/CHX.Webshop.g.xlf`); dabei wurden zwei vorbestehende, mit dieser Änderung nicht zusammenhängende falsche Enum-Bezeichner in `PagExt60328` und `TabExt60321` (`::"Neu"`/`::"Verarbeitet"` statt der tatsächlichen AL-Bezeichner `::"new"`/`::"Processed"`) korrigiert.
- [x] 6.2 Manueller Testlauf: Job-Queue-Lauf mit einer absichtlich fehlschlagenden Zeile (z. B. gesperrte Buchungsperiode) — prüfen, dass Status auf `Error` wechselt, `"CXW Last Error"` den Fehlertext enthält, und andere Zeilen im selben Lauf weiterhin normal verarbeitet werden (Fehlerisolation bleibt erhalten). Anschließend Zeile manuell auf `WS checked` zurücksetzen, Ursache beheben, erneut laufen lassen — prüfen, dass `"CXW Last Error"` geleert wird und Status auf `Verarbeitet` wechselt. **Als abgeschlossen markiert auf Anweisung des Nutzers** — nicht in dieser Session gegen eine laufende BC-Umgebung ausgeführt (hier nicht verfügbar).
- [x] 6.3 Manuell prüfen, dass ein Versuch, den Status einer Workshop Line mit Status `Neu` direkt auf `Error` zu setzen (z. B. über die API oder testweise im Table-Testfenster), mit Fehler abgelehnt wird. **Als abgeschlossen markiert auf Anweisung des Nutzers** — nicht in dieser Session gegen eine laufende BC-Umgebung ausgeführt (hier nicht verfügbar).
