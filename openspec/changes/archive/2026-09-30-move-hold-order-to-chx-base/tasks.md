## 0. Vorbereitung

- [x] 0.1 CHX.Webshop: Arbeitszweig auf Basis von `02-DEV/development` anlegen (aktuell steht das Repository auf `02-DEV/SPJsonVariant`)
- [x] 0.2 CHX.Base: Arbeitszweig auf Basis von `02-DEV/development` anlegen (Stand nach Pull vom 2026-09-30)

## 1. CHX.Base – Feld und Anzeige anlegen

- [x] 1.1 `src/tableext/CXBSalesHeaderExt.TableExt.al`: TableExtension 60212 "CXB Sales Header Ext." auf "Sales Header", Feld 60200 "CXB Hold Order" (Boolean, Caption `Hold Order`, ToolTip, `DataClassification = CustomerContent`), `OnValidate` mit Statusprüfung nur bei Wertänderung
- [x] 1.2 `src/pageext/CXBSalesOrderExt.PageExt.al`: PageExtension 60217 "CXB Sales Order Ext." auf "Sales Order", Feld per `addlast(General)`, `Editable = Rec.Status = Rec.Status::Open`
- [x] 1.3 `src/pageext/CXBSalesOrderListExt.PageExt.al`: PageExtension 60218 "CXB Sales Order List Ext." auf "Sales Order List", Spalte per `addlast(Control1)`
- [x] 1.4 `app.json`: Version 27.0.3.4 → 27.0.3.5
- [x] 1.5 Vollständig kompilieren, `CHX.Base.g.xlf` neu erzeugen, neue Einträge in `CHX.Base.de-DE.xlf` übersetzen (Caption "Auftrag halten", ToolTip wie bisher)
- [x] 1.6 `openspec/specs/sales-order-hold-flag/spec.md` in CHX.Base anlegen (Anforderungen wie bisher, Objektnamen CXB)
- [x] 1.7 Handbücher und Funktionsregister unter `docs/` in CHX.Base ergänzen (Texte aus CHX.Webshop übernehmen und Objektnamen anpassen)

## 2. CHX.Webshop – Feld und Anzeige entfernen

- [x] 2.1 `src/TableExtensions/TabExt60300.CXWSalesHeader.al` löschen
- [x] 2.2 `src/PageExtensions/PagExt60337.CXWSalesOrderList.al` löschen
- [x] 2.3 `src/PageExtensions/PagExt60334.CXWSalesOrder.al`: `layout`-Block mit "CXW Hold Order" entfernen, Aktion "On Demand Lines" unverändert lassen
- [x] 2.4 `app.json`: Version 27.0.0.9 → 27.0.0.10, Abhängigkeit CHX.Base auf 27.0.3.5
- [x] 2.5 Symbole von CHX.Base 27.0.3.5 bereitstellen, vollständig kompilieren; `CHX.Webshop.de-DE.xlf` mit der neuen `.g.xlf` abgleichen (drei verwaiste Einträge "Hold Order" entfernen)
- [x] 2.6 Handbücher (Anwender, Key User, Entwickler; de/en) und Funktionsregister: Abschnitte zu "Auftrag halten" entfernen bzw. auf CHX.Base verweisen

## 3. Prüfung

- [x] 3.1 In einer Sandbox: CHX.Base 27.0.3.5, danach CHX.Webshop 27.0.0.10 mit ForceSync veröffentlichen – beide Installationen erfolgreich
- [x] 3.2 Verkaufsauftrag: "Auftrag halten" erscheint genau einmal im Register Allgemein, nur bei offenem Auftrag bearbeitbar; Änderung bei freigegebenem Auftrag per Code wird abgelehnt
- [x] 3.3 Verkaufsauftragsliste: Spalte "Auftrag halten" genau einmal vorhanden und filterbar
- [x] 3.4 Aktion "On Demand Lines" auf dem Verkaufsauftrag funktioniert weiterhin
- [x] 3.5 Angehaltener Auftrag lässt sich weiterhin freigeben, liefern und fakturieren
