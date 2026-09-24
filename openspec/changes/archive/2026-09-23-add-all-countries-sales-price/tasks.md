## 1. Einrichtung pro Land

- [x] 1.1 Table Extension 60346 "CXW Country/Region" (`src/TableExtensions/TabExt60346.CXWCountryRegion.al`) auf `Country/Region` anlegen: Feld 60300 `"CXW Sales Price Activated"` (Boolean), Feld 60301 `"CXW Sales Price Currency Code"` (Code[10], `TableRelation = Currency`), Captions + DataClassification wie in TabExt60320
- [x] 1.2 Page Extension 60347 "CXW Countries/Regions" (`src/PageExtensions/PagExt60347.CXWCountriesRegions.al`) auf `Countries/Regions` anlegen, beide Felder mit ToolTips anzeigen
- [x] 1.3 Table Extension 60320 "CXWCurrency" und Page Extension 60327 "CXWCurrencies" löschen; per Grep sicherstellen, dass `"CXW Sales Price Activated"` nur noch auf `Country/Region` referenziert wird

## 2. Datenmodell Prüfzeile & Archiv

- [x] 2.1 Table 60312 "CXW Sales Price Checking": Feld 27 `"CXW Country Code"` (Code[10], `TableRelation = "Country/Region"`, Caption 'Country Code') ergänzen; PK auf `("CXW Item No.", "CXW Currency Code", "CXW Country Code")` erweitern
- [x] 2.2 Table 60312: Feld 24 in `"CXW Countries Processed"` (Caption 'Countries Processed') umbenennen; ungenutzte Variable `Country: Record "Country/Region"` entfernen, falls weiterhin unbenutzt
- [x] 2.3 Table 60313 "CXW Sales Price Archive": Feld 27 `"CXW Country Code"` identisch ergänzen; PK auf `("CXW Item No.", "CXW Currency Code", "CXW Country Code", "CXW Version No.")` erweitern
- [x] 2.4 XmlPort 60328: `SourceTableView` auf `sorting("CXW Item No.", "CXW Currency Code", "CXW Country Code")` anpassen

## 3. Aktion "Add all Countries" (Page 60322)

- [x] 3.1 Aktion "Add all Currencies" entfernen und Aktion `AddAllCountries` (Caption 'Add all Countries', ToolTip, `Image = Add`, Promoted wie bisher) anlegen
- [x] 3.2 Vorbedingungen übernehmen (Setup-TestFields, mind. eine Zeile, alle Validated/Accept New Setup, mind. eine Quellzeile mit leerem Land und `"CXW Countries Processed" = false`)
- [x] 3.3 Lokale Prozedur `fnAddAllCountries()` implementieren (Name wegen Konflikt mit der Aktion `AddAllCountries`): Quellzeilen (`"CXW Country Code" = ''`, `"CXW Countries Processed" = false`) × aktivierte Länder; Existenzprüfung per `Get(Item, Landeswährung, Land)`; nach der Länderschleife Quellzeile per `Get(Item, Währung, '')` auf `"CXW Countries Processed" = true` setzen
- [x] 3.4 Hilfsprozedur `CreateCountryLine(Quelle, Land)`: gleiche Währung → Preise + Wechselkursfelder 1:1; abweichende Währung → bestehende Umrechnung via `GetLastestExchangeRate`; Feldübernahme-Block unverändert; `"CXW Country Code"` setzen
- [x] 3.5 Spalte `"CXW Country Code"` (Enabled = false) im Repeater nach `"CXW Currency Code"` ergänzen
- [x] 3.6 Nicht mehr benötigte globale Variable `g_recCurrencies` entfernen bzw. durch `Record "Country/Region"` ersetzen

## 4. Export & Archiv (Codeunit 60329)

- [x] 4.1 `ArchiveCheckingLine`: zusätzlich `SetRange("CXW Country Code", pSalesPriceChecking."CXW Country Code")` für die Versionsermittlung
- [x] 4.2 `CreateExternalInterfaceFile` um Parameter `pCountryCode: Code[10]` erweitern: JSON-Feld `"CXW Country Code"` ergänzen, Dateiname `SalesPrice_<Item>_<Currency>_<Country>.json`
- [x] 4.3 Aufruf in der Aktion "Upload Sales Price" (Page 60322) mit `l_recSalesPriceCheck."CXW Country Code"` anpassen; alle weiteren Aufrufer per Grep prüfen

## 5. Übersetzungen & Berechtigungen

- [x] 5.1 Projekt kompilieren, `Translations/CHX.Webshop.g.xlf` neu erzeugen und `CHX.Webshop.de-DE.xlf` synchronisieren (neue/umbenannte Captions/ToolTips: "Add all Countries", "Country Code", "Countries Processed", "Sales Price Activated", "Sales Price Currency Code"); verwaiste Einträge "Add all Currencies"/"Currencies Processed" entfernen
- [x] 5.2 Permission Set `CXWChronWSAll` prüfen (keine neuen Tabellen, nur Erweiterungen — voraussichtlich keine Änderung nötig)

## 6. Verifikation

- [x] 6.1 Kompilieren ohne Fehler/Warnungen aus den geänderten Objekten
- [ ] 6.2 Sandbox-Test: DE/AT (leere Währung) und CH (CHF) aktivieren, CSV importieren, Validate, Approve, "Add all Countries" → je Quellzeile 3 Länderzeilen, CHF umgerechnet, DE/AT 1:1; zweiter Lauf → "Nothing to process"
- [ ] 6.3 Sandbox-Test: "Upload Sales Price" → je Land ein JSON mit `"CXW Country Code"`, Archiv-Versionen pro Land unabhängig, `"Sales Price"` pro Währung einmal vorhanden
- [ ] 6.4 Publish mit bestehenden Archivdaten testen (PK-Änderung Table 60313) und Ergebnis dokumentieren

## 7. Dokumentation & Abstimmung

- [x] 7.1 Handbücher (`docs/user-manual-*.md`, `docs/key-user-manual-*.md`, `docs/developer-manual-*.md`) auf "Add all Countries" und Ländereinrichtung umstellen; Hinweis zur Umstellung der Currency-Aktivierung und bekannte Einschränkung Fremdwährungs-Quellzeilen aufnehmen
- [x] 7.2 Funktionsregister (`docs/funktionsregister/*.md`) aktualisieren
- [ ] 7.3 `docs/` nach Confluence synchronisieren (Space SOFTWAREEN, Elternseite 344457224)
- [ ] 7.4 Empfänger der Preis-API über neues JSON-Feld `"CXW Country Code"` und Datensätze pro Land informieren
