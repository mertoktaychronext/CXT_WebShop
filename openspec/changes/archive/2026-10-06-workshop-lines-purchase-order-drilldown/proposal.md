## Why

Aus der Einkaufsbestellung heraus ist heute nicht erkennbar, ob für den Auftrag bereits Werkstattzeilen existieren, und es gibt keinen direkten Weg dorthin – der Benutzer muss die Liste „Workshop Lines“ separat öffnen und manuell filtern. Außerdem kann „Send to Workshop“ erneut ausgeführt werden, ohne dass der Benutzer darauf hingewiesen wird, dass für den Auftrag schon Werkstattzeilen angelegt wurden.

## What Changes

- Neues FlowField **„No. of Workshop Lines“** (Anzahl Werkstattzeilen) auf dem Einkaufskopf, berechnet per `Count` über „CXW Workshop Line“ mit Belegart und Belegnummer des Kopfes.
- Das FlowField wird auf der Seite **Einkaufsbestellung** (Page 50 „Purchase Order“) angezeigt. Ein Klick (DrillDown) öffnet die Seite **„CXW Workshop Lines“** (Page 60338), gefiltert auf Belegart und Belegnummer der Bestellung.
- Die Aktion **„Send to Workshop“** prüft vor dem Start, ob für die Bestellung bereits Werkstattzeilen existieren:
  - Gibt es bereits Werkstattzeilen und noch nicht gesendete Artikelzeilen, erscheint ein Hinweis mit Rückfrage (Anzahl vorhandener Werkstattzeilen); bei „Nein“ wird abgebrochen.
  - Gibt es bereits Werkstattzeilen und keine offenen Artikelzeilen mehr, erscheint eine Meldung, dass alle Zeilen bereits an die Werkstatt gesendet wurden; es wird nichts verarbeitet.
  - Ohne vorhandene Werkstattzeilen bleibt das Verhalten unverändert.

## Capabilities

### New Capabilities
- `workshop-lines-purchase-order-drilldown`: Anzeige der Anzahl Werkstattzeilen auf der Einkaufsbestellung als FlowField mit DrillDown auf die gefilterte Werkstattzeilen-Liste sowie Hinweis/Rückfrage bei erneutem „Send to Workshop“, wenn bereits Werkstattzeilen existieren.

### Modified Capabilities
<!-- keine: die bestehenden Workshop-Specs beschreiben Seriennummern, API-Daten und Attribut-Vorbelegung, nicht den Aufruf von „Send to Workshop“ selbst -->

## Impact

- `src/TableExtensions/TabExt60304.CXWSWPurchaseHeader.al` – neues FlowField (Feld-ID 60301).
- `src/PageExtensions/PagExt60328.CXWWorkshopPurchaseOrder.al` – Feld auf der Bestellung mit DrillDown, Vorabprüfung in `SendLinesToWorkshop`, neue Labels.
- `Translations/CHX.Webshop.de-DE.xlf` – deutsche Übersetzungen für Feld-Caption, ToolTip und Meldungen.
- Berechtigungen: keine Änderung nötig („CXW Workshop All“ enthält bereits Lesezugriff auf „CXW Workshop Line“ und Ausführung von Page 60338).
- Keine Datenmigration, keine API-Änderung.
