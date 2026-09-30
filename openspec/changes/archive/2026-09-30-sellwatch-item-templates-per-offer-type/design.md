## Context

`Codeunit 60305 "CXW SellWatch Mgt"` legt pro unverarbeitetem SellWatch-Eintrag Kreditor, Einkaufsbestellung und einen neuen Artikel an (`CreateSellWatchItem`). Der Artikel entsteht heute so:

```
PurchSetup."CXW SW Item Template Code" ──▶ ItemTemplate.Get
Item.TransferFields(ItemTemplate, true)   // Feld-für-Feld nach Feldnummer, ohne Validate
Item."No." := ''                          // sonst stünde der Vorlagencode in der Nr.
Description / Description 2 / CXB Consignment Sales setzen
Item.Insert(true)                         // Nr. aus Lagereinrichtung
Item Unit of Measure manuell einfügen
```

Folgen: keine Standarddimensionen der Vorlage, keine Validierungslogik, `"No. Series"` der Vorlage wird ignoriert, eine Vorlage für alle Angebotsarten.

Im Base App 28.5 bietet `Codeunit "Item Templ. Mgt."`:
- `CreateItemFromTemplate(var Item; var IsHandled; ItemTemplCode: Code[20]): Boolean` – `Item.Init` → `InitItemNo` (Nummernserie der Vorlage, falls gesetzt) → Lager-Bewertungsmethode → `Item.Insert(true)` → `ApplyItemTemplate(..., UpdateExistingValues = true)`.
- `ApplyItemTemplate` → `InitFromTemplate` (nur nicht-leere Vorlagenfelder, danach `Validate`, `SetBaseUoM` legt die Artikeleinheit an) → `Item.Modify(true)` → `InsertDimensions` (Standarddimensionen) → `Item.Get`.

Angebotsart steht in `"CXW SellWatch Vendor Info"."CXW Offer Type"` (Text[250]); im Code wird bereits an drei Stellen gegen `'commission'` verglichen.

## Goals / Non-Goals

**Goals:**
- Zwei Artikelvorlagen: Kommission (`commission`) und Standard (alle anderen Angebotsarten).
- Artikelanlage über `Item Templ. Mgt.` statt `TransferFields`.
- Bestehende Konfiguration ohne Migration weiterverwenden.
- Sprechende Fehlermeldungen je Vorlage.

**Non-Goals:**
- Eigenes SellWatch-Setupfeld für Nummernserien (erledigt über die Vorlagen, siehe D5).
- Änderungen an Kreditor-/Bestellanlage oder am Lagerort-TODO.
- Vereinheitlichung/Case-Insensitivität des `'commission'`-Vergleichs im restlichen Codeunit.
- Weitere Vorlagen je Angebotsart (z. B. eigene für `exchange`).

## Decisions

### D1: Bestehendes Feld 60300 wird zur Standard-Vorlage, neues Feld 60303 für Kommission
Feld `"CXW SW Item Template Code"` (60300) behält Name und Nummer; nur Caption/Tooltip ändern sich auf „SellWatch-Artikelvorlage (Standard)“. Neues Feld `field(60303; "CXW SW Consign. Item Templ."; Code[20])`, `TableRelation = "Item Templ."`, Caption „SellWatch-Artikelvorlage (Kommission)“. Auf der Seite direkt unter dem Standardfeld in Gruppe „SellWatch“.
- *Alternative:* Feld 60300 umbenennen/obsolet setzen und zwei neue Felder anlegen → erfordert Upgrade-Codeunit und Datenmigration ohne fachlichen Mehrwert. Verworfen.
- *Alternative:* Zuordnungstabelle Angebotsart → Vorlage → flexibel, aber Overkill für genau zwei Fälle. Verworfen; ließe sich später nachziehen.

### D2: Vorlagenauswahl in eigener Prozedur, kein Fallback
Neue lokale Prozedur `GetSellWatchItemTemplateCode(): Code[20]` liest `PurchasesSetup`, wählt anhand `SellWatchVendorInfo."CXW Offer Type" = 'commission'` das Feld, prüft „leer“ (eigener Fehlertext je Vorlage) und `ItemTempl.Get` (Fehlertext mit Code). Kein Ausweichen auf die Standardvorlage, wenn die Kommissionsvorlage fehlt – sonst entstünden stillschweigend falsch eingerichtete Kommissionsartikel.
- Vergleich bleibt case-sensitiv `= 'commission'`, konsistent zu `ValidateAndCreateVendor`/`CreatePurchaseOrder`.
- Die Prüfung erfolgt vor `CreateItemFromTemplate`, weil der Standard bei unbekanntem Code nur einen generischen `Get`-Fehler wirft.

### D3: `CreateItemFromTemplate` mit explizitem Vorlagencode, danach SellWatch-Werte setzen
```
ItemTemplCode := GetSellWatchItemTemplateCode();
if not ItemTemplMgt.CreateItemFromTemplate(Item, IsHandled, ItemTemplCode) then
    Error(...);   // tritt nur auf, wenn ein Subscriber via IsHandled abbricht
Item.Validate(Description, ...);
Item.Validate("Description 2", ...);
if commission then Item.Validate("CXB Consignment Sales", true);
Item.Modify(true);
exit(Item."No.");
```
- Mit übergebenem Code zeigt der Standard keinen Auswahldialog → Job-Queue-tauglich.
- `Item."No." := ''` entfällt (Standard setzt die Nr. über `InitItemNo` bzw. `Insert(true)`).
- Manuelles Einfügen von `Item Unit of Measure` entfällt: `SetBaseUoM` legt sie an; ein zweites Insert würde mit „existiert bereits“ scheitern.
- SellWatch-Werte werden **nach** der Vorlage gesetzt, damit eine Vorlagen-Beschreibung sie nicht überschreibt (der Standard wendet mit `UpdateExistingValues = true` an).
- *Alternative:* `Item.Init` + eigene Werte + `Insert(true)` + `ApplyItemTemplate(Item, Templ, false)` → SellWatch-Werte würden nicht überschrieben, aber die Nummernserie der Vorlage (`InitItemNo`) müsste manuell aufgerufen werden und der Standard-Ablauf (Bewertungsmethode, Events) würde nachgebaut. Verworfen.
- Rückgabewert `false` mit `IsHandled = false` ist bei übergebenem Code praktisch unmöglich; wir behandeln ihn trotzdem defensiv mit einem generischen Fehler, damit nie eine leere Artikelnr. an die Einkaufszeile geht.

### D4: Fehlertexte
- `NoStdItemTemplateSetUpErr` – Standardvorlage fehlt (ersetzt `NoItemTemplateSetUpErr`, Text nennt jetzt „Standard“).
- `NoConsignItemTemplateSetUpErr` – Kommissionsvorlage fehlt.
- `ItemTemplateNotFoundErr` – bleibt, `%1` = Vorlagencode.
- `ItemNotCreatedFromTemplateErr` – defensiver Fall aus D3.

### D5: Nummernserie über die Artikelvorlage
Die Artikelnummer wird vom Standard vergeben: `InitItemNo` nutzt `"No. Series"` der gewählten Vorlage; ist dort nichts hinterlegt, vergibt `Item.Insert(true)` die Nummer aus `"Inventory Setup"."Item Nos."`. Damit können Kommissions- und Standardartikel bei Bedarf eigene Nummernkreise bekommen – reine Einrichtung, kein Code. Das TODO „Nummernserie für SellWatch-Artikel einrichten“ in `CreateSellWatchItem` wird entfernt.
- *Alternative:* eigenes Setupfeld „SellWatch-Artikelnummern“ in der Einkaufseinrichtung → dupliziert Standardfunktion. Verworfen.

## Risks / Trade-offs

- [Kommissionsvorlage beim Go-live nicht eingerichtet → Kommissionsangebote brechen in der Job Queue ab] → Hinweis im Key-User-Handbuch und in der Release-Notiz; Einrichtung vor dem Deployment.
- [Validate-Logik läuft jetzt; Vorlagen, die bisher „durchrutschten“ (z. B. ungültige Buchungsgruppen-Kombination), erzeugen nun Fehler] → Beide Vorlagen vor Go-live einmal manuell über „Artikel aus Vorlage anlegen“ testen.
- [Nummernserie an der Vorlage ändert die Artikelnummern sofort, sobald jemand dort eine Serie einträgt] → gewollt (D5); Serie muss „Standardnummern“ erlauben (`TestAutomatic`), sonst Fehler bei der Anlage. Im Key-User-Handbuch dokumentieren.
- [Subscriber anderer Extensions (z. B. CHX.Base) auf `Item Templ. Mgt.`-Events greifen jetzt auch bei SellWatch-Artikeln] → im Test mit CHX.Base 27.0.3.5 prüfen.
- [Vorlage enthält `CXB Consignment Sales`-Feld nicht] → Kennzeichen wird bei `commission` weiterhin explizit gesetzt (D3).

## Migration Plan

1. Deployment: keine Upgrade-Codeunit nötig, Feld 60300 behält seinen Wert (= Standardvorlage).
2. Nach dem Deployment Kommissions-Artikelvorlage anlegen und in der Einkaufseinrichtung (Gruppe „SellWatch“) hinterlegen – idealerweise **vor** dem nächsten Job-Queue-Lauf, sonst ggf. Job-Queue-Posten nach Einrichtung neu starten.
3. Rollback: Vorversion installieren (Downgrade erfordert ggf. Force-Sync, da Feld 60303 wegfällt). Feld 60300 bleibt unberührt, die Vorversion arbeitet damit wie bisher.

## Open Questions

- Soll `'commission'` künftig case-insensitiv verglichen werden (API liefert Freitext)? Aktuell bewusst nicht Teil dieser Änderung.
