## 1. Datenmodell

- [x] 1.1 TableExtension 60322 "CXW SW Purchases Setup" auf "Purchases & Payables Setup" angelegt: Feld `CXW SW Item Template Code` (Code[20], TableRelation = "Item Templ.", Field-ID 60300), Caption 'SellWatch Item Template'.
- [x] 1.2 PageExtension 60330 auf Page "Purchases & Payables Setup": neue Gruppe "SellWatch" mit dem neuen Feld ergänzt (`addlast(Content)`, analog zum Muster von PagExt60326), mit ToolTip.

## 2. Verarbeitung

- [x] 2.1 Codeunit 60305 "CXW SellWatch Mgt", Prozedur `CreateSellWatchItem`: `ItemTemplate.FindFirst()` durch `PurchSetup.Get()` + Lesen von `"CXW SW Item Template Code"` ersetzt.
- [x] 2.2 Zwei getrennte Fehlermeldungen ergänzt: `NoItemTemplateSetUpErr` (Setup-Feld leer) und `ItemTemplateNotFoundErr` (Setup-Feld befüllt, aber Artikelvorlage existiert nicht mehr, mit `%1` = Code). Altes Label `NoItemTemplateFoundErr` entfernt (keine verbleibenden Referenzen, geprüft).
- [x] 2.3 `// TODO: Item Template einrichtenbar, Wo?; Evtl Nummernserie fuer SellWatch Artikel einrichten` entfernt; eigener `// TODO: Nummernserie für SellWatch-Artikel einrichten` für den weiterhin offenen Nummernserien-Aspekt stehen gelassen.

## 3. Berechtigungen

- [x] 3.1 Permission Set 60310 "CXW SWChronWSAll" um `tabledata "Purchases & Payables Setup" = R` ergänzt.

## 4. Übersetzungen

- [x] 4.1 `Translations/CHX.Webshop.g.xlf` per `al compile` regeneriert; `Translations/CHX.Webshop.de-DE.xlf` synchronisiert: neue Feld-Caption ("SellWatch Item Template" → "SellWatch-Artikelvorlage"), Gruppen-Caption ("SellWatch", unübersetzt als Markenname), ToolTip und beide neuen Fehlermeldungs-Labels übersetzt; alte, verwaiste `NoItemTemplateFoundErr`-Übersetzung entfernt. 440/440 Trans-Units zwischen g.xlf und de-DE.xlf abgeglichen, keine leeren Targets, valides XML.

## 5. Dokumentation

- [x] 5.1 `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md` und `gesamtuebersicht.md`: neue TableExtension 60322, PageExtension 60330 dokumentiert, `CreateSellWatchItem`-Beschreibung und Permission-Set-Beschreibung aktualisiert, Objektzahlen (50→52) und Changelog ergänzt.
- [x] 5.2 Setup-Hinweis ergänzt in `docs/key-user-manual-de.md` und `docs/key-user-manual-en.md` (neuer Abschnitt "SellWatch – Artikelvorlage einrichten" nach dem bestehenden Online-Check-Abschnitt, neue Troubleshooting-Zeile, Berechtigungs-Hinweis aktualisiert) — passender bestehender Ort als ein generisches README, da das Projekt Setup-Anleitungen im Key-User-Handbuch führt; `docs/README.md`-Changelog ergänzt.

## 6. Prüfung

- [x] 6.1 AL-Extension kompiliert fehlerfrei — verifiziert per `al compile` (Microsoft AL Compiler 18.0.37.11445) gegen `.alpackages`: 52/52 Dateien (2 neue), 0 Fehler, 1 vorbestehende Warnung (AL0603, Codeunit60330, nicht Teil dieser Änderung); Field-ID 60300 auf "Purchases & Payables Setup" kollisionsfrei bestätigt.
- [x] 6.2 Code-Pfad statisch geprüft (kein Live-BC verfügbar): `PurchSetup.Get()` (Singleton, leerer Primärschlüssel) → Leer-Prüfung → `NoItemTemplateSetUpErr` bzw. `ItemTemplate.Get(...)` fehlgeschlagen → `ItemTemplateNotFoundErr` mit korrektem `%1`-Parameter; danach unveränderte Weiterverarbeitung mit der aufgelösten `ItemTemplate`-Variable. Fehlerpropagation über `Error()` verhält sich wie zuvor (kein Try-Wrapper vorhanden oder nötig, unverändert gegenüber dem bisherigen Verhalten).
