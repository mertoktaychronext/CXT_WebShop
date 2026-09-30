## 1. Serienlogik (Codeunit 60335 "CXW Workshop Line Mgt.")

- [x] 1.1 `IsSerialNoTracked(ItemNo): Boolean` – Artikel hat Artikelverfolgungscode mit `"SN Purchase Inbound Tracking"`
- [x] 1.2 `FindPurchLineSerialNo(PurchLine): Code[50]` – erste Seriennr. aus `Reservation Entry` der EK-Zeile (Source Type `Database::"Purchase Line"`, Subtype, ID, Ref. No., `"Serial No." <> ''`)
- [x] 1.3 `AssignNextSerialNo(PurchLine): Code[50]` – `"No. Series".GetNextNo(Item."Serial Nos.")`, Artikelverfolgung über `Create Reserv. Entry` (Menge 1, Status Überschuss, erwartetes Wareneingangsdatum der Zeile)
- [x] 1.4 `GetOrCreateSerialNoInformation(ItemNo, VariantCode, SerialNo; var SerialNoInfo)` – holen oder mit `Insert(true)` anlegen

## 2. Ablauf "Send to Workshop" (PagExt60328)

- [x] 2.1 `ProcessLine` umbauen gemäß design.md D1: nach Ankunftsbestätigung Prüfungen (Menge Basis = 1, SN-Verfolgung), Seriennr. finden oder ziehen (fehlende Nummernserie → Fehlerliste), Seriennr.-Information holen/anlegen
- [x] 2.2 `Page.RunModal(Page::"Serial No. Information Card", SerialNoInfo)`, danach Datensatz neu lesen
- [x] 2.3 Herstellernummer leer → Fehlerliste; lokale `[TryFunction]` um `"CXB Serial No. Bin Enforcement".CheckPresenceMandatory` → bei Fehler `GetLastErrorText` in Fehlerliste
- [x] 2.4 Herstellernummer in `PurchLine."CXW Manufacturer Serial No."` übernehmen, `Sent to Workshop` setzen, `CreateWorkshopLine` unverändert aufrufen
- [x] 2.5 Labels: neue Fehlertexte (keine SN-Verfolgung, keine Seriennr.-Nummernserie, Menge ≠ 1); `SerialNoInputCancelledErr` entfernen; `SerialNoRequiredErr` beibehalten; ToolTip der Aktion anpassen

## 3. Aufräumen & Berechtigungen

- [x] 3.1 `src/Pages/Pag60340.CXWSerialNoInput.al` löschen und alle Verweise entfernen
- [x] 3.2 `CXWWorkshopAll.permissionset.al`: `page "CXW Serial No. Input"` entfernen; `tabledata "Reservation Entry" = RIM`, `tabledata "Serial No. Information" = RIM` ergänzen

## 4. Übersetzungen & Build

- [x] 4.1 Kompilieren ohne Fehler, keine neuen Warnungen in geänderten Dateien
- [x] 4.2 `Translations/CHX.Webshop.de-DE.xlf`: neue Texte übersetzen, Einträge von Page 60340 und `SerialNoInputCancelledErr` entfernen

## 5. Test (manuell in Sandbox)

- [x] 5.1 SN-Artikel ohne Artikelverfolgung auf der EK-Zeile → nächste Nummer gezogen, Artikelverfolgung vorhanden, Karte zeigt die Nummer; Herstellernummer eintragen → Werkstattzeile mit Herstellernummer
- [x] 5.2 EK-Zeile mit bereits zugewiesener Seriennr. → keine neue Nummer, Karte zeigt vorhandene Nummer
- [x] 5.3 Karte ohne Herstellernummer schließen → Zeile in Fehlerliste; erneuter Versand → dieselbe Seriennr.
- [x] 5.4 Artikelverfolgungscode mit „Box Bin Mandatory“, Box nicht angegeben → Zeile in Fehlerliste mit CHX.Base-Meldung
- [x] 5.5 Artikel ohne SN-Verfolgung / ohne Seriennr.-Nummernserie / Menge 2 → jeweils Fehlerliste, keine Karte
- [x] 5.6 Echtheitsprüfung „echt“ über API → Codeunit 60331 bucht Wareneingang mit Seriennummer ohne Fehler

## 6. Dokumentation

- [x] 6.1 `docs/developer-manual-de.md` / `-en.md`: Update-Hinweis, Ablaufskizze „Send to Workshop“ (Page 6504 statt 60340), Objektliste/Berechtigungen
- [x] 6.2 `docs/key-user-manual-de.md` / `-en.md`: Einrichtungsvoraussetzungen (Artikelverfolgungscode, Seriennr.-Nummernserie, CHX.Base-Pflichtkennzeichen)
- [x] 6.3 `docs/user-manual-de.md` / `-en.md`: Bedienablauf „Send to Workshop“ mit Seriennr.-Informationskarte
- [x] 6.4 `docs/funktionsregister/*`: neue Prozeduren in 60335, geänderte Aktion, Page 60340 entfernt, Zählungen
- [x] 6.5 `docs/README.md` Änderungsvermerk
