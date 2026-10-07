## Why

Die externe Werkstatt erhält über die Workshop-Lines-API heute nur Beleg-Schlüssel, Artikelnummer und Herstellerseriennummer. Für die Echtheitsprüfung braucht sie zusätzlich Angaben zur Bestellung (Lieferant, Lieferantenbestellnummer, Menge, Preis, Gebrauchtware) und zur Uhr (Marke, Modell, Box, Zertifikat, Zustand usw.). Sie hat diese Felder ausdrücklich angefragt.

## What Changes

- Die API `workshopLines` (Page 60339) liefert zusätzlich, nur lesend: `tenant`, `vendorOrderNo`, `vendorNo`, `vendorName`, `variantCode`, `description`, `brand`, `model`, `box`, `certificate`, `condition`, `quantity`, `unitPrice`, `seller_currency`, `usedGoods` sowie `subModel`, `ref`, `year` (immer enthalten, leer bzw. `0` ohne Wert).
- Tabelle 60318 "CXW Workshop Line" erhält Felder für diese Werte. Sie werden bei **"Send to Workshop"** aus Bestellkopf, Bestellzeile und den Standard-Artikelattributen ("Item Attribute Value Mapping", Attribut-IDs 1, 2, 3, 5, 8, 10, 11, 13) übernommen (Momentaufnahme zum Zeitpunkt der Übergabe an die Werkstatt).
- `tenant` kommt aus dem neuen Einrichtungsfeld "Workshop Tenant" in der Einkaufseinrichtung (Wert `GmbH`) und wird zur Laufzeit gelesen.
- Eine Upgrade-Codeunit befüllt die neuen Felder für bestehende, noch nicht verarbeitete Workshop-Zeilen (Status `New` und `WS checked`).
- Die neuen Felder sind über die API nicht änderbar. Ein PATCH mit geänderten Werten wird abgelehnt, wie bei den bestehenden Schlüsselfeldern.
- Die interne Seite "CXW Workshop Lines" (60338) zeigt die neuen Felder an.
- Das Permission Set "CXW Workshop API" erhält nur Lesezugriff auf die Einkaufseinrichtung (für `tenant`); Bestellung, Lieferant und Artikel bleiben gesperrt.

## Capabilities

### New Capabilities
- `workshop-line-api-purchase-data`: Zusätzliche Bestell- und Uhrendaten in der Workshop-Lines-API, ihre Herkunft, der Zeitpunkt der Übernahme und der Schreibschutz.

### Modified Capabilities
- (keine) – Die Basis-Capability `workshop-line-api` liegt nicht unter `openspec/specs/` (fehlplatziert im Archiv, siehe Entwicklerhandbuch). Die Erweiterung wird daher als eigene Capability beschrieben.

## Impact

- `src/Tables/Tab60318.CXWWorkshopLine.al`: neue Felder.
- `src/PageExtensions/PagExt60328.CXWWorkshopPurchaseOrder.al`: `CreateWorkshopLine` befüllt die neuen Felder.
- `src/Pages/Pag60339.CXWWorkshopLineAPI.al`: neue API-Felder, Schreibschutz in `OnModifyRecord`.
- `src/Pages/Pag60338.CXWWorkshopLines.al`: Anzeige.
- Neu: Upgrade-Codeunit für die Befüllung bestehender Zeilen.
- `src/PermissionSets/CXWWorkshopAll.permissionset.al`: Lesezugriff auf "General Ledger Setup" und Ausführung der neuen Codeunit für Benutzer, die "Send to Workshop" ausführen.
- `src/TableExtensions/TabExt60322.CXWSWPurchasesSetup.al`, `src/PageExtensions/PagExt60330.CXWSWPurchasesSetup.al`: Einrichtungsfeld "Workshop Tenant".
- Übersetzungen, Handbücher.
- Externe Werkstatt: Die API-Antwort wird um Felder ergänzt; bestehende Felder und der Endpunkt bleiben unverändert (nicht breaking).
- Die Antworten der Werkstatt vom 2026-09-28 sind eingearbeitet (siehe design.md, Context). Offen ist nur die Bestätigung der Attribut-IDs.
