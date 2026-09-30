## Why

Das Kennzeichen "Auftrag halten" am Verkaufsauftrag ist keine Webshop-Funktion, sondern gehört zur allgemeinen Chronext-Basisfunktionalität. Es wurde am 2026-09-29 in CHX.Webshop angelegt (TableExtension 60300) und soll jetzt in die Basis-Extension **CHX.Base** umziehen, damit auch Mandanten bzw. Apps ohne Webshop es nutzen können. Das Feld ist noch nicht produktiv mit Werten in Gebrauch; eine Datenübernahme ist nicht nötig.

## What Changes

- **CHX.Base** (Repository `CHX.Base`, Stand `02-DEV/development`) erhält das Feld "Auftrag halten" am Verkaufskopf samt Anzeige auf Verkaufsauftrag und Verkaufsauftragsliste – mit unverändertem Verhalten (reines Kennzeichen, nur manuell, nur im Status Offen änderbar). Namen folgen den CHX.Base-Konventionen: Feld **"CXB Hold Order"**.
- **CHX.Webshop** entfernt das Feld "CXW Hold Order" (TableExtension 60300), das Feld auf der Seite Verkaufsauftrag (PageExtension 60334, die Aktion "On Demand Lines" bleibt) und die PageExtension 60337 "CXW Sales Order List".
- **BREAKING** (nur technisch): Der Feldname ändert sich von "CXW Hold Order" auf "CXB Hold Order". Bereits gesetzte Werte in Test-/Sandbox-Umgebungen gehen beim Entfernen aus CHX.Webshop verloren (Schema-Synchronisation mit ForceSync).
- CHX.Webshop hebt die Mindestversion der Abhängigkeit CHX.Base auf die neue CHX.Base-Version an.
- Übersetzungen, Handbücher, Funktionsregister und OpenSpec-Specs werden in beiden Repositories nachgezogen.

## Capabilities

### New Capabilities
- (keine in CHX.Webshop) – In CHX.Base entsteht die Capability `sales-order-hold-flag` neu (Spec dort unter `openspec/specs/sales-order-hold-flag/`, inhaltlich wie bisher, mit den neuen Objektnamen).

### Modified Capabilities
- `sales-order-hold-flag`: Wird aus CHX.Webshop vollständig entfernt (alle Anforderungen REMOVED, Migration: CHX.Base).

## Impact

- **CHX.Base:** neue TableExtension auf "Sales Header", neue PageExtensions auf "Sales Order" und "Sales Order List", Übersetzung `CHX.Base.de-DE.xlf`, Handbücher und Funktionsregister unter `docs/`, neue Spec, Version 27.0.3.4 → 27.0.3.5.
- **CHX.Webshop:** `src/TableExtensions/TabExt60300.CXWSalesHeader.al` und `src/PageExtensions/PagExt60337.CXWSalesOrderList.al` entfallen, `src/PageExtensions/PagExt60334.CXWSalesOrder.al` verliert das Feld, `app.json` (Abhängigkeit CHX.Base ≥ 27.0.3.5, eigene Version +1), Übersetzungen, Handbücher, Funktionsregister, Spec.
- **Deployment-Reihenfolge:** zuerst CHX.Base, danach CHX.Webshop.
- Keine Schnittstellen und keine Prozesse betroffen.
