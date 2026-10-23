## Context

Eine Werkstattzeile entsteht ausschließlich über „Send to Workshop“ auf der Einkaufsbestellung (PagExt 60328, `ProcessLine`/`CreateWorkshopLine`). Dabei wird nicht nur die Werkstattzeile angelegt, sondern auch Zustand an anderen Stellen geschrieben:

| Ort | Was „Send to Workshop“ schreibt | Wer wertet es aus |
|---|---|---|
| Einkaufszeile (TabExt 60321) | „Sent to Workshop“ = Ja, „Manufacturer Serial No.“, „Not Arrived“ = Nein | Filter in `SendLinesToWorkshop` (nur nicht gesendete Zeilen); Sperre der Felder im Subform (PagExt 60329, `LineEditable`) |
| Reservierungsposten (Artikelverfolgung der Einkaufszeile) | BC-Seriennummer, ggf. neu aus Nummernserie | Wareneingang in Codeunit 60331; Wiederverwendung bei erneutem Senden (`FindPurchLineSerialNo`) |
| Seriennr.-Information | Datensatz zur Seriennummer, Herstellernummer (CHX.Base) | Lager/CHX.Base, Wiederverwendung bei erneutem Senden |
| Einkaufskopf | nichts gespeichert – „No. of Workshop Lines“ ist FlowField | zählt automatisch richtig |

Heute: Page 60338 und API-Page 60339 haben `DeleteAllowed = false`. Gelöscht wird nur kaskadierend, wenn die Einkaufszeile gelöscht wird (TabExt 60321 `OnDelete`, `WorkshopLine.Delete()` ohne Trigger, verarbeitete Zeilen bleiben stehen). Dieser Weg wird auch von der Verarbeitung „nicht echt“ (Codeunit 60331, `PurchHeader.Delete(true)`) durchlaufen. „CXW Workshop All“ gewährt heute `RIMD` auf die Werkstattzeile, damit funktioniert die Kaskade für alle Workshop-Benutzer.

## Goals / Non-Goals

**Goals:**
- Werkstattzeilen in „New“ und „Error“ über die Seite „Workshop Lines“ löschen können.
- Nach dem Löschen ist die Einkaufszeile wieder in demselben Zustand wie vor „Send to Workshop“ (aus Sicht der Webshop-App) und kann erneut gesendet werden.
- Prüfergebnisse („WS checked“) und Prüfnachweis („Processed“) bleiben geschützt.
- Löschen ist an einen eigenen Berechtigungssatz gebunden.

**Non-Goals:**
- Kein Löschen über das Werkstatt-API.
- Keine Information der Werkstatt über gelöschte Zeilen, kein Storno-Status.
- Kein Zurücknehmen der Artikelverfolgung / Seriennummer oder der Seriennr.-Information.
- Kein Storno eines bereits gebuchten Wareneingangs.

## Decisions

### 1. Logik im `OnDelete`-Trigger der Tabelle, nicht auf der Seite
Status-Sperre und Zurücksetzen der Einkaufszeile gehören in `trigger OnDelete()` von Tab 60318; die eigentliche Rücksetzung als Prozedur in Codeunit 60335 „CXW Workshop Line Mgt.“ (z. B. `ResetPurchLineOnDelete`). So gilt die Regel für jeden Löschweg mit Trigger (Seite, Code, Konfigurationspakete), nicht nur für eine Seite.
*Alternative:* `OnDeleteRecord` auf Page 60338 – verworfen, weil andere Löschwege die Einkaufszeile dann gesperrt zurücklassen.

### 2. Nur „New“ und „Error“ löschbar
- **New**: Hauptanwendungsfall (irrtümlich gesendet, Werkstatt hat noch nichts gemeldet).
- **Error**: Zeile ist in der Verarbeitung hängen geblieben; Löschen + erneut senden ist ein Ausweg.
- **WS checked**: Die Werkstatt hat Ergebnisse gemeldet (Echtheit, Attribute); diese dürfen nicht verloren gehen. → `Error(...)`.
- **Processed**: Prüfnachweis; bei „echt“ ist der Wareneingang gebucht, bei „nicht echt“ existiert die Bestellung nicht mehr. → `Error(...)`.
Umsetzung als Positivliste (`if not (Status in [New, Error]) then Error(...)`), damit ein künftiger neuer Status standardmäßig nicht löschbar ist.

### 3. Eigener Berechtigungssatz „CXW Workshop Delete“, indirektes Löschrecht in „CXW Workshop All“
- Neu: `permissionset 60303 "CXW Workshop Delete"`, `Assignable = true`, `IncludedPermissionSets = "CXW Workshop All"`, `tabledata "CXW Workshop Line" = RIMD`. Durch das Einschließen genügt die Zuweisung dieses einen Satzes für Workshop-Benutzer mit Löschrecht. `RIMD` statt nur `D`, weil der Permission-Test (`EveryPersistentTableHasFullTableDataPermission`) einen Satz mit vollem Recht je Tabelle verlangt.
- „CXW Workshop All“: `tabledata "CXW Workshop Line" = RIMd` – direktes Löschen (Seite) ist damit nicht mehr möglich, indirektes über Objekte mit passender `Permissions`-Eigenschaft schon.
- Die Kaskade beim Löschen der Einkaufszeile wird aus TabExt 60321 in eine Prozedur der Codeunit 60335 verlagert (z. B. `DeleteForDeletedPurchLine`); die Codeunit erhält `Permissions = tabledata "CXW Workshop Line" = d`. TabExt 60321 ruft nur noch diese Prozedur auf.
*Alternative:* „CXW Workshop All“ behält `D`, Löschen wird nur per Seiten-Prüfung (`OnDeleteRecord` + Prüfung auf zugewiesenen Satz) beschränkt – verworfen: Prüfen auf Berechtigungssatz-Zuweisung im Code ist fragil (Benutzergruppen, Security Groups, SUPER) und schützt nicht gegen andere Löschwege.
*Alternative:* Neuer Satz ohne `IncludedPermissionSets`, nur Zusatzrecht – verworfen, weil „D“ allein den Permission-Test nicht erfüllt und ein Satz mit RIMD ohne Ausführungsrechte allein nicht nutzbar wäre.

### 4. Kaskade von der Einkaufszeile bleibt ohne Trigger
Die Prozedur für das Mitlöschen ruft `WorkshopLine.Delete()` (ohne `true`) – der neue Tabellen-Trigger läuft dort also **nicht**. Das ist gewollt: Die Einkaufszeile wird gerade selbst gelöscht; ein `Modify` auf genau diese Zeile im laufenden `OnDelete` würde zu einem Versionskonflikt führen, und die Status-Sperre darf das Löschen der Einkaufszeile nicht blockieren. Verarbeitete Zeilen werden wie bisher nicht mitgelöscht; offene Zeilen („New“, „WS checked“, „Error“) wie bisher schon. Ein Kommentar im Trigger weist darauf hin.

### 5. Einkaufszeile zurücksetzen statt löschen
Rücksetzung: „Sent to Workshop“ := false, „Manufacturer Serial No.“ := '', `Modify()` (nur eigene Felder, keine Validierung von Standardfeldern). „Not Arrived“ bleibt unverändert (beim Senden bereits auf Nein gesetzt). Fehlt die Einkaufszeile (`Get` schlägt fehl), wird nichts gemacht.

### 6. Artikelverfolgung und Seriennr.-Information bleiben stehen
`ProcessLine` ist bereits darauf ausgelegt, dass diese Daten aus einem abgebrochenen Versuch bestehen bleiben und wiederverwendet werden (`FindPurchLineSerialNo`, `GetOrCreateSerialNoInformation`). Löschen hieße eine Nummer aus der Serie verbrennen bzw. eine erfasste Herstellernummer verlieren. Die Seriennr.-Information gehört außerdem CHX.Base und kann von anderen Prozessen referenziert sein.

### 7. API bleibt ohne Löschen
`DeleteAllowed = false` auf Page 60339 und `RM` im Berechtigungssatz „CXW Workshop API“ bleiben. Die Werkstatt wird über gelöschte Zeilen nicht informiert (fachlich nicht notwendig, da nur Zeilen in „New“/„Error“ gelöscht werden).

## Risks / Trade-offs

- [Benutzer, die bisher implizit `D` auf die Tabelle hatten, verlieren es] → Auf der Seite war Löschen bisher ohnehin nicht möglich; das Mitlöschen über die Einkaufszeile bleibt über das indirekte Recht erhalten. In den Release Notes / im Key-User-Handbuch auf die Zuweisung von „CXW Workshop Delete“ hinweisen.
- [Ein künftiger Code-Pfad löscht Werkstattzeilen direkt, ohne über Codeunit 60335 zu gehen] → Läuft für Benutzer mit nur „CXW Workshop All“ in einen Berechtigungsfehler; das ist im Test sichtbar. Löschen nur über die Codeunit-Prozedur bündeln.
- [Werkstatt hat eine „New“-Zeile bereits abgeholt, meldet aber noch nicht zurück; sie wird in BC gelöscht → späteres PATCH ergibt 404, erneutes Senden erzeugt eine neue Zeile mit neuer `SystemId`] → Fachlich akzeptiert (keine Information der Werkstatt gewünscht).
- [Ein Löschweg ohne Trigger (`Delete()` ohne `true`) umgeht Sperre und Rücksetzung] → Nur die Kaskade tut das, dort gewollt (Entscheidung 4).

## Migration Plan

Keine Datenmigration, kein Upgrade-Tag. Nach dem Deployment den Benutzern, die Werkstattzeilen löschen dürfen, „CXW Workshop Delete“ zuweisen. Rollback durch Zurücksetzen der Version (dann gilt wieder `RIMD` in „CXW Workshop All“, der neue Satz entfällt).

## Open Questions

- Welche Benutzer/Rollen bekommen „CXW Workshop Delete“ zugewiesen? (Organisatorisch, keine Code-Auswirkung.)
