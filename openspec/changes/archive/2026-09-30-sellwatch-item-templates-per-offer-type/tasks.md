## 1. Einrichtung

- [x] 1.1 `TabExt60322.CXWSWPurchasesSetup.al`: Caption von Feld 60300 `"CXW SW Item Template Code"` auf „SellWatch Item Template (Standard)“ ändern (Name/Nummer unverändert)
- [x] 1.2 `TabExt60322.CXWSWPurchasesSetup.al`: neues Feld `field(60303; "CXW SW Consign. Item Templ."; Code[20])` mit `TableRelation = "Item Templ."`, Caption „SellWatch Item Template (Commission)“, `DataClassification = ToBeClassified`
- [x] 1.3 `PagExt60330.CXWSWPurchasesSetup.al`: neues Feld direkt nach `"CXW SW Item Template Code"` in Gruppe „SellWatch“ einfügen, Tooltips beider Felder anpassen (Standard = alle Angebotsarten außer Kommission; Kommission = Angebotsart `commission`)

## 2. Artikelanlage (Codeunit 60305 "CXW SellWatch Mgt")

- [x] 2.1 Lokale Prozedur `GetSellWatchItemTemplateCode(): Code[20]` anlegen: Vorlagenfeld nach `"CXW Offer Type" = 'commission'` wählen, bei leerem Feld je Vorlage eigenen Fehler, bei nicht existierender Vorlage `ItemTemplateNotFoundErr` mit Code
- [x] 2.2 `CreateSellWatchItem` auf `Codeunit "Item Templ. Mgt".CreateItemFromTemplate(Item, IsHandled, ItemTemplCode)` umstellen; `TransferFields`, `Item."No." := ''`, `Item.Init` und `Item.Insert(true)` entfernen; bei Rückgabe `false` Fehler `ItemNotCreatedFromTemplateErr`
- [x] 2.3 Nach der Vorlagenanwendung Description, Description 2 und (bei `commission`) `"CXB Consignment Sales"` validieren und `Item.Modify(true)` ausführen
- [x] 2.4 Manuelles Anlegen von `Item Unit of Measure` sowie die nicht mehr benötigten Variablen (`ItemTemplate`, `ItemUnitofMeasure`) entfernen; TODO „Nummernserie für SellWatch-Artikel einrichten“ entfernen (erledigt über `"No. Series"` der Vorlage)
- [x] 2.5 Labels anpassen: `NoItemTemplateSetUpErr` → `NoStdItemTemplateSetUpErr` (Text nennt Standardvorlage), neu `NoConsignItemTemplateSetUpErr` und `ItemNotCreatedFromTemplateErr`; `ItemTemplateNotFoundErr` bleibt

## 3. Übersetzungen & Build

- [x] 3.1 Kompilieren (`CHX.Webshop.g.xlf` wird neu erzeugt) und ohne Fehler/Warnungen im geänderten Code bauen
- [x] 3.2 `Translations/CHX.Webshop.de-DE.xlf` synchronisieren: neue/geänderte Captions, Tooltips und Fehlertexte übersetzen, verwaiste Einträge (`NoItemTemplateSetUpErr`) entfernen

## 4. Test (manuell in Sandbox)

- [x] 4.1 Angebot `commission` mit gesetzter Kommissionsvorlage → Artikel aus Kommissionsvorlage, Kennzeichen Kommissionsverkauf gesetzt, Einkaufsbestellung freigegeben
- [x] 4.2 Angebot mit anderer/leerer Angebotsart → Artikel aus Standardvorlage
- [x] 4.3 Standarddimensionen an beiden Vorlagen hinterlegen → erscheinen am neuen Artikel
- [x] 4.3a Nummernserie an einer Vorlage hinterlegen → Artikelnr. kommt aus dieser Serie; ohne Serie an der Vorlage → Nr. aus Lagereinrichtung
- [x] 4.4 Genau eine Artikeleinheit (Basiseinheit, Menge 1) am neuen Artikel, kein Fehler wegen doppelter Einheit
- [x] 4.5 Vorlage mit Beschreibung → Artikelbeschreibung ist trotzdem „Marke Modell Baujahr“, Beschreibung 2 = Referenz
- [x] 4.6 Fehlerfälle: Kommissionsvorlage leer (Standard gesetzt), Standardvorlage leer, Vorlagencode verweist auf gelöschte Vorlage → jeweils passender Fehler, kein Artikel, keine Bestellung
- [x] 4.7 Nach Upgrade von Vorversion: bisher hinterlegte Vorlage steht als Standardvorlage in der Einrichtung

## 5. Dokumentation

- [x] 5.1 `docs/developer-manual-de.md` / `-en.md`: Abschnitt SellWatch-Artikelanlage aktualisieren (zwei Vorlagen, `Item Templ. Mgt.` statt `TransferFields`, Dimensionen, Nummernserie der Vorlage), Update-Hinweis ergänzen
- [x] 5.2 `docs/key-user-manual-de.md` / `-en.md`: Einrichtung beider Vorlagen in der Einkaufseinrichtung beschreiben, inkl. Hinweis „Kommissionsvorlage vor Go-live einrichten“ und dass die Artikelnummernserie je Vorlage über deren Feld „Nummernserie“ gesteuert wird (Serie muss Standardnummern erlauben)
- [x] 5.3 `docs/README.md` Änderungsvermerk ergänzen
