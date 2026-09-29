## 1. Datenmodell und Enums

- [x] 1.1 `enumextension 60300 "CXW Data Export Statuses" extends "Data Export Statuses"` mit `value(60300; "CXW Pending")`, Caption 'Pending (Sales Price)' anlegen
- [x] 1.2 Enum 60334 "CXW Sales Price Export Status" um `value(3; Queued)` (Caption 'Queued') ergänzen
- [x] 1.3 Tab 60311 "CXW General Sales Price Setup": Felder `16 "CXW Max. Export Attempts"` (Integer, `InitValue = 3`, `MinValue = 1`) und `17 "CXW Archive Country Code"` (Code[10], `TableRelation = "Country/Region"`, `InitValue = 'DE'`) ergänzen
- [x] 1.4 Page 60321: beide Felder neben "CXW Price Export Active"/"CXW API Interface Code" mit ToolTip anzeigen
- [x] 1.5 Tabelle 60320 "CXW Sales Price Export" mit den Feldern 1–23 laut design.md, Entscheidung 1 (inkl. FlowField `"CXW Export Status"`), PK `"CXW Entry No."`, Schlüssel `"CXW Item No.", "CXW Country Code", "CXW Currency Code"`, `DrillDownPageId`/`LookupPageId` = 60320
- [x] 1.6 Page 60320 "CXW Sales Price Export Entries" (List, `Editable = false`, `UsageCategory = Lists`) mit allen Feldern, `SystemCreatedAt`/`SystemCreatedBy` und Drilldown bzw. Aktion zum "Data Export Entry"

## 2. Export Gateway (Codeunit 60329) umbauen

- [x] 2.1 `ResolveUnitPriceLCY` auf Einzelwerte umstellen (`pCurrencyCode`, `pExchangeRateAmount`, `pUnitPrice`) und `UpdateSalesPriceFields` anpassen; das Ergebnis beim Rückschreiben bleibt unverändert
- [x] 2.2 Archivierung in `WriteBackAndArchive` nur noch, wenn `"CXW Country Code"` = `"CXW Archive Country Code"`; `WriteBackAndArchive` gibt den geschriebenen "Sales Price" zurück (bereits `var`)
- [x] 2.3 Neue Prozedur `QueueExport(pSalesPriceChecking; pSalesPrice)`: "CXW Sales Price Export"-Datensatz aus Prüfzeile anlegen (inkl. `"CXW Unit Price (LCY)"` per `ResolveUnitPriceLCY` und `"CXW Sales Price SystemId"`), danach "Data Export Entry" mit `SALESPRICE`, JSON, `FileName` und `Source Record ID` = RecordId des Exportdatensatzes; `Insert(true)` und in derselben Transaktion `Status := "CXW Pending"` und `Modify(true)`; Rückverweis `"CXW Data Export Entry No."` setzen
- [x] 2.4 `CreateExternalInterfaceFile`, `CreateDataExportEntry` und die RecordRef-basierte JSON-Erzeugung (`AddFieldToJson`, `"CXW Country Code"`-Anhang) entfernen
- [x] 2.5 `SendToApiInterface` auf `var DataExportEntry` umstellen: `Status`, `Attempt Count += 1`, `Last Attempt At`, `Processed At` bzw. `Error Message` am übergebenen Eintrag setzen; `LogHttpCall` weiter mit `Entry No.`
- [x] 2.6 Neue Prozedur `BuildSalesPriceJson(pExport; pSalesPrice; pItem): Text` mit den 30 Schlüsseln in fester Reihenfolge laut Spec und design.md, Entscheidung 5
- [x] 2.7 Hilfsprozedur `CalcProfitPercent(pUnitPriceLcy, pVatBusPostingGr, pVatProdPostingGr, pUnitCost)` gemäß design.md, Entscheidung 6

## 3. Freigabe

- [x] 3.1 Worker-Codeunit für die Freigabe einer Zeile (per `Codeunit.Run`, `TableNo = "CXW Sales Price Checking"`): `WriteBackAndArchive` → `QueueExport`; ein Fehler rollt alle Änderungen der Zeile zurück
- [x] 3.2 Page 60322: Aktion "Upload Sales Price" durch "Release Sales Prices" ersetzen (nur Zeilen mit `"CXW Country Code" <> ''`; Abbruch mit Hinweis auf "Add all Countries", wenn nur Quellzeilen freigegeben sind; Prüfungen inkl. `TestField("CXW Archive Country Code")`, Rückfrage für `Queued`/`Sent`, `Commit()` + `Codeunit.Run` pro Zeile, Status `Queued` bzw. `Error`, Abschlussmeldung "%1 von %2 …"); ToolTip anpassen
- [x] 3.3 Page 60322: Navigationsaktion zu Page 60320 "CXW Sales Price Export Entries" neben der Archiv-Aktion

## 4. Job-Codeunit

- [x] 4.1 Codeunit 60332 "CXW Export Sales Price Job" (`TableNo = "Job Queue Entry"`): Setup lesen; bei inaktivem Export oder leerem API-Code ohne Fehler beenden
- [x] 4.2 Auswahl: `Destination Code = SALESPRICE` und (`Status = CXW Pending` oder `Status = Error` und `Attempt Count < Max`); Max = Setupwert, `0` wird wie `3` behandelt
- [x] 4.3 Verarbeitung pro Eintrag isoliert (Worker per `Codeunit.Run`) mit `Commit()` nach jedem Eintrag; Laufzeitfehler → `Status = Error`, `Attempt Count += 1`, `Last Attempt At`, `Error Message := GetLastErrorText()`
- [x] 4.4 Payload nur bauen, wenn keine vorhanden ist: Exportdatensatz über `Source Record ID` (RecordRef → `SetTable`), "Sales Price" per `GetBySystemId`, Item per `Get`; fehlt einer davon → Fehler mit Label; danach `SetPayload`
- [x] 4.5 Gespeicherte Payload lesen (`CreatePayloadInStream`) und über `SendToApiInterface` senden
- [x] 4.6 Der Job-Lauf endet nicht mit `Error`, wenn einzelne Einträge fehlschlagen

## 5. Manuelles Zurücksetzen

- [x] 5.1 `pageextension 60336 "CXW Data Export Entries" extends "Data Export Entries"`: Aktion "Requeue Sales Price" (`SetSelectionFilter`, nur `SALESPRICE` + `Error` → `CXW Pending`, `Attempt Count := 0`, `Error Message := ''`, Meldung mit Anzahl)

## 6. Berechtigungen und Übersetzungen

- [x] 6.1 `CXWChronWSAll`: `tabledata "CXW Sales Price Export" = RIMD`, `table "CXW Sales Price Export" = X`, `page "CXW Sales Price Export Entries" = X`, neue Codeunits = X
- [x] 6.2 Alle neuen Texte als Label bzw. Caption/ToolTip gemäß `multilingual-messages`
- [x] 6.3 Kompilieren, `CHX.Webshop.g.xlf` neu erzeugen, neue Einträge in `CHX.Webshop.de-DE.xlf` übersetzen
- [x] 6.4 `app.json`-Version erhöhen

## 7. Prüfung

- [x] 7.1 Kompilieren ohne neue Fehler oder Warnungen (außer den bekannten Obsolete-Warnungen zu 60314)
- [ ] 7.2 Test: Freigabe von DE, AT (gleiche Währung, unterschiedlicher Preis) und US → drei Exportdatensätze und drei `CXW Pending`-Einträge; nur DE erhält eine Archivzeile; nach dem Joblauf enthalten die Payloads je den eigenen Preis und das eigene Land
- [ ] 7.3 Test: Payload enthält genau 30 Schlüssel in der vorgegebenen Reihenfolge, keine entfallenen Schlüssel, `reasonCode` nie leer, `profit`/`unitCost` gemäß Beispielrechnung
- [ ] 7.4 Test: "Data Export Mgt." (ChronextBC) laufen lassen → SALESPRICE-Einträge bleiben unverändert
- [ ] 7.5 Test: Endpoint liefert Fehler → Wiederholung bis `Max`, danach keine Auswahl mehr; "Requeue Sales Price" setzt zurück und der nächste Lauf sendet dieselbe Payload
- [ ] 7.6 Test: gelöschter Exportdatensatz → nur dieser Eintrag `Error`, die übrigen werden verarbeitet, der Joblauf endet erfolgreich
- [ ] 7.7 Test: Fehler beim Rückschreiben einer Zeile → kein Exportdatensatz, kein Eintrag, keine Archivzeile für diese Zeile; die übrigen Zeilen werden freigegeben
- [ ] 7.8 Test: Archivland im Setup leer → "Release Sales Prices" bricht vor der ersten Zeile ab
- [ ] 7.9 Test: freigegebene Quellzeile ohne Land neben ihren Länderzeilen → für die Quellzeile kein "Sales Price"-Schreiben, kein Archiv, kein Exportdatensatz, kein Eintrag, Status unverändert; nur Quellzeilen freigegeben → Abbruch mit Hinweis

## 8. Dokumentation

- [x] 8.1 `docs/user-manual-de.md`/`-en.md`: "Release Sales Prices", asynchroner Versand, neue Liste "Sales Price Export Entries", Archiv nur noch DE
- [x] 8.2 `docs/key-user-manual-de.md`/`-en.md`: Job-Queue-Eintrag (Codeunit 60332), "Max. Export Attempts", "Archive Country Code", "Requeue Sales Price", Warnung vor "Export Data" bei SALESPRICE-Einträgen
- [x] 8.3 `docs/developer-manual-de.md`/`-en.md`: Ablauf, Tabelle 60320, Status `CXW Pending`, Feldherkunft des JSON, Beispiel-Payload, reservierter Destination Code `SALESPRICE`
