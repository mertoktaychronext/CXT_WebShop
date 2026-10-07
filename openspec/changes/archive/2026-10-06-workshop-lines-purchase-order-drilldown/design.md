## Context

Werkstattzeilen („CXW Workshop Line“, Tabelle 60318) werden über die Aktion „Send to Workshop“ (PageExt 60328 auf „Purchase Order“) je angekommener Einkaufszeile angelegt. Der Primärschlüssel ist Belegart + Belegnummer + Zeilennummer der Einkaufszeile, die Verknüpfung zum Einkaufskopf ist also direkt über `"CXW Document Type"`/`"CXW Document No."` möglich. Die Liste „CXW Workshop Lines“ (Page 60338) ist nur über die Suche erreichbar.

`SendLinesToWorkshop` filtert bereits auf `"CXW Sent to Workshop" = false`; ein erneuter Aufruf verarbeitet also nur offene Zeilen (z. B. vorher als „Not Arrived“ markierte oder mit Fehler abgebrochene). Ein Hinweis, dass schon Werkstattzeilen existieren, fehlt.

## Goals / Non-Goals

**Goals:**
- Anzahl der Werkstattzeilen auf der Bestellung sichtbar machen und per Klick die gefilterte Liste öffnen.
- Benutzer beim erneuten „Send to Workshop“ auf vorhandene Werkstattzeilen hinweisen.

**Non-Goals:**
- Kein Sperren des Nachsendens offener Zeilen – das Teilsenden (nicht angekommene Zeilen später nachsenden) muss weiter möglich sein.
- Keine Anzeige auf Bestellübersicht, Archiv oder gebuchten Belegen.
- Keine Änderung an der Seite „Workshop Lines“ selbst.

## Decisions

**FlowField auf dem Einkaufskopf (TabExt 60304, Feld 60301)**
`field(60301; "CXW No. of Workshop Lines"; Integer)` mit `FieldClass = FlowField`, `CalcFormula = count("CXW Workshop Line" where("CXW Document Type" = field("Document Type"), "CXW Document No." = field("No.")))`, `Editable = false`, `BlankZero = true`. Integer statt Boolean („Werkstattzeilen vorhanden“), weil die Anzahl mehr Information liefert, als Leerwert trotzdem „keine vorhanden“ ausdrückt und `BlankZero` den Nullfall unauffällig hält. Feld liegt in der bestehenden Purchase-Header-Erweiterung, statt eine neue Tabellenerweiterung anzulegen.

**Anzeige auf der Bestellung (PageExt 60328)**
Neuer `layout`-Abschnitt mit `addlast(General)`. Das FlowField wird über die Seite automatisch berechnet (sichtbares FlowField auf Card-Seite). Expliziter `OnDrillDown`-Trigger statt Standard-DrillDown: Der Standard-DrillDown würde die `DrillDownPageId` der Tabelle 60318 nutzen, die nicht gesetzt ist; mit dem Trigger ist Page 60338 und der Filter explizit:
```al
WorkshopLine.SetRange("CXW Document Type", Rec."Document Type");
WorkshopLine.SetRange("CXW Document No.", Rec."No.");
Page.Run(Page::"CXW Workshop Lines", WorkshopLine);
```
Alternative `DrillDownPageId = "CXW Workshop Lines"` an Tabelle 60318 setzen – verworfen, um das Tabellenobjekt (auch API-relevant) nicht anzufassen; der Trigger ist lokal und eindeutig.

**Vorabprüfung in `SendLinesToWorkshop`**
Am Anfang (vor dem Sammeln der Zeilennummern):
1. Werkstattzeilen der Bestellung zählen (`WorkshopLine.Count()` mit Filter auf Belegart/Nummer – nicht das FlowField, damit die Prüfung nicht vom Seitenzustand abhängt).
2. Ist die Anzahl > 0: die bereits vorhandene Zeilen-Sammlung (gleicher Filter wie heute) zuerst ausführen; ist die Liste leer → `Message(AllLinesAlreadySentMsg)` und `exit`; sonst `Confirm(WorkshopLinesExistQst, false, Anzahl)` – bei Nein `exit`.
Reihenfolge: erst sammeln, dann prüfen, damit die Rückfrage nur kommt, wenn tatsächlich etwas zu tun ist. Default der Rückfrage ist `false` (versehentliches Doppelsenden vermeiden).

Ohne vorhandene Werkstattzeilen und ohne offene Zeilen bleibt das heutige Verhalten (kein Hinweis) unverändert.

**Labels / Übersetzung**
Neue Labels in PageExt 60328 (englisch im Code, deutsch in `CHX.Webshop.de-DE.xlf`):
- `WorkshopLinesExistQst`: 'There are already %1 workshop lines for this order. Do you want to send the remaining lines to the workshop?' – DE: „Für diese Bestellung gibt es bereits %1 Werkstattzeilen. Möchten Sie die übrigen Zeilen an die Werkstatt senden?“
- `AllLinesAlreadySentMsg`: 'Workshop lines already exist for this order. There are no further lines to send to the workshop.' – DE: „Für diese Bestellung gibt es bereits Werkstattzeilen. Es sind keine weiteren Zeilen an die Werkstatt zu senden.“
- Caption 'No. of Workshop Lines' – DE: „Anzahl Werkstattzeilen“.

## Risks / Trade-offs

- [Feld-ID 60301 auf „Purchase Header“ kollidiert mit einer Erweiterung einer anderen App] → Feld-IDs auf Standardtabellen sind app-übergreifend eindeutig; vor Implementierung per Symbol-Suche prüfen, dass CHX.Base/ChronextBC 60301 auf „Purchase Header“ nicht belegen.
- [FlowField-Berechnung auf jeder Bestellungsanzeige] → `count` über den Primärschlüssel-Präfix (Document Type, Document No.) ist ein Index-Seek, vernachlässigbar.
- [Benutzer ohne Leserecht auf „CXW Workshop Line“] → FlowField und Prüfung schlagen dann fehl; alle Workshop-Benutzer haben „CXW Workshop All“ mit Lese-/Ausführungsrecht. Andere Einkäufer ohne dieses Permission Set würden einen Fehler beim Öffnen der Bestellung sehen → im Test mit reinem Einkaufsbenutzer prüfen; falls nötig `InherentPermissions` / Leserecht im Basis-Permission-Set ergänzen.
- [Gelöschte Werkstattzeilen (Einkaufszeile gelöscht, Status ≠ Processed)] → zählen nicht mehr; gewünscht, da die Anzahl den aktuellen Stand zeigen soll.

## Open Questions

- Soll statt der Rückfrage bei offenen Zeilen ein hartes Blockieren erfolgen (reine Meldung, kein erneutes Senden möglich)? Angenommen: nein, weil das Nachsenden nicht angekommener Zeilen sonst nicht mehr ginge.
- Position des Feldes auf der Bestellung: angenommen Gruppe „Allgemein“ (letztes Feld); alternativ neben „Vendor Order No.“ oder in einer FactBox.
