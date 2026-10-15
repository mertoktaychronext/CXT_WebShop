## 1. Abhängigkeiten (D2)

- [x] 1.1 `app.json`: Abhängigkeit Salini Base App ≥ 28.0.0.13 ergänzen, CHX.Base auf ≥ 28.0.0.1 anheben, Version 27.0.0.26 (app.json stand bereits auf 27.0.0.25; 27.0.0.19 wäre ein Rückschritt)
- [x] 1.2 Symbole laden; bei Fehlern wegen `application` 26.0 auf 27.0.0.0 anheben (Symbole CHX.Base 28.0.0.1 / Salini Base App 28.0.0.13 geladen; Anhebung nicht nötig)

## 2. Feldzugriffe umstellen (D1)

- [x] 2.1 `CXW Availability Change Mgt.` (60348): `QueueItemLedgerEntryChange` auf `"SLPSBC Margin Taxation"`
- [x] 2.2 `CXW Availability Change Mgt.`: Aktualisierung von `"CXW Diff. Taxation Purchase"` auf `"SLPSBC Margin Taxation"`
- [x] 2.3 `CXW Availability Change Mgt.`: Filter in `GetAvailableInventoryQuantity` auf `"SLPSBC Margin Taxation"`
- [x] 2.4 `CXW Realtime Inventory Mgt.` (60350): `"CXW Differential Taxation"` aus `"SLPSBC Margin Taxation"`
- [x] 2.5 Suche im ganzen Projekt: kein Zugriff mehr auf `"CXB Margin Taxation"` (auch nicht in Berichten, Abfragen, API-Seiten)

## 3. Build

- [x] 3.1 Kompilieren mit CodeCop, keine Warnung AL0432 (veraltetes Feld) mehr (fehlerfrei; AL0432 nur noch für die eigene veraltete Tabelle "CXW Sales Price Out. File")

## 4. Doku

- [x] 4.1 Funktionsregister / Gesamtübersicht: Quelle der Differenzbesteuerung = Salini Base App
- [x] 4.2 Release Notes 27.0.0.26: Voraussetzung CHX.Base 28.0.0.1 und Salini Base App 28.0.0.13, Auslieferung zusammen mit CHX.Base (Update-Hinweis in developer-manual-de/en.md)

## 5. Test (Sandbox, zusammen mit CHX.Base 28.0.0.1)

- [x] 5.1 Vor dem Update: verfügbaren Bestand je Besteuerungsart für einen differenz- und einen regelbesteuerten Artikel notieren
- [x] 5.2 Nach dem Update: gleiche Werte (Szenario „Bestand eines vor dem Update gebuchten Postens")
- [x] 5.3 Neuer Zugang (Artikel Buch.-Blatt) eines differenzbesteuerten Artikels → Verfügbarkeitsänderung mit „Diff. Taxation Purchase = Ja"
- [x] 5.4 Echtzeitbestand für diesen Posten → „Differential Taxation = Ja"

## 6. Auslieferung

- [x] 6.1 Produktiv im selben Wartungsfenster wie CHX.Base 28.0.0.1 (Migration Plan der CHX.Base-Change, Schritt 2)
