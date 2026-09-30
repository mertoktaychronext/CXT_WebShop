## Context

Anwender wollen Verkaufsaufträge als "angehalten" kennzeichnen und danach filtern. Der Standard-Verkaufskopf hat kein solches Feld; CHX.Base und ChronextBC erweitern "Sales Header" nicht (geprüft in den Symbolen unter `.alpackages`). CHX.Webshop hat bisher nur eine Page Extension auf "Sales Order" (60334, Aktion "On Demand Lines"), aber keine Table Extension auf "Sales Header".

Vorgaben aus der Abstimmung vom 2026-09-29: reines Kennzeichen ohne Sperrwirkung, nur manuell gesetzt, bei freigegebenen Aufträgen nicht mehr änderbar.

Der ID-Bereich der App ist 60300–60349 und weitgehend belegt. Für Table Extensions und Page Extensions sind noch IDs frei.

## Goals / Non-Goals

**Goals:**
- Boolean-Feld "Auftrag halten" am Verkaufskopf.
- Bearbeitbar auf dem Verkaufsauftrag, sichtbar und filterbar in der Verkaufsauftragsliste.

**Non-Goals:**
- Keine Sperre von Freigabe, Buchung, Lager oder Versand.
- Kein Grund, kein "gesetzt von/am", keine Historie.
- Kein Setzen über API oder Webshop.
- Keine Anzeige auf Angeboten, Rechnungen, Gutschriften, Archiven oder gebuchten Belegen.

## Decisions

**Table Extension 60300 "CXW Sales Header" mit Feld 60300 "CXW Hold Order" (Boolean).**
Eine neue Table Extension statt eines Felds in einer bestehenden, weil es noch keine auf "Sales Header" gibt. Die Feldnummer folgt dem Muster der übrigen Table Extensions (60300 ff.). `DataClassification = ToBeClassified` wie im restlichen Projekt.
*Alternative:* ein Enum-Feld (z. B. Status "Normal/Angehalten") – verworfen, weil nur Ja/Nein gebraucht wird; ein Boolean lässt sich einfacher filtern.

**Änderung nur im Status Offen: `OnValidate` mit `TestField(Status, Status::Open)`.**
Die Prüfung sitzt im Feld selbst, damit sie auch für Änderungen aus Code, Konfigurationspaketen oder Excel-Bearbeitung gilt, nicht nur für die Seite. Sie verhält sich wie die Standardfelder des Verkaufskopfs: Auch "Genehmigung ausstehend" und "Vorauszahlung ausstehend" sperren das Feld.
*Alternative:* `Rec.TestStatusOpen()` des Standards – verworfen, weil die Prozedur über das Event `OnBeforeTestStatusOpen` von anderen Extensions übersprungen werden kann und ihre Zugänglichkeit aus Extensions nicht garantiert ist. *Alternative:* nur `Editable` auf der Seite – verworfen, weil Änderungen aus Code dann nicht verhindert würden.

**Anzeige in der bestehenden Page Extension 60334 "CXW Sales Order", Gruppe General (`addlast(General)`), mit `Editable = Rec.Status = Rec.Status::Open`.**
Die Seite graut das Feld bei nicht offenen Aufträgen aus, damit Anwender gar nicht erst in den Fehler laufen. Die verbindliche Regel bleibt die Prüfung in der Tabelle.

**Neue Page Extension 60337 "CXW Sales Order List" auf "Sales Order List", Spalte am Ende des Repeaters.**
Damit ist das Feld als Spalte filter- und sortierbar, ohne zusätzliche Aktionen.

**Kein Zurücksetzen beim Kopieren oder beim Umwandeln eines Angebots.**
"Beleg kopieren" und "Angebot → Auftrag" übertragen den Kopf per `TransferFields`; das Kennzeichen wird dabei mitkopiert. Da das Feld nur auf Aufträgen angezeigt wird und nichts sperrt, wird kein Event-Subscriber zum Zurücksetzen gebaut (siehe Risiken).

## Risks / Trade-offs

- [Kopierter Auftrag erbt "Auftrag halten"] → Das ist in der Liste sichtbar und manuell entfernbar. Wenn das stört, später per Subscriber auf das Kopier-Event zurücksetzen.
- [Kennzeichen soll nach Freigabe noch gesetzt werden] → Auftrag erneut öffnen, Feld setzen, wieder freigeben – wie bei anderen Kopffeldern.
- [Anwender erwarten eine Sperre] → ToolTip und Handbuch sagen ausdrücklich, dass das Feld nur ein Kennzeichen ist.
- [Kennzeichen geht beim Archivieren und Buchen verloren] → Gewollt; die Archiv- und Postentabellen erhalten kein Feld.

## Migration Plan

Keine Datenmigration: Bestehende Aufträge erhalten den Standardwert `false`. Deployment über die normale App-Veröffentlichung. Rollback: App-Version zurückspielen; das Feld wird dabei mit seinen Werten entfernt.

## Open Questions

- (keine)
