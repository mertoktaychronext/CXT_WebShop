## Context

- **API heute:** Page 60339 "CXW Workshop Line API" (`chronext/CXTServices/v1.0`, `workshopLines`) auf Tabelle 60318 "CXW Workshop Line". Gelesen werden Beleg-Schlüssel, `itemNo`, `manufacturerSerialNo`, Status und die Prüfattribute; die Werkstatt schreibt Status, `genuine` und die Attribute zurück. `OnModifyRecord` verbietet Änderungen an den Schlüsselfeldern.
- **Workshop-Zeilen entstehen** nur über die Aktion "Send to Workshop" auf der Einkaufsbestellung (PageExt 60328, `CreateWorkshopLine`). Die Aktion läuft unter dem Einkaufsbenutzer (Permission Set "CXW Workshop All").
- **Berechtigung des Werkstatt-Benutzers:** Permission Set 60302 "CXW Workshop API" = nur `tabledata "CXW Workshop Line" = RM`. Das ist eine bewusste Entscheidung aus dem Basis-Change: kein Zugriff auf Bestellung, Lieferant oder Artikel.
- **Datenquellen:**
  - Bestellkopf: `"Vendor Order No."` (Code[35]), `"Buy-from Vendor No."` (Code[20]), `"Buy-from Vendor Name"` (Text[100]), `"Currency Code"` (leer = Mandantenwährung).
  - Bestellzeile: `"Variant Code"`, `Description`, `Quantity`, `"Direct Unit Cost"`, ChronextBC-Feld `"Used Good"` (Boolean, TableExt 50109).
  - Standard-Artikelattribute: "Item Attribute Value Mapping" (`"Table ID"` = 27, `"No."` = Artikelnr., `"Item Attribute ID"`) → "Item Attribute Value" (`Value`, Text[250]). Laut Werkstatt gelten die Attribut-IDs brand 1, model 2, subModel 3, ref 5, year 8, condition 10, box 11, certificate 13. Sie entsprechen den Feldnummern von Marke/Modell/Submodell/Referenz/Jahr/Zustand/Box/Zertifikat in ChronextBC "Item Attribute Collection", die ihre Beschriftungen über `"Item Attribute".Get(Feldnummer)` ermittelt. Die Werte sind pro Artikel gepflegt, nicht pro Variante.
- **Antworten der Werkstatt (2026-09-28):** `tenant` = "GmbH"; Uhrendaten aus "Item Attribute Value Mapping" mit obigen IDs; `box`/`certificate` heute "ja"/"nein", Boolean wäre auch möglich; `year` als Zahl; `condition` mit den Werten NEW, AAA, AA, A, VINT; Einkaufspreis ist korrekt, zusätzlich Währung als `seller_currency`; optionale Felder immer mitsenden (`""` bzw. `0`).

## Goals / Non-Goals

**Goals:**
- Alle angefragten Felder plus `seller_currency` in der API-Antwort, lesend.
- Kein Zugriff des Werkstatt-Benutzers auf Bestellung, Kreditor, Artikel oder Attribute; nur Lesezugriff auf die Einkaufseinrichtung für `tenant`.
- Stabile Werte: Die Werkstatt sieht, was zum Zeitpunkt der Übergabe galt.

**Non-Goals:**
- Kein Rückschreiben dieser Felder durch die Werkstatt.
- Keine Änderung an Endpunkt, bestehenden Feldern, Statuslogik oder Verarbeitung (Codeunit 60331).
- Keine Umschlüsselung von `condition`, `box` oder `certificate`: Die gepflegten Attributwerte werden unverändert gesendet.
- Keine Konsolidierung der fehlplatzierten Basis-Spec `workshop-line-api` in diesem Change.

## Decisions

### 1. Momentaufnahme auf der Workshop-Zeile statt Live-Lookup
Die Werte werden in `CreateWorkshopLine` auf neue Felder der Tabelle 60318 kopiert. Die API liest nur noch die Workshop-Zeile.
- *Warum:* Der Werkstatt-Benutzer braucht keine Rechte auf Bestellung, Lieferant oder Artikelattribute. Die Werte sind filterbar (`$filter=vendorNo eq '…'`), und die Zeile behält ihre Daten auch, wenn die Bestellung später storniert und gelöscht wird (das passiert bei widerlegter Echtheit).
- *Alternative A: Live-Lookup in `OnAfterGetRecord` mit `InherentPermissions` auf der API-Page.* Die Werte wären immer aktuell, aber nicht filterbar. Nach einer Stornierung wären sie leer. Verworfen.
- *Alternative B: Permission Set "CXW Workshop API" um Leserechte erweitern.* Das widerspricht der bewussten Isolation aus dem Basis-Change. Verworfen.
- *Folge:* Spätere Änderungen an Bestellung oder Artikel erreichen die Werkstatt nicht. Das ist fachlich gewollt: Die Werkstatt prüft den Stand der Übergabe.

### 2. Neue Felder auf Tabelle 60318

| Nr. | Feld | Typ | Quelle | API-Name |
|---|---|---|---|---|
| 30 | `"CXW Vendor Order No."` | Code[35] | Bestellkopf `"Vendor Order No."` | `vendorOrderNo` |
| 31 | `"CXW Vendor No."` | Code[20] | Bestellkopf `"Buy-from Vendor No."` | `vendorNo` |
| 32 | `"CXW Vendor Name"` | Text[100] | Bestellkopf `"Buy-from Vendor Name"` | `vendorName` |
| 33 | `"CXW Variant Code"` | Code[10] | Bestellzeile `"Variant Code"` | `variantCode` |
| 34 | `"CXW Description"` | Text[100] | Bestellzeile `Description` | `description` |
| 35 | `"CXW Quantity"` | Decimal | Bestellzeile `Quantity` | `quantity` |
| 36 | `"CXW Unit Price"` | Decimal | Bestellzeile `"Direct Unit Cost"` | `unitPrice` |
| 37 | `"CXW Used Goods"` | Boolean | Bestellzeile `"Used Good"` (ChronextBC) | `usedGoods` |
| 38 | `"CXW Currency Code"` | Code[10] | Bestellkopf `"Currency Code"`, leer → `"General Ledger Setup"."LCY Code"` | `seller_currency` |
| 40 | `"CXW Brand"` | Text[250] | Attribut 1 | `brand` |
| 41 | `"CXW Model"` | Text[250] | Attribut 2 | `model` |
| 42 | `"CXW Sub Model"` | Text[250] | Attribut 3 | `subModel` |
| 43 | `"CXW Reference"` | Text[250] | Attribut 5 | `ref` |
| 44 | `"CXW Year"` | Integer | Attribut 8, per `Evaluate` in Ganzzahl umgewandelt | `year` |
| 45 | `"CXW Condition"` | Text[250] | Attribut 10 | `condition` |
| 46 | `"CXW Box"` | Text[250] | Attribut 11 | `box` |
| 47 | `"CXW Certificate"` | Text[250] | Attribut 13 | `certificate` |

- Textlängen der Uhrendaten = Länge von `"Item Attribute Value".Value`, damit beim Kopieren nichts abgeschnitten wird oder die Übernahme abbricht.
- Ist ein Attribut für den Artikel nicht gepflegt, bleibt das Feld leer bzw. `0`. Ist der Jahreswert nicht numerisch (z. B. ein Jahresbereich), wird `0` übernommen. Beides ist kein Fehler; "Send to Workshop" läuft weiter.
- Attribut-IDs als Konstanten in Codeunit 60335. *Warum nicht über Attributnamen:* Die Werkstatt hat die IDs benannt, und die Namen sind übersetzbar bzw. mandantenabhängig.
- *`box`/`certificate` als Text:* Die Werkstatt verarbeitet heute "ja"/"nein"; eine Umwandlung nach Boolean brächte kein fachliches Plus, aber das Risiko, abweichende Werte falsch abzubilden.
- *`seller_currency`:* Der API-Feldname folgt dem Wunsch der Werkstatt (mit Unterstrich) statt der camelCase-Konvention der übrigen Felder.

### 3. `tenant` aus einem Einrichtungsfeld zur Laufzeit
Neues Feld `60302 "CXW Workshop Tenant"` (Text[30]) auf "Purchases & Payables Setup" (TableExt 60322, Anzeige in PageExt 60330, Gruppe der SellWatch-/Workshop-Einstellungen). Der Key User trägt dort `GmbH` ein. Die API-Page liest den Wert in `OnAfterGetRecord` und liefert ihn als `tenant`.
- *Warum ein Einrichtungsfeld statt fest "GmbH":* Der Wert kennzeichnet den Mandanten gegenüber der Werkstatt. Ein weiterer Mandant (z. B. AG) muss einen anderen Wert senden können, ohne Codeänderung.
- *Warum zur Laufzeit statt Momentaufnahme:* Ein nachträglich gepflegter oder korrigierter Wert gilt sofort auch für bereits übergebene Zeilen.
- *Berechtigung:* Das Permission Set "CXW Workshop API" erhält `tabledata "Purchases & Payables Setup" = R`. Die API-Page liest den Wert in `OnOpenPage`.
  - *Verworfen: `InherentPermissions` auf der API-Page.* Auf Pages erlaubt AL dort nur Rechte am Objekt selbst, keine Tabellenrechte auf fremde Tabellen (Compilerfehler AL0776).
  - *Verworfen: Momentaufnahme auf der Workshop-Zeile.* Die Upgrade-Codeunit läuft beim Deploy, bevor der Wert eingetragen werden kann; offene Zeilen hätten dann dauerhaft ein leeres `tenant`.
  - *Abwägung:* Die Einkaufseinrichtung enthält Nummernserien und Buchungsoptionen, aber keine personen- oder preisbezogenen Daten. Der Zugriff auf Bestellung, Kreditor, Artikel und Attribute bleibt gesperrt. Entschieden am 2026-09-28 (Option 1).

### 4. Schreibschutz über die API
Alle neuen Felder sind auf der API-Page `Editable = false`. Zusätzlich prüft `OnModifyRecord` sie wie die bestehenden Schlüsselfelder und lehnt Änderungen mit `FieldNotEditableErr` ab. `tenant` ist ohnehin nicht schreibbar.

### 5. Befüllung bestehender Zeilen
Eine Upgrade-Codeunit (`Subtype = Upgrade`, `OnUpgradePerCompany`, Upgrade-Tag) befüllt die neuen Felder für Workshop-Zeilen mit Status `New` oder `WS checked`, deren Bestellzeile noch existiert. Verarbeitete Zeilen (`Processed`, `Error`) bleiben unverändert: Sie werden von der Werkstatt nicht mehr abgefragt.
- Die Befüllung nutzt dieselbe Prozedur wie `CreateWorkshopLine` in Codeunit 60335 "CXW Workshop Line Mgt.".
- IDs: Codeunit 60335 (Mgt.) und 60336 (Upgrade). 60332–60334 sind auf `02-DEV/SalesPriceExport` belegt und werden gemieden, damit es beim Merge keinen Konflikt gibt.

### 6. Berechtigungen
"CXW Workshop All" enthält bereits Lesezugriff auf "Item Attribute", "Item Attribute Value" und "Item Attribute Value Mapping". Ergänzt werden `tabledata "General Ledger Setup" = R` (Mandantenwährung) und `codeunit "CXW Workshop Line Mgt." = X`. "CXW Workshop API" erhält nur `tabledata "Purchases & Payables Setup" = R` (siehe Entscheidung 3).

## Risks / Trade-offs

- [Gepflegte `condition`-Werte entsprechen nicht NEW/AAA/AA/A/VINT] → Die Werkstatt erhält unerwartete Werte. Mitigation: Vor dem Go-live die Attributwerte von Attribut 10 prüfen; bei Abweichung Werte bereinigen oder ein Mapping als Folge-Change ergänzen.
- [Attribut-IDs sind in einem Mandanten anders vergeben] → Falsche Werte in falschen Feldern. Mitigation: Vor dem Go-live die IDs 1, 2, 3, 5, 8, 10, 11, 13 in "Item Attributes" prüfen (Rückfrage der Anwenderin zur Bedeutung der IDs läuft).
- [Artikelattribute für neue Artikel nicht gepflegt] → Die Uhrenfelder bleiben leer. Mitigation: Handbuchhinweis, Attribute vor "Send to Workshop" pflegen.
- [`tenant` im Setup leer] → Die API liefert `""`. Mitigation: Deploy-Schritt 3.
- [Momentaufnahme veraltet, wenn die Bestellung nach "Send to Workshop" korrigiert wird] → bewusst in Kauf genommen (Entscheidung 1).
- [Merge mit `02-DEV/SalesPriceExport`] → Codeunit- und Feld-IDs sind so gewählt, dass sie nicht kollidieren.

## Migration Plan

1. Deploy mit neuer Version. Der Schema-Sync ist unkritisch (nur neue Felder).
2. Die Upgrade-Codeunit befüllt offene Workshop-Zeilen einmalig.
3. Einkaufseinrichtung: "Workshop Tenant" = `GmbH` setzen.
4. Die Werkstatt über die neuen Felder informieren.
5. Rollback: Vorversion deployen. Die neuen Felder werden dann nicht mehr ausgeliefert; es gehen keine Daten verloren, solange die Felder nicht entfernt werden.

## Open Questions

- Bestätigung der Attribut-IDs (Rückfrage läuft). Der Code-Befund spricht dafür, dass `"Item Attribute".ID` gemeint ist.
