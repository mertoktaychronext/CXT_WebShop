## Context

„Send to Workshop“ (`PagExt60328 "CXW Workshop Purchase Order"`, `ProcessLine`) ermittelt je Einkaufszeile die BC-Seriennummer: zuerst aus der Artikelverfolgung (`FindPurchLineSerialNo`, Reservation Entry der Einkaufszeile), sonst wird die nächste Nummer aus der Seriennr.-Nummernserie des Artikels gezogen und als Artikelverfolgung angehängt (`AssignNextSerialNo`). Die Nummer liegt danach in der lokalen Variablen `SerialNo`. `CreateWorkshopLine(PurchLine)` übernimmt aber nur die Herstellernummer, die BC-Seriennummer geht verloren.

Die Werkstattzeile ist eine Momentaufnahme der Übergabe (Felder 30–47, `Editable = false`): Der API-Benutzer („CXW Workshop API“) darf nur die Werkstattzeile lesen, keine Bestellungen, Artikel oder Artikelverfolgung. Deshalb muss die Seriennummer auf der Werkstattzeile gespeichert werden und kann nicht zur Laufzeit gelesen werden.

Nach der Buchung des Wareneingangs (Codeunit 60331) existiert die Artikelverfolgung der Einkaufszeile nicht mehr (Reservation Entry → Artikelposten); bei nicht echten Uhren wird die Bestellung gelöscht.

## Goals / Non-Goals

**Goals:**
- BC-Seriennummer beim Anlegen der Werkstattzeile speichern, auf „CXW Workshop Lines“ anzeigen und im API `workshopLines` als `serialNo` ausgeben.
- Schreibschutz im API wie bei den übrigen Übergabedaten.
- Offene Bestandszeilen einmalig nachbefüllen.

**Non-Goals:**
- Nachbefüllen verarbeiteter Zeilen (Status `Processed`/`Error`) aus Artikelposten bzw. gebuchten Wareneingängen.
- Synchronisation, wenn die Artikelverfolgung der Einkaufszeile nach dem Senden geändert wird.
- Drilldown von der Werkstattzeile auf die Seriennr.-Informationskarte.
- Änderungen an Codeunit 60331, an der Ermittlung/Vergabe der Seriennummer oder an Berechtigungssätzen.

## Decisions

### D1: Neues Feld 39 `"CXW Serial No."` (Code[50]) auf Tab 60318
Code[50] wie `"Serial No."` in Reservation Entry / Serial No. Information. Feldnummer 39 liegt im Block der Übergabedaten (30–38 Bestelldaten, 40–47 Uhrendaten). `Editable = false`, `DataClassification = ToBeClassified` wie die Nachbarfelder. Caption „Serial No.“ (DE: „Seriennr.“), damit es sich klar von „Manufacturer Serial No.“ unterscheidet.
- *Alternative:* FlowField auf Reservation Entry → scheitert an den Berechtigungen des API-Benutzers und liefert nach der Buchung nichts mehr. Verworfen.

### D2: Seriennummer als Parameter an `CreateWorkshopLine`
`ProcessLine` kennt die Nummer bereits; `CreateWorkshopLine(PurchLine; SerialNo: Code[50])` setzt das Feld vor `Insert(true)`. Kein erneutes Lesen der Reservation Entry.
- *Alternative:* in `FillPurchaseData` per `FindPurchLineSerialNo` lesen → zusätzliche Abfrage und eine zweite Quelle für dieselbe Information. Für das Upgrade (D4) wird `FindPurchLineSerialNo` aber genutzt.

### D3: API-Feld `serialNo` neben `manufacturerSerialNo`
`field(serialNo; Rec."CXW Serial No.") { Editable = false; }` direkt nach `manufacturerSerialNo`. Zusätzlich in `OnModifyRecord` ein Vergleich mit `xRec` → `FieldNotEditableErr`, wie bei den übrigen schreibgeschützten Feldern (`Editable = false` allein verhindert bei API-Pages kein PATCH zuverlässig, daher das bestehende Muster). Die Berechtigung „CXW Workshop API“ bleibt unverändert, weil nur die Werkstattzeile gelesen wird.

### D4: Upgrade über neuen Tag in Codeunit 60336
Neuer Upgrade-Tag `CXW-WORKSHOPLINE-SERIALNO-<Datum>`, Prozedur `FillSerialNoOnOpenLines`: Zeilen mit Status `New|WS checked` und leerem `"CXW Serial No."`, Einkaufszeile per `Get` vorhanden → `FindPurchLineSerialNo(PurchLine)`; nur bei nicht leerem Ergebnis `Modify(false)`. Registrierung in `RegisterPerCompanyTags`. Fehlende Einkaufszeile oder Artikelverfolgung → Zeile bleibt leer, kein Fehler.
- *Alternative:* auch verarbeitete Zeilen über Purch. Rcpt. Line (`Order No.`/`Order Line No.`) und Artikelposten befüllen → mehr Logik und Berechtigungen für einen reinen Altbestand; bei nicht echten Uhren gibt es keinen Wareneingang. Verworfen (Non-Goal).

### D5: Anzeige auf Page 60338
Feld direkt nach `"CXW Manufacturer Serial No."`, `Editable = false`, ToolTip: „Specifies the Business Central serial number of the watch, as assigned in the item tracking of the purchase line when the line was sent to the workshop.“

## Risks / Trade-offs

- [Werkstatt-Client erwartet ein festes Feldset] → Das Feld ist additiv; JSON-Clients ignorieren unbekannte Felder üblicherweise. Werkstatt vor dem Go-live über das neue Feld `serialNo` informieren.
- [Artikelverfolgung wird nach dem Senden geändert] → Werkstattzeile zeigt die Nummer zum Übergabezeitpunkt (bewusste Momentaufnahme, wie bei den Bestelldaten); Codeunit 60331 bucht mit der aktuellen Artikelverfolgung. Abweichungen sind selten, weil die Zeile nach dem Senden gesperrt ist.
- [Verarbeitete Altzeilen bleiben ohne Seriennummer] → bewusst, im Handbuch erwähnen.

## Migration Plan

1. `app.json`-Version erhöhen (Upgrade-Codeunit läuft nur bei höherer Version).
2. Deployment: Upgrade befüllt offene Zeilen einmalig je Mandant.
3. Rollback: Feld ist additiv; eine ältere App-Version ohne das Feld lässt sich nur mit Schema-Sync `ForceSync` zurückspielen (Datenverlust nur dieses Felds).

## Open Questions

- ~~Soll das API-Feld anders heißen (z. B. `bcSerialNo`)?~~ Entschieden 2026-10-21: `serialNo` ist eindeutig, die Herstellernummer heißt bereits `manufacturerSerialNo`.

## Abweichungen in der Umsetzung

- Die Übernahme aus der Artikelverfolgung für das Upgrade liegt als öffentliche Prozedur `FillSerialNoFromPurchLine` in Codeunit 60335 (nicht direkt in Codeunit 60336), damit sie aus der Test-App testbar ist (die Test-App sieht keine `internal`-Prozeduren).
