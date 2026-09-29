## Why

Freigegebene Verkaufspreise werden heute nur synchron über die Aktion "Upload Sales Price" gesendet. Das JSON entsteht per RecordRef-Schleife mit BC-Feldnamen (`"Item No."`, `"CXW Country Code"`, System-Felder …). Es entspricht damit nicht dem Format, das der Empfänger aus dem NAV-Altsystem kennt (camelCase-Schlüssel der früheren API-Page 88006 "CHNX Sales Price Entity"). Der Versand soll künftig entkoppelt über die Aufgabenwarteschlange laufen, im vereinbarten Dateiformat, mit automatischer Wiederholung bei Fehlern. Außerdem soll das Archiv nur noch den DE-Preis enthalten. Die Preise aller Länder müssen deshalb an anderer Stelle pro Land festgehalten werden.

## What Changes

- **BREAKING**: Die Aktion "Upload Sales Price" auf Page 60322 wird durch **"Release Sales Prices"** ersetzt. Sie schreibt wie bisher in "Sales Price" zurück, sendet aber **nicht** mehr. Pro Zeile legt sie
  - einen Datensatz in der neuen Tabelle **"CXW Sales Price Export"** an. Er ist der Preisstand dieses Landes zum Zeitpunkt der Freigabe.
  - einen "Data Export Entry" (ChronextBC 50103) mit `Destination Code` = `SALESPRICE` und Status **`CXW Pending`** an. Seine `Source Record ID` zeigt nur auf diesen Datensatz, der Eintrag trägt keine Preisdaten.
- **BREAKING**: Quellzeilen ohne Land (importierte Zeilen) werden von "Release Sales Prices" übersprungen. Sie werden weder zurückgeschrieben noch archiviert noch gesendet. Gesendet werden nur Länderzeilen.
- **BREAKING**: "CXW Sales Price Archive" erhält nur noch Zeilen des Archivlandes (neues Setup-Feld **"CXW Archive Country Code"**, Vorgabe `DE`). Andere Länder und Quellzeilen ohne Land werden nicht mehr archiviert.
- Neue Tabelle **"CXW Sales Price Export"** mit Liste. Sie enthält je freigegebener Zeile Artikel, Land, Währung, Preise (inkl. berechnetem Preis in Mandantenwährung), Gültigkeit, Grund, Kommentar, Bemerkung, Änderungsinfo, `SystemId` des "Sales Price" und den Verweis auf den "Data Export Entry".
- Neuer Status **`Queued`** im Enum "CXW Sales Price Export Status" für die Prüfzeile nach erfolgreicher Freigabe. Eine erneute Freigabe erfolgt nur nach Rückfrage.
- Neue Enum-Erweiterung auf "Data Export Statuses" (ChronextBC) mit `CXW Pending`. Der ChronextBC-Job "Data Export Mgt." (50102) verarbeitet nur `Waiting to Process` und ignoriert diese Einträge deshalb.
- Neue Codeunit **"CXW Export Sales Price Job"** (`TableNo = "Job Queue Entry"`). Sie verarbeitet SALESPRICE-Einträge mit Status `CXW Pending` sowie `Error`-Einträge mit `Attempt Count` < Maximum. Sie liest die Preisdaten über `Source Record ID` aus "CXW Sales Price Export", baut das JSON, speichert es als Payload und sendet es über die bestehende API-Schnittstelle (inkl. SigV4).
- **BREAKING**: Neues JSON-Format mit 29 festen camelCase-Schlüsseln. Es entfallen gegenüber dem NAV-Format: `variantCode`, `promotionMediumNo`, `promMedTarGrpNo`, `setNo`, `sizeCodeDiva`, `colorCodeDiva`, `colorDescriptionDiva`, `sizeDescriptionDiva`, `systemValueSizeCodes`, `systemValueColorCodes`, `sizeToEnterCode`, `priceGroupId`, `fallBackPrice`, `documentUnitPrice`, `deliveryCostLimitCode`, `priceChangeSuggWriteOff`. `unitCost` und `profit` (Prozent) werden aus dem Artikel berechnet. `reasonCode` ist nie leer.
- Neues Setup-Feld **"CXW Max. Export Attempts"** (Standard 3).
- Neue Aktion **"Requeue Sales Price"** auf ChronextBC-Page 50108 "Data Export Entries" (Page-Erweiterung), für den manuellen Eingriff nach Erreichen des Maximums.

## Capabilities

### New Capabilities
- `sales-price-export-job`: Speicherung der freigegebenen Preise pro Land in "CXW Sales Price Export", Job in der Aufgabenwarteschlange, Auswahl und Wiederholung, JSON-Format mit Feldherkunft, manuelles Zurücksetzen.

### Modified Capabilities
- `sales-price-api-export`: Versand nicht mehr synchron, sondern über den Job. `Source Record ID` zeigt auf "CXW Sales Price Export"; Status-Lebenszyklus (`CXW Pending` → `Processed`/`Error`); Exportstatus der Prüfzeile `Queued`; Rückfrage bei erneuter Freigabe; neues Payload-Format.
- `sales-price-checking-writeback`: Auslösung durch "Release Sales Prices". Archiviert werden nur noch Zeilen des Archivlandes. Ein Fehler beim Rückschreiben erzeugt weder Exportdatensatz noch Export-Eintrag.

## Impact

- Neu: Tabelle 60320 "CXW Sales Price Export", Page 60320 "CXW Sales Price Export Entries", Codeunit 60332 "CXW Export Sales Price Job", enumextension 60300 "CXW Data Export Statuses", pageextension 60336 "CXW Data Export Entries".
- `src/Codeunits/Codeunit60329.CXWExportGatewaySalesPrice.al`: `CreateExternalInterfaceFile` entfällt, dafür `QueueExport`. Die Archivierung ist nur noch bedingt. `SendToApiInterface` aktualisiert den bestehenden "Data Export Entry". `ResolveUnitPriceLCY` wird auf Einzelwerte umgestellt.
- `src/Pages/Pag60322.CXWSalesPriceCheckingList.al`: Aktion ersetzt, Navigation zur neuen Liste.
- `src/Enums/Enum60334.CXWSalesPriceExportStatus.al`: Wert `Queued`.
- `src/Tables/Tab60311.CXWGeneralSalesPriceSetup.al` und `src/Pages/Pag60321.CXWGeneralSalesPriceSetup.al`: Felder "CXW Max. Export Attempts" und "CXW Archive Country Code".
- `src/PermissionSets/CXWChronWSAll.permissionset.al`, `Translations/CHX.Webshop.de-DE.xlf`.
- Betrieb: Ein Key User muss einen wiederkehrenden Job-Queue-Eintrag für Codeunit 60332 anlegen und im Setup das Archivland prüfen.
- Empfänger: erhält ab diesem Release das neue JSON-Format.
- Doku: `docs/user-manual-*`, `docs/key-user-manual-*`, `docs/developer-manual-*`.
