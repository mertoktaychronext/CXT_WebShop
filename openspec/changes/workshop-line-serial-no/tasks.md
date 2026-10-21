## 1. Datenmodell

- [x] 1.1 Tab 60318 "CXW Workshop Line": Feld 39 `"CXW Serial No."` (Code[50], Caption 'Serial No.', `Editable = false`, `DataClassification = ToBeClassified`) im Block der Übergabedaten anlegen

## 2. Befüllung

- [x] 2.1 PagExt 60328 `CreateWorkshopLine`: Parameter `SerialNo: Code[50]` ergänzen, `WorkshopLine."CXW Serial No." := SerialNo` vor `Insert(true)`; Aufruf in `ProcessLine` mit der ermittelten bzw. gezogenen `SerialNo`
- [x] 2.2 Codeunit 60336 "CXW Workshop Upgrade": neuer Upgrade-Tag `CXW-WORKSHOPLINE-SERIALNO-<Datum>`, Prozedur `FillSerialNoOnOpenLines` (Status `New|WS checked`, leeres `"CXW Serial No."`, Einkaufszeile vorhanden → `"CXW Workshop Line Mgt.".FindPurchLineSerialNo`, nur bei Ergebnis `Modify(false)`), Tag in `RegisterPerCompanyTags` registrieren
- [x] 2.3 `app/app.json`: Version erhöhen

## 3. API und Oberfläche

- [x] 3.1 Page 60339 "CXW Workshop Line API": `field(serialNo; Rec."CXW Serial No.")` mit `Editable = false` direkt nach `manufacturerSerialNo`
- [x] 3.2 Page 60339 `OnModifyRecord`: Änderung von `"CXW Serial No."` mit `FieldNotEditableErr` ablehnen
- [x] 3.3 Page 60338 "CXW Workshop Lines": Feld nach `"CXW Manufacturer Serial No."` anzeigen, `Editable = false`, ToolTip laut design.md D5

## 4. Übersetzungen und Prüfung

- [x] 4.1 Kompilieren ohne neue Fehler oder Warnungen (lokal CodeCop/UICop für App und Test-App; AppSourceCop läuft in der Pipeline)
- [x] 4.2 `CHX.Webshop.g.xlf` neu erzeugen, neue Einheiten in `CHX.Webshop.de-DE.xlf` übersetzen (Caption „Seriennr.“, ToolTip)
- [x] 4.3 Berechtigungen prüfen: „CXW Workshop API“ und „CXW Workshop All“ brauchen keine Änderung (Berechtigungstest läuft in der Pipeline)

## 5. Tests

- [x] 5.1 Manuell (die Aktion braucht Bestätigung, Seriennr.-Informationskarte und CHX.Base-Pflichtprüfung, daher kein automatischer Test): Testfall „Send to Workshop“ mit vorhandener Seriennummer in der Artikelverfolgung → Werkstattzeile hat diese `"CXW Serial No."`
- [x] 5.2 Manuell: Testfall ohne Artikelverfolgung → gezogene Nummer aus der Seriennr.-Nummernserie steht auf der Werkstattzeile
- [x] 5.3 Test-App: Übernahme aus der Artikelverfolgung über die öffentliche Prozedur `FillSerialNoFromPurchLine` (Codeunit 60335), die das Upgrade nutzt – Seriennr. vorhanden → übernommen, keine Artikelverfolgung → leer ohne Fehler (`SerialNoIsTakenFromItemTracking`, `PurchLineWithoutItemTrackingLeavesSerialNoEmpty`)
- [x] 5.4 Manuell: API `workshopLines` liefert `serialNo`; PATCH mit geändertem `serialNo` wird abgelehnt, PATCH mit `status`/`genuine`/Attributen funktioniert weiter
- [x] 5.5 Manuell: API-Benutzer nur mit „CXW Workshop API“ liest `serialNo` ohne Berechtigungsfehler

## 6. Dokumentation

- [x] 6.1 `docs/developer-manual-de.md`/`-en.md`: Feld 39, API-Feld `serialNo`, Upgrade-Tag
- [x] 6.2 `docs/key-user-manual-de.md`/`-en.md`: BC-Seriennummer auf Werkstattzeile und im Werkstatt-API, Altzeilen mit Status `Processed` bleiben leer
- [x] 6.3 Funktionsregister aktualisieren (geänderte Signatur `CreateWorkshopLine`, neue Upgrade-Prozedur)
- [ ] 6.4 Werkstatt über das neue API-Feld `serialNo` informieren (Feldname bestätigt)
