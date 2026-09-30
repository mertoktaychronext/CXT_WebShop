## 0. Klärung (blockiert Teile der Umsetzung)

- [x] 0.1 Antwort des Anfragenden zu `tenant` einholen und Entscheidung 3 in design.md bzw. die Spec anpassen
- [x] 0.2 Antwort zu Quelle und Formaten der Uhrendaten (`box`, `certificate`, `year`, `condition`) sowie zum Währungscode einholen; Entscheidung 2 und Spec bei Bedarf anpassen

## 1. Datenmodell

- [x] 1.1 Tab 60318 "CXW Workshop Line": Felder 30–37 und 40–47 laut design.md, Entscheidung 2 anlegen (Caption, DataClassification, `Editable = false`)

## 2. Befüllung

- [x] 2.1 Neue Codeunit 60335 "CXW Workshop Line Mgt." mit `FillPurchaseData(var WorkshopLine; PurchLine)`: liest Bestellkopf, übernimmt Kopf- und Zeilenwerte, liest "Item Attribute Collection" (`Get(Item No., Variant Code)`) und übernimmt die Uhrendaten; fehlt der Datensatz, bleiben sie leer
- [x] 2.2 PageExt 60328 `CreateWorkshopLine`: `FillPurchaseData` vor `Insert(true)` aufrufen
- [x] 2.3 Upgrade-Codeunit 60336 "CXW Workshop Upgrade" (`Subtype = Upgrade`, `OnUpgradePerCompany`, Upgrade-Tag über Codeunit "Upgrade Tag", Registrierung über `OnGetPerCompanyUpgradeTags`): Zeilen mit Status `New`/`WS checked` und vorhandener Bestellzeile befüllen, `Modify(false)`

## 3. API und Oberfläche

- [x] 3.1 Page 60339: API-Felder `vendorOrderNo`, `vendorNo`, `vendorName`, `variantCode`, `description`, `quantity`, `unitPrice`, `usedGoods`, `brand`, `model`, `subModel`, `ref`, `year`, `condition`, `box`, `certificate` mit `Editable = false`
- [x] 3.2 Page 60339: `tenant` als globale Variable, gesetzt in `OnAfterGetRecord` (vorläufig `CompanyName()`, endgültig nach 0.1)
- [x] 3.3 Page 60339 `OnModifyRecord`: Änderungen an allen neuen Feldern mit `FieldNotEditableErr` ablehnen
- [x] 3.4 Page 60338 "CXW Workshop Lines": neue Felder anzeigen (Uhrendaten standardmäßig `Visible = false`), ToolTips

## 4. Berechtigungen und Übersetzungen

- [x] 4.1 "CXW Workshop All": `tabledata "Item Attribute Collection" = R`, `codeunit "CXW Workshop Line Mgt." = X`, Upgrade-Codeunit falls nötig; "CXW Workshop API" unverändert lassen
- [x] 4.2 Kompilieren, `CHX.Webshop.g.xlf` neu erzeugen, neue Einträge in `CHX.Webshop.de-DE.xlf` übersetzen
- [x] 4.3 `app.json`-Version erhöhen (Upgrade-Codeunit braucht eine höhere Version)

## 5. Prüfung

- [x] 5.1 Kompilieren ohne neue Fehler oder Warnungen
- [ ] 5.2 Test: "Send to Workshop" für eine Zeile mit gepflegten Artikelattributen 1/2/3/5/8/10/11/13 und Bestellung in Fremdwährung → alle Felder inkl. `seller_currency` und `tenant` auf der Workshop-Zeile bzw. in der API-Antwort
- [ ] 5.3 Test: Artikel ohne Attributwerte bzw. mit nicht numerischem Jahr → Workshop-Zeile wird angelegt, Uhrendaten leer, `year` = 0; Bestellung ohne Währung → `seller_currency` = Mandantenwährung
- [ ] 5.4 Test: API-Benutzer nur mit "CXW Workshop API" liest `workshopLines` inkl. `tenant` ohne Berechtigungsfehler, Bestellungen bleiben für ihn gesperrt
- [ ] 5.5 Test: PATCH mit geändertem `vendorNo` wird abgelehnt; PATCH mit `status`/`genuine`/Attributen funktioniert weiter
- [ ] 5.6 Test: Upgrade befüllt offene Zeilen einmalig, verarbeitete bleiben leer

## 6. Dokumentation

- [x] 6.1 `docs/developer-manual-de.md`/`-en.md`: API-Felder, Herkunft, Momentaufnahme, Upgrade-Codeunit
- [x] 6.2 `docs/key-user-manual-de.md`/`-en.md`: Hinweis, dass die Werkstatt Bestell- und Uhrendaten erhält und diese aus der Item Attribute Collection stammen

## 7. Nacharbeit nach den Antworten der Werkstatt (2026-09-28)

- [x] 7.1 Tab 60318: Uhrenfelder 40–43 und 45–47 auf Text[250] verlängern; Feld 38 `"CXW Currency Code"` (Code[10]) ergänzen
- [x] 7.2 Codeunit 60335: Uhrendaten aus "Item Attribute Value Mapping" (Table ID = Item, Attribut-IDs 1/2/3/5/8/10/11/13 als Konstanten) statt aus "Item Attribute Collection"; `year` per `Evaluate`, sonst 0; Währung aus Bestellkopf, leer → `"General Ledger Setup"."LCY Code"`
- [x] 7.3 TabExt 60322: Feld `60302 "CXW Workshop Tenant"` (Text[30]); PageExt 60330: Feld mit ToolTip anzeigen
- [x] 7.4 Page 60339: `tenant` aus "Purchases & Payables Setup"."CXW Workshop Tenant" lesen; "CXW Workshop API" erhält `tabledata "Purchases & Payables Setup" = R` (Option 1, InherentPermissions ist auf Pages für fremde Tabellen nicht möglich); API-Feld `seller_currency` inkl. Schreibschutz
- [x] 7.5 Page 60338: Feld Währung anzeigen, ToolTips der Uhrenfelder auf "Artikelattribut" umstellen
- [x] 7.6 "CXW Workshop All": `tabledata "Item Attribute Collection" = R` entfernen, `tabledata "General Ledger Setup" = R` ergänzen
- [x] 7.7 Kompilieren, Übersetzungen nachziehen (neue und verwaiste Einheiten)
- [x] 7.8 Handbücher (Entwickler, Key User) auf Artikelattribute, `seller_currency` und "Workshop Tenant" umstellen
- [ ] 7.9 Vor Go-live: Attribut-IDs 1/2/3/5/8/10/11/13 und die gepflegten Werte von Attribut 10 (NEW/AAA/AA/A/VINT) im Mandanten prüfen
