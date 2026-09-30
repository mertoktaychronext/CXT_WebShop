## Why

Aus SellWatch-Angeboten erzeugte Artikel werden heute für alle Angebotsarten mit derselben Artikelvorlage angelegt; Kommissionsware braucht aber eine eigene Grundeinrichtung (z. B. andere Buchungsgruppen/Kategorie) als angekaufte Ware. Zusätzlich wird die Vorlage per `Item.TransferFields` angewendet, wodurch u. a. Standarddimensionen der Vorlage verloren gehen, Validierungen nicht laufen und die Nummernserie der Vorlage ignoriert wird.

## What Changes

- Neues Setup-Feld in der Einkaufseinrichtung (Gruppe „SellWatch“) für die **Artikelvorlage für Kommission** (Angebotsart `commission`).
- Das bestehende Feld `"CXW SW Item Template Code"` bleibt erhalten und dient künftig als **Standard-Artikelvorlage für alle anderen Angebotsarten** (Caption/Tooltip werden entsprechend angepasst; keine Datenmigration nötig).
- `CreateSellWatchItem` wählt die Vorlage anhand von `"CXW Offer Type"`: `commission` → Kommissionsvorlage, sonst → Standardvorlage.
- Umstellung der Artikelanlage von `Item.TransferFields(ItemTemplate, true)` auf den Standard `Codeunit "Item Templ. Mgt."` (`CreateItemFromTemplate`). Dadurch werden Standarddimensionen der Vorlage übernommen, Feldvalidierungen ausgeführt und die Artikeleinheit vom Standard angelegt.
- Das manuelle Anlegen des `Item Unit of Measure`-Datensatzes entfällt (übernimmt der Standard).
- Fehlerbehandlung wird auf beide Vorlagen ausgeweitet (fehlend / nicht mehr vorhanden, jeweils mit Nennung der betroffenen Vorlage).
- Die Nummernserie für SellWatch-Artikel wird über das Feld `"No. Series"` der jeweiligen Artikelvorlage gesteuert (Standardverhalten von `Item Templ. Mgt.`); ohne Serie an der Vorlage gilt die Artikelnummernserie der Lagereinrichtung. Eine eigene SellWatch-Einrichtung für Nummernserien ist nicht nötig; das TODO im Code entfällt.

## Capabilities

### New Capabilities
<!-- keine -->

### Modified Capabilities
- `sellwatch-item-template-setup`: Statt einer Artikelvorlage gibt es zwei (Kommission / Standard), die Auswahl erfolgt nach Angebotsart; die Vorlage wird über den BC-Standard angewendet (inkl. Dimensionen); Fehlerbehandlung gilt je Vorlage.

## Impact

- `src/TableExtensions/TabExt60322.CXWSWPurchasesSetup.al` – neues Feld 60303, Caption des Feldes 60300 angepasst
- `src/PageExtensions/PagExt60330.CXWSWPurchasesSetup.al` – neues Feld in Gruppe „SellWatch“, Tooltips angepasst
- `src/Codeunits/Codeunit60305.CXWSellWatchMgt.al` – `CreateSellWatchItem` (Vorlagenauswahl, Standard `Item Templ. Mgt.`, Wegfall manueller Artikeleinheit), neue/angepasste Labels
- `Translations/*.xlf` – neue/geänderte Captions, Tooltips, Fehlertexte
- `docs/` – Entwickler- und Key-User-Handbücher (DE/EN), Abschnitt SellWatch-Artikelvorlage
- Einrichtung beim Kunden: zweite Artikelvorlage anlegen und in der Einkaufseinrichtung hinterlegen, sonst schlägt die Verarbeitung von Kommissionsangeboten fehl
