## 1. Datenmodell

- [x] 1.1 Codeunit-ID 60351 gegen alle offenen Branches/Changes prüfen (ggf. nächste freie ID wählen und Artefakte anpassen)
- [x] 1.2 `Tab60300.CXWSellWatchVendorInfo.al`: Felder `46 "CXW Last Error"` (Text[250]) und `47 "CXW Last Error DateTime"` (DateTime) mit Caption, `Editable = false`, `DataClassification = ToBeClassified`

## 2. Verarbeitung

- [x] 2.1 `Codeunit60305.CXWSellWatchMgt.al`: Schleifenrumpf aus `ValidateAndCreateVendor` (Kreditorsuche/-anlage + `CreatePurchaseOrder`) in `internal procedure ProcessOffer(var SellWatchOffer: Record "CXW SellWatch Vendor Info")` verschieben; setzt die globale `SellWatchVendorInfo`
- [x] 2.2 `CreatePurchaseOrder`: beim bestehenden `SellWatchVendorInfo.Modify()` zusätzlich `"CXW Last Error"` und `"CXW Last Error DateTime"` leeren
- [x] 2.3 Neuer `codeunit 60351 "CXW SellWatch Process Offer"` mit `TableNo = "CXW SellWatch Vendor Info"`, `OnRun` → `SellWatchMgt.ProcessOffer(Rec)`
- [x] 2.4 `ValidateAndCreateVendor` umbauen: offene `"CXW Entry No"` in `List of [Integer]` sammeln; je Eintrag `Get` → `Commit` → `ClearLastError` → `Codeunit.Run(Codeunit::"CXW SellWatch Process Offer", …)`; bei `false` Eintrag neu lesen, Fehlertext (gekürzt) + `CurrentDateTime()` setzen, `Modify`, `Commit`
- [x] 2.5 Prüfen, dass der tote Code (`CreatePurchaseOrderinBV`/`GmBH`) weiterhin kompiliert (nutzt globale `SellWatchVendorInfo`/`VendorRec` unverändert)

## 3. Oberfläche & Berechtigungen

- [x] 3.1 `Pag60307.CXWSellWatchOverview.al`: Felder „Last Error“ und „Last Error Date/Time“ mit ToolTip ergänzen; `StyleExpr` (Unfavorable bei Fehlertext) für SRid und Fehlerfeld, Style-Variable in `OnAfterGetRecord` setzen
- [x] 3.2 Sicherstellen, dass `Pag60337.CXWSellWatchAPI.al` die neuen Felder nicht veröffentlicht (keine Änderung erwartet)
- [x] 3.3 `CXWSWChronWSAll.permissionset.al`: `codeunit "CXW SellWatch Process Offer" = X` ergänzen

## 4. Übersetzungen & Build

- [x] 4.1 Kompilieren ohne Fehler, keine neuen Warnungen in geänderten Dateien
- [x] 4.2 `Translations/CHX.Webshop.de-DE.xlf` um neue Captions/ToolTips ergänzen

## 5. Test (manuell in Sandbox)

- [x] 5.1 Drei offene Angebote, mittleres scheitert (z. B. Kommissionsvorlage leer, Angebotsart `commission`) → die anderen beiden verarbeitet, das mittlere offen mit Fehlertext + Zeitpunkt
- [x] 5.2 Gescheitertes Angebot mit neuem Kreditor: kein Kreditor, keine Bankverbindung, kein Bestellkopf, kein Artikel zurückgeblieben
- [x] 5.3 Aufgabenwarteschlangenposten endet trotz Fehler mit Status „Bereit“/erfolgreich
- [x] 5.4 Ursache beheben, erneut laufen lassen → Angebot verarbeitet, Fehlerfelder leer
- [x] 5.5 Übersicht: fehlerhafte Zeile hervorgehoben, Fehlerfelder nicht bearbeitbar
- [x] 5.6 API-POST mit `lastError`-Property → Wert wird nicht übernommen

## 6. Dokumentation

- [x] 6.1 `docs/developer-manual-de.md` / `-en.md`: Update-Hinweis, Architektur-Skizze SellWatch (Einzelverarbeitung), Objektliste um Codeunit 60351, Bekannte Einschränkungen anpassen
- [x] 6.2 `docs/key-user-manual-de.md` / `-en.md`: Fehlerfelder in der SellWatch-Übersicht, automatische Wiederholung, Troubleshooting-Zeile aktualisieren (Job Queue muss nicht mehr neu gestartet werden)
- [x] 6.3 `docs/funktionsregister/*`: `ProcessOffer`, neuer Codeunit, geänderte Beschreibung von `ValidateAndCreateVendor`, Zählungen
- [x] 6.4 `docs/README.md` Änderungsvermerk
