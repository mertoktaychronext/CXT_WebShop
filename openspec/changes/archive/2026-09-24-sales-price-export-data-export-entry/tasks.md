## 1. Export-Codeunit umstellen (Codeunit 60329 "CXW Export Gateway Sales Price")

- [x] 1.1 Label `SalesPriceDestinationCodeLbl: Label 'SALESPRICE', Locked = true;` ergänzen
- [x] 1.2 `CreateExternalInterfaceFile`: Insert in "CXW Sales Price Outbound File" entfernen; JSON und Dateinamen bauen und `SendToApiInterface(JsonText, FileName, SalesPrice.RecordId())` aufrufen (öffentliche Signatur von `CreateExternalInterfaceFile` bleibt unverändert)
- [x] 1.3 `SendToApiInterface`: Parameter `var vOutboundFile` ersetzen durch `pJsonText`, `pFileName`, `pSourceRecordId`; Ergebnis des Aufrufs (Erfolg, HTTP-Status, Fehlertext, Request- und Response-Text) zwischenspeichern, statt den Outbound-Datensatz zu ändern
- [x] 1.4 Neuen lokalen Helper `CreateDataExportEntry(pJsonText; pFileName; pSourceRecordId; pSuccess; pErrorMessage): BigInteger` anlegen: `Init` → Destination Code, Payload Format JSON, FileName, Source Record ID → `Insert` → `SetPayload` → Status Processed/Error, Attempt Count 1, Last Attempt At, Processed At (nur bei Erfolg), Error Message (gekürzt) → `Modify(true)`; Rückgabe `"Entry No."`
- [x] 1.5 In `SendToApiInterface` nach dem HTTP-Aufruf in allen drei Pfaden (Erfolg, Nicht-Erfolg-Status, Netzwerkfehler) zuerst `CreateDataExportEntry` und dann `LogHttpCall` aufrufen; Rückgabewert `true`/`false` wie bisher
- [x] 1.6 `LogHttpCall`: Parameter `pOutboundFile` durch `pDataExportEntryNo: BigInteger` ersetzen; `"CXW Source Table No." := Database::"Data Export Entry"`, `"CXW Source Entry No" := pDataExportEntryNo`
- [x] 1.7 Sicherstellen, dass kein Codepfad nach dem Export einen "Data Export Entry" mit Status "Waiting to Process" hinterlässt (Code-Review aller `Insert`-Stellen)

## 2. Tabellen und Berechtigungen

- [x] 2.1 Tab 60302 "CXW Http Call Log": `TableRelation` von `"CXW Source Entry No"` um `else if ("CXW Source Table No." = const(50103)) "Data Export Entry"."Entry No."` erweitern; Zweig für 60314 beibehalten
- [x] 2.2 Tab 60314 "CXW Sales Price Outbound File": `ObsoleteState = Pending`, `ObsoleteReason` und `ObsoleteTag` setzen
- [x] 2.3 Permission Set `CXWChronWSAll`: `tabledata "Data Export Entry" = RIM` und `table "Data Export Entry" = X` ergänzen
- [x] 2.4 `app.json`: Version auf `27.0.0.3` erhöhen (passend zum ObsoleteTag)

## 3. Build und Test

- [x] 3.1 Kompilieren; nur die erwarteten AL0432-Warnungen (Obsolete Pending 60314) zulassen, keine Fehler
- [x] 3.2 Test Erfolg: "Upload Sales Price" für eine Zeile → "Data Export Entry" mit `SALESPRICE`, Status Processed, Payload in der FactBox von Page 50108 sichtbar, "CXW Http Call Log" mit Source Table 50103 und passender Entry No.; Prüfzeile auf "Sent"
- [x] 3.3 Test Fehler: falsche Endpoint-URL oder 4xx → "Data Export Entry" mit Status Error und Error Message, Log mit Success = false, Prüfzeile auf "Error"; erneuter Upload erzeugt einen neuen Eintrag
- [x] 3.4 Test ChronextBC-Job: "Data Export Mgt." ausführen → kein `SALESPRICE`-Eintrag wird verarbeitet; "Export Data" auf einem `SALESPRICE`-Eintrag sendet keinen Request (Fehler "Setup nicht gefunden")
- [x] 3.5 Test mehrere Länder: DE und AT mit gleicher Währung → zwei Einträge mit unterschiedlichem Dateinamen und Ländercode im Payload
- [x] 3.6 Prüfen, dass in "CXW Sales Price Outbound File" keine neuen Datensätze entstehen und Alt-Logs mit Source Table 60314 weiterhin auflösbar sind

## 4. Übersetzungen und Doku

- [x] 4.1 `Translations/CHX.Webshop.de-DE.xlf` nach dem Build synchronisieren (ObsoleteReason ist nicht übersetzungsrelevant; auf neue Trans-Units prüfen)
- [x] 4.2 `docs/developer-manual-de.md`/`-en.md`: Export-Ablauf, neue Protokollstelle "Data Export Entry" (`SALESPRICE`, reservierter Code) und Obsolete-Status von 60314 beschreiben
- [x] 4.3 `docs/key-user-manual-de.md`/`-en.md`: SalesPrice-Übertragungen in "Data Export Entries" finden; Wiederholung nur über "Upload Sales Price", nicht über "Export Data"
- [x] 4.4 Funktionsregister (`docs/funktionsregister/`) für Codeunit 60329 und Tabelle 60314 aktualisieren
- [x] 4.5 Confluence-Sync der geänderten Doku (Space SOFTWAREEN, Elternseite 344457224)
