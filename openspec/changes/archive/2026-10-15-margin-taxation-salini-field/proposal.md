## Why

Das Kennzeichen „Differenzbesteuerung" zieht von CHX.Base in die **Salini Base App** um (Salini Base App 28.0.0.13: Feld `"SLPSBC Margin Taxation"`, Nr. 5729377; CHX.Base 28.0.0.1, Change `margin-taxation-to-salini-base`). Ab CHX.Base 28.0.0.1 wird das alte Feld `"CXB Margin Taxation"` (60200) nicht mehr gefüllt und ist veraltet.

CHX.Webshop liest das alte Feld auf den **Artikelposten**, um Verfügbarkeitsänderungen und den Echtzeitbestand an den Webshop zu melden (getrennt nach Differenz- und Regelbesteuerung). Ohne Umstellung würden alle nach dem Update gebuchten Artikelposten als „nicht differenzbesteuert" gemeldet und die Bestände je Besteuerungsart falsch berechnet.

## What Changes

- **Lesezugriffe umstellen** von `ItemLedgerEntry."CXB Margin Taxation"` auf `ItemLedgerEntry."SLPSBC Margin Taxation"`:
  - `CXW Availability Change Mgt.` (Cod. 60348): `QueueItemLedgerEntryChange`, Aktualisierung von „Diff. Taxation Purchase" eines Verfügbarkeitseintrags, Filter in `GetAvailableInventoryQuantity`.
  - `CXW Realtime Inventory Mgt.` (Cod. 60350): Füllen von „Differential Taxation" im Echtzeitbestand.
- **Abhängigkeiten:** direkte Abhängigkeit auf die **Salini Base App ≥ 28.0.0.13** (das Feld liegt dort, transitive Abhängigkeiten reichen in AL nicht), CHX.Base auf **≥ 28.0.0.1**.
- **Auslieferung zusammen mit CHX.Base 28.0.0.1** im selben Wartungsfenster.
- **Unverändert:** eigene Felder „CXW Diff. Taxation Purchase" / „CXW Differential Taxation", API und Webshop-Schnittstelle, Berechnungslogik.

## Capabilities

### New Capabilities
- `webshop-availability-margin-taxation`: Woher Verfügbarkeitsänderungen und Echtzeitbestand die Information „differenzbesteuert" eines Artikelpostens beziehen und wie sich das beim Umstieg von CHX.Base auf die Salini Base App verhält.

### Modified Capabilities
<!-- keine – für Verfügbarkeitsänderungen/Echtzeitbestand gibt es noch keine Spec unter openspec/specs/ -->

## Impact

- `src/Codeunits/Codeunit60348.CXWAvailabilityChangeMgt.al` (3 Stellen), `src/Codeunits/Codeunit60350.CXWRealtimeInventoryMgt.al` (1 Stelle), `app.json`.
- Keine Schema-Änderung, kein Upgrade-Code. Version 27.0.0.26.
- Bestehende Einträge in „Verfügbarkeitsänderungen" und „Echtzeitbestand" behalten ihre Werte; die Datenübernahme der Artikelposten erledigt das Upgrade von CHX.Base.
