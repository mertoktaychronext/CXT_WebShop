# Entwicklerhandbuch – SL Chronext Webshop

## Überblick

Diese Business-Central-Erweiterung (AL) bildet die Verwaltung von Webshop-Verkaufspreisen ab: CSV-Import in eine Zwischenablage-Tabelle, fachliche Prüfung (Marge, Preisschwankungen), Freigabe durch einen Sachbearbeiter, optional die automatische Vervielfältigung eines Preises auf alle aktivierten Fremdwährungen, und das Hochladen freigegebener Preise an ein externes System. Die Aktion "Release Sales Prices" schreibt jeden freigegebenen Länderpreis in die Standardtabelle "Sales Price", archiviert den DE-Preis versioniert in "CXW Sales Price Archive", hält den Preis jedes Landes in "CXW Sales Price Export" fest und plant ihn als "Data Export Entry" ein; ein Job in der Aufgabenwarteschlange sendet ihn an eine konfigurierbare API-Schnittstelle. Ein zweiter, unabhängiger Baustein für dateibasierten Preisimport (nicht produktiv angebunden) rundet das Projekt ab. Das Projekt ist eine Migration aus einem gewachsenen Dynamics-NAV-Altsystem in modernes, SaaS-fähiges AL.

> **Update 2026-08-10:** Alle 26 Objekte dieser Erweiterung (bisher IDs 51000–51007, Präfix „SL") wurden reinen Rename/Renumber-Charakters in den registrierten idRange-Block 60311–60336 (Präfix „CXW") verschoben, ebenso alle von ihnen definierten Felder (Präfix „CXW "/„CXW"). Geschäftslogik, Verhalten und Feld-Captions sind unverändert. Zwei Bezeichner mussten wegen des 30-Zeichen-Limits von AL zusätzlich gekürzt werden: Table 60316 „CXW Price Import Protocol" (ohne „Sales" im Bezeichner) und das Feld „CXW Non Stock Price Thresh %" auf Table 60311 (Caption weiterhin "Non Stock Price Threshold %"). Dieses Handbuch wurde entsprechend aktualisiert.

Als zweiter, fachlich unabhängiger Baustein enthält die Erweiterung **SellWatch**: Ankaufsanfragen für gebrauchte Uhren, die vom Partner SellWatch eingehen, werden automatisiert zu Lieferant und Einkaufsbestellung verarbeitet (Codeunit 60305 "CXW SellWatch Mgt"); eine schreibgeschützte Übersichtsseite (Page 60307 "CXW SellWatch-Overview") zeigt Verkäufer-, Uhren- und Bestelldaten. Ein separater Mechanismus prüft per HTTP, ob eine Uhr im SellWatch-Onlineshop sichtbar ist (Table 60301 "CXW Watch Online Approval"), und protokolliert jeden Aufruf inklusive Fehlertelemetrie (Table 60302 "CXW Http Call Log", Page 60309). SellWatch und die Verkaufspreisverwaltung sind fachlich getrennt, teilen sich aber dieselbe Schnittstellen-Stammdatentabelle "CXW API Interface Setup" (Table 60317) sowie seit dem HTTP-Logging-Update das gemeinsame Protokoll `"CXW Http Call Log"`: der Online-Check verwendet dort den fest verdrahteten Code `'WOA'`.

Als dritter, ebenfalls fachlich unabhängiger Baustein enthält die Erweiterung die **Workshop-Ankaufsprüfung** (Enum 60337, Table 60318, TableExtension 60321, PageExtension 60328/60329, Pages 60338–60339, Codeunit 60331, PermissionSets 60301/60302): Angekaufte Uhren werden nach Ankunft über die Aktion "Send to Workshop" auf der Purchase-Order-Page an eine externe Werkstatt übergeben (inkl. Erfassung der Herstellerseriennummer), die per bidirektionaler Custom-API (Page 60339, OAuth2-S2S-authentifiziert) Echtheit und Artikelmerkmale zurückmeldet. Eine job-queue-gesteuerte Codeunit (60331) verarbeitet geprüfte Zeilen: bei bestätigter Echtheit wird nur der Wareneingang gebucht und die gemeldeten Attribute werden als Standard-Artikelattribute übernommen; bei widerlegter Echtheit wird die Bestellung storniert. Details siehe Abschnitt "Workshop-Ankaufsprüfung" unten.

Als vierter, neuer Baustein enthält die Erweiterung den **Kommissionsverkauf** (Enum 60343, Table 60341, Codeunit 60344/60345, Page 60342): Wird eine VK-Rechnung mit einer Zeile eines Artikels mit `"CXB Consignment Sales"` = true (Feld aus der Dependency CHX.Base) gebucht, legt ein Event-Subscriber auf `Codeunit "Sales-Post"` einen Kommissions-Buchungseintrag an und ermittelt dabei automatisch die zugehörige, wareneingebuchte, noch nicht fakturierte Einkaufsbestellung. Eine job-queue-gesteuerte Codeunit bucht fällige Einträge (Fälligkeitsdatum = VK-Buchungsdatum + einrichtbare Verzögerung in Tagen) automatisiert als Einkaufsrechnung. Details siehe Abschnitt "Kommissionsverkauf" unten.

> **Update 2026-09-28 (SalesPrice-Export über die Aufgabenwarteschlange, Version 27.0.0.6):** "Upload Sales Price" ist durch "Release Sales Prices" ersetzt. Die Aktion sendet nicht mehr, sondern schreibt zurück, archiviert **nur noch das Archivland** (neues Setup-Feld "CXW Archive Country Code", Standard DE), speichert den Preis jedes Landes in der neuen Table 60320 "CXW Sales Price Export" und legt einen "Data Export Entry" (`SALESPRICE`) im neuen Status **"CXW Pending"** (Enumextension 60300 auf "Data Export Statuses") an, der nur per `Source Record ID` auf Table 60320 verweist. Quellzeilen ohne Land werden übersprungen. Codeunit 60332 "CXW Export Sales Price Job" baut das JSON im **NAV-kompatiblen Format** (29 camelCase-Schlüssel, siehe unten) und sendet es; Wiederholung bis "CXW Max. Export Attempts", danach manuell über "Requeue Sales Price" (PageExtension 60336). Details: `openspec/changes/sales-price-export-job-queue/`.
>
> Beispiel-Payload:
> ```json
> {"itemNo":"A61087","variantCode":"A61087","salesType":"2","salesCode":"","startingDate":"","currencyCode":"USD","countryRegionCode":"DM","unitOfMeasureCode":"","minimumQuantity":0,"unitPrice":2790,"priceIncludesVat":false,"allowInvoiceDisc":true,"vatBusPostingGrPrice":"","endingDate":"","allowLineDisc":true,"id":"{77BBD1E0-A4D4-451B-A55A-1395CC7230F7}","remark":"","nonStockPrice":0,"lastModifiedUserID":"","lastModifiedDate":"","reasonCode":"CatMan","comment":"","strikePriceInclVat":0,"recomRetailPriceInclVat":0,"unitPriceLcy":2446.72455,"startingTime":"","endingTime":"","profit":0,"unitCost":0,"vatProdPostingGroup":"MDE1900"}
> ```
> Herkunft: Preis-, Gültigkeits- und Textwerte aus Table 60320; `salesType`, `salesCode`, `unitOfMeasureCode`, `minimumQuantity`, `priceIncludesVat`, `allowInvoiceDisc`, `vatBusPostingGrPrice`, `allowLineDisc` aus "Sales Price"; `vatProdPostingGroup`, `unitCost` (`"Unit Cost"`) aus Item; `itemNo`/`variantCode` = "Old Item No."/"Old Variant Code" des Artikels, sonst Artikelnr. bzw. Variantencode (ohne Variante die Artikelnr.); `profit` = Marge in % (Nettopreis LCY über VAT Posting Setup); `reasonCode` = Enum-Name (nicht übersetzt). Entfallen gegenüber NAV: Variante, Promotion-, Set-, DiVA- und Größen/Farb-Felder sowie `priceGroupId`, `fallBackPrice`, `documentUnitPrice`, `deliveryCostLimitCode`, `priceChangeSuggWriteOff`.

> **Update 2026-09-24 (SalesPrice-Export protokolliert in "Data Export Entry"):** Codeunit 60329 schreibt jede Übertragung nicht mehr in Table 60314 "CXW Sales Price Outbound File", sondern – wie der Verfügbarkeitsexport (Codeunit 60347) – in die ChronextBC-Tabelle 50103 "Data Export Entry" (Destination Code `SALESPRICE`, Payload, Dateiname, Status Processed/Error, Fehlermeldung). Der Eintrag wird erst **nach** dem HTTP-Aufruf mit Endstatus angelegt (`CreateDataExportEntry`), weil ChronextBCs "Data Export Mgt." (50102) alle Einträge im Status "Waiting to Process" erneut über "Data Export API Sender" versenden würde. `SALESPRICE` ist reserviert und darf **nicht** als "Data Export API Setup"-Code angelegt werden – sonst würde "Export Data" auf Page 50108 ohne AWS SigV4 senden. "CXW Http Call Log" verweist jetzt auf den "Data Export Entry" ("CXW Source Table No." = 50103). Table 60314 ist `ObsoleteState = Pending` (Tag 27.0.0.3). Konfiguration und Authentifizierung ("CXW API Interface Setup") sind unverändert. Details: `openspec/changes/sales-price-export-data-export-entry/`.

> **Update 2026-09-23 (Add all Countries):** Aktion "Add all Currencies" durch "Add all Countries" ersetzt – Aktivierung und Verkaufspreiswährung jetzt pro Land (Table/Page Extension 60346/60347 auf "Country/Region"), Table/Page Extension 60320/60327 auf "Currency" entfernt, neues Schlüsselfeld "CXW Country Code" auf Table 60312/60313, Ländercode im Export-JSON. Details: `openspec/changes/add-all-countries-sales-price/`.

> **Update 2026-09-28 (Workshop-API: Bestell- und Uhrendaten, Version 27.0.0.7):** Die API `workshopLines` liefert zusätzlich Bestell- und Uhrendaten (siehe Architektur, Abschnitt Workshop-Ankaufsprüfung). Sie werden bei "Send to Workshop" über Codeunit 60335 als Momentaufnahme auf Table 60318 kopiert, damit der Werkstatt-Benutzer keine Rechte auf Bestellung, Kreditor oder Artikel braucht. Uhrendaten kommen aus den Standard-Artikelattributen mit den von der Werkstatt benannten IDs (1, 2, 3, 5, 8, 10, 11, 13), `seller_currency` aus der Bestellwährung (leer → Mandantenwährung), `tenant` aus dem neuen Feld "CXW Workshop Tenant" der Einkaufseinrichtung (TabExt 60322, Feld 60302); dafür hat "CXW Workshop API" zusätzlich Lesezugriff auf "Purchases & Payables Setup" (`InherentPermissions` ist auf Pages für fremde Tabellen nicht möglich). Die Upgrade-Codeunit 60336 befüllt bestehende Zeilen im Status New/WS checked einmalig (Upgrade-Tag `CXW-WORKSHOPLINE-PURCHASEDATA-20260928`). Details: `openspec/changes/workshop-line-api-purchase-data/`.

> **Update 2026-09-30 (Workshop-Attributfelder vorbefüllt, Version 27.0.0.11):** Die Attributfelder, die die Werkstatt zurückschreibt (`dialColor` … `attribute10`, Felder 11–20 auf Table 60318), werden bei "Send to Workshop" aus den gleichnamigen Artikelattributen vorbefüllt (`PrefillEmptyWorkshopAttributes` in Codeunit 60335, nur leere Felder, fehlende Attribute werden nicht angelegt). Hat der Artikel für das englisch benannte Attribut keinen Wert, wird als Fallback das deutsche ChronextBC-Attribut per ID gelesen (Dial Color → 22, Case Diameter → 18, Bracelet Material → 23, Case Material → 16, Movement → 15, Gender → 24, Crystal → 20; Features und Attribut 9/10 ohne Fallback), sonst bleibt das Feld leer. Der Fallback gilt nur für die Vorbefüllung, zurückgeschrieben wird weiterhin in das englisch benannte Attribut. Ein unverändert bestätigter Fallback-Wert wird nicht zurückgeschrieben (`IsUnchangedFallbackValue` in Codeunit 60335: englisches Attribut am Artikel leer und Wert = Fallback-Wert), damit das englische Attribut nicht mit dem deutschen Text befüllt oder neu angelegt wird. Die Werkstatt korrigiert sie bei Bedarf; Codeunit 60331 schreibt sie wie bisher zurück. Die Zuordnung Feld ↔ Attributname liegt jetzt zentral in Codeunit 60335 (`GetWorkshopAttributeName`, `GetWorkshopAttributeValue`, `SetWorkshopAttributeValue`, `WorkshopAttributeCount`) und wird von Vorbefüllung und Rückschreiben gemeinsam genutzt. Der Upgrade-Tag `CXW-WORKSHOPLINE-ATTRIBUTEPREFILL-20260930` befüllt leere Felder offener Zeilen im Status New einmalig. Details: `openspec/changes/workshop-line-prefill-attributes/`.

> **Update 2026-09-30 (SellWatch: Artikelvorlage je Angebotsart, Standard "Item Templ. Mgt."):** Die Einkaufseinrichtung hat zwei SellWatch-Artikelvorlagen: `"CXW SW Item Template Code"` (Feld 60300, jetzt „Standard“ – für alle Angebotsarten außer `commission`, bisheriger Wert bleibt erhalten) und neu `"CXW SW Consign. Item Templ."` (Feld 60303, „Kommission“ – für `"CXW Offer Type" = 'commission'`). `CreateSellWatchItem` (Codeunit 60305) legt den Artikel nicht mehr per `Item.TransferFields` an, sondern über `Codeunit "Item Templ. Mgt".CreateItemFromTemplate(Item, IsHandled, ItemTemplCode)`: Standarddimensionen der Vorlage werden übernommen, Vorlagenfelder validiert, die Artikeleinheit zur Basiseinheit legt der Standard an (manuelles `Item Unit of Measure`-Insert entfernt), die Artikelnummer kommt aus der `"No. Series"` der Vorlage bzw. ohne Serie aus der Lagereinrichtung. Beschreibung, Beschreibung 2 und `"CXB Consignment Sales"` werden danach gesetzt (`Item.Modify(true)`). Vorlagenauswahl und Prüfung in der neuen lokalen Prozedur `GetSellWatchItemTemplateCode`; fehlt die Kommissionsvorlage, gibt es keinen Fallback auf die Standardvorlage. Details: `openspec/changes/archive/2026-09-30-sellwatch-item-templates-per-offer-type/`.

> **Update 2026-09-30 (SellWatch: Angebote einzeln verarbeiten, Fehler am Angebot):** `ValidateAndCreateVendor` (Codeunit 60305) verarbeitet jedes offene Angebot in eigener Transaktion: Eintragsnummern werden vorab gesammelt, je Angebot folgen `Commit`, `ClearLastError` und `Codeunit.Run` auf den neuen Codeunit 60351 "CXW SellWatch Process Offer" (`TableNo` = Table 60300), der die neue interne Prozedur `ProcessOffer` aufruft. Scheitert ein Angebot, wird nur dieses zurückgerollt (kein halb angelegter Kreditor, keine Bestellung ohne Zeile, kein verwaister Artikel), Fehlertext und Zeitpunkt landen in den neuen Feldern `"CXW Last Error"` (46) / `"CXW Last Error DateTime"` (47) auf Table 60300, und der Lauf fährt mit dem nächsten Angebot fort; der Aufgabenwarteschlangenposten endet nicht mehr mit Fehler. Gescheiterte Angebote bleiben offen und werden beim nächsten Lauf automatisch erneut versucht; bei Erfolg werden die Fehlerfelder geleert. Page 60307 zeigt beide Felder und hebt fehlerhafte Zeilen hervor; die API (Page 60337) veröffentlicht sie nicht. `Codeunit.Run` statt `[TryFunction]` (wie in 60331/60345), weil eine TryFunction Datenbankschreibvorgänge nicht zurückrollt. Details: `openspec/changes/archive/2026-09-30-sellwatch-process-offers-individually/`.

> **Update 2026-09-30 (Send to Workshop: Seriennr.-Informationskarte statt eigenem Dialog):** Page 60340 "CXW Serial No. Input" entfällt. "Send to Workshop" (PageExtension 60328) ermittelt je angekommener Zeile die Seriennr. aus der Artikelverfolgung der Einkaufszeile oder zieht die nächste aus `Item."Serial Nos."` und hängt sie als Artikelverfolgung an (neue interne Prozeduren in Codeunit 60335), öffnet dann Page 6504 "Serial No. Information Card" und übernimmt `"CXB Manufacturer Serial No."` (CHX.Base) in Einkaufs- und Werkstattzeile. Zeilen mit Menge ≠ 1, ohne SN-Einkaufsverfolgung, ohne Seriennr.-Nummernserie, mit leerer Herstellernummer oder fehlenden CHX.Base-Pflichtangaben (`CheckPresenceMandatory`) landen in der Fehlerliste. Dadurch kann Codeunit 60331 den Wareneingang seriennummernpflichtiger Artikel ohne manuelle Artikelverfolgung buchen. Permission Set `CXW Workshop All`: Reservation Entry und Serial No. Information jetzt RIM, neu No. Series Line (RM) und Item Tracking Code (R). Details: `openspec/changes/archive/2026-09-30-workshop-send-serial-no-information/`.

> **Update 2026-09-02 (Vollständige Neuverifikation):** Alle 57 AL-Objekte wurden Zeile für Zeile gegen den aktuellen Code (Branch `03-FEAT/Workshop`) abgeglichen. Korrigiert: die Architektur-Skizze verwies noch auf eine "Country/Region"-Table-/Page-Erweiterung, die in dieser Erweiterung nicht (mehr) existiert – die Aktivierung für "Add all Currencies" liegt ausschließlich auf der "Currency". Präzisiert: `CreateSellWatchItem` liest die Artikelvorlage aus `Purchases & Payables Setup."CXW SW Item Template Code"`. Keine Code-Änderungen.

> **Update 2026-08-14 (Kommissionsverkauf ergänzt):** Neue Objekte 60341/60342/60343/60344/60345, neues Setup-Feld `"CXW SW Consignment Invoice Delay (Days)"` auf `TableExtension 60322 "CXW SW Purchases Setup"`. Dabei wurde auch die zuvor als "verloren gegangen" dokumentierte SellWatch-Artikelvorlagen-Konfiguration (siehe Bekannte Einschränkungen, alter Stand) tatsächlich wiederhergestellt und ist seither produktiv im Code vorhanden – der entsprechende Hinweis unten wurde korrigiert. Zusätzlich wurde die bislang falsche Aussage "keine Dependencies" korrigiert: `app.json` hängt seit der Artikelvorlagen-Konfiguration von **CHX.Base** ab.

> **Update 2026-08-13 (Workshop-Ankaufsprüfung nachdokumentiert):** Die Workshop-Ankaufsprüfung existierte bereits seit einer früheren Erweiterung, war aber in keinem der drei Handbücher dokumentiert. Dieses Update ergänzt sie in allen drei Handbüchern (DE/EN) sowie im `docs/README.md`; zusätzlich wurde die veraltete Aussage zu fest hinterlegten SellWatch-Variantencodes korrigiert (siehe Bekannte Einschränkungen) – keine Code-Änderungen.

> **Update 2026-08-10 (HTTP-Call-Logging vereinheitlicht):** Table 60302/Page 60309 hießen zuvor `"CXW SW Http Call Log"` und waren fest mit `"CXW Watch Online Approval"` verdrahtet. Umbenannt in `"CXW Http Call Log"` (Caption `'Http Call Log'`) und um ein neues Feld `"CXW Source Table No."` (gleiches Muster wie `"CXW API Interface Setup"."CXW Source Table No."`) ergänzt, sodass `"CXW Source Entry No"` je nach `"CXW Source Table No."` wahlweise auf `"CXW Watch Online Approval"` (60301) oder `"CXW Sales Price Outbound File"` (60314) verweist. `Codeunit "CXW Export Gateway Sales Price"`'s `SendToApiInterface` protokolliert seither jeden Aufruf (Erfolg, Non-Success-HTTP-Status, Netzwerkfehler) im selben Protokoll wie SellWatch, inklusive Redigierung des `Authorization`-Headers (analog zur bestehenden `X-API-KEY`-Redigierung bei SellWatch). Beide Permission Sets (`CXWChronWSAll`, `CXW SWChronWSAll`) wurden entsprechend angepasst.

> **Update 2026-08-10:** Ebenfalls am 2026-08-10 wurden die 11 SellWatch-Objekte (bisher IDs 51001–51010, uneinheitliche Präfixe „SW"/„SellWatch"/kein Präfix) als reines Rename/Renumber in den registrierten idRange-Block 60300–60310 verschoben und einheitlich mit „CXW " präfixiert, ebenso die rund 70 von ihnen definierten Felder. Feld-Captions, Enum-Werte und Geschäftslogik sind unverändert (siehe `openspec/changes/archive/2026-08-10-sellwatch-cxw-renumbering/`). IDs 60311–60349 waren zu diesem Zeitpunkt bereits für die Verkaufspreisverwaltung reserviert bzw. belegt; SellWatch nutzt seither 60300–60310, der Rest von 60300–60349 bleibt für künftige Objekte frei.

## Technischer Stack

| Komponente | Technologie | Version |
|---|---|---|
| Erweiterungstyp | Microsoft Dynamics 365 Business Central (AL) | Platform/Application 26.0.0.0 |
| Runtime | AL Runtime | 17.0 |
| Objekt-ID-Bereich | Kundenbereich | 60300–60349 (genutzt: 60300–60310 SellWatch, 60311–60336 Verkaufspreisverwaltung, 60318–60345 Workshop-Ankaufsprüfung + Kommissionsverkauf – Objekttypen überschneiden sich, da jeder Objekttyp einen eigenen ID-Namensraum hat; nach dem Kommissionsverkauf sind nur noch 4 IDs frei, 60346–60349); 51000–51049 bleibt registriert, wird aber seit dem Rename vom 2026-08-10 von keinem Objekt dieser Erweiterung mehr belegt |
| Abhängigkeiten | CHX.Base | 27.0.1.1 (liefert u. a. das Item-Feld `"CXB Consignment Sales"`, das der Kommissionsverkauf voraussetzt) |
| Publisher | Salini Life | – |
| Extension-ID | `5df32934-5708-418c-ba16-44b30feb51f4` | – |

## Projektstruktur

```
app.json                          # Extension-Manifest, idRanges 51000-51049 + 60300-60349, Dependency CHX.Base
src/
  Tables/                         # 12 Tabellen (60300-60302 SellWatch; 60311-60317 Verkaufspreisverwaltung; 60318 Workshop; 60341 Kommissionsverkauf)
  TableExtensions/                # 6 Erweiterungen (Purchase Line, Purchase Header, Purchases & Payables Setup – SellWatch/Kommission; Sales Price, Country/Region – Verkaufspreisverwaltung; Purchase Line – Workshop)
  PageExtensions/                 # 5 Erweiterungen (Sales Prices, Countries/Regions – Verkaufspreisverwaltung; Purchase Order, Purchase Order Subform – Workshop; Purchases & Payables Setup – SellWatch/Kommission)
  Pages/                          # 13 Seiten + 1 Xmlport (60307-60309 + 60337 SellWatch; 60321-60325 + Xmlport 60328 Verkaufspreisverwaltung; 60338-60339 Workshop; 60342 Kommissionsverkauf)
  Codeunits/                      # 6 Codeunits (SellWatch Mgt, SellWatch Process Offer – SellWatch; Export Gateway Sales Price, Import Sales Prices – Verkaufspreisverwaltung; Process Workshop Lines – Workshop; Consignment Sale Detection, Post Consignment Purchases – Kommissionsverkauf)
  Enums/                          # 9 Enums (SW Order Status – SellWatch; 6 weitere – Verkaufspreisverwaltung; Workshop Line Status – Workshop; Consignment Posting Status – Kommissionsverkauf)
  PermissionSets/                 # 5 Permission Sets (CXW SWChronWSAll, CXW Sell Watch API – SellWatch; CXWChronWSAll – Verkaufspreisverwaltung; CXW Workshop All [deckt seit dieser Version auch den Kommissionsverkauf ab], CXW Workshop API – Workshop)
Translations/                     # .g.xlf (generiert) + de-DE.xlf (gepflegt)
openspec/
  specs/                          # dauerhafte Capability-Spezifikationen (z.B. sales-price-country-copy, sellwatch-http-call-logging, sellwatch-standard-table-extensions)
  changes/                        # laufende und archivierte Change-Proposals
docs/                             # dieses Handbuch + Funktionsregister
```

**Namenskonvention der Dateien:** `Tab<ID>.<PascalCaseName>.al`, `Pag<ID>.<Name>.al`, `TabExt<ID>.<Name>.al`, `PagExt<ID>.<Name>.al`, `Enum<ID>.<Name>.al`, `Codeunit<ID>.<Name>.al`, `XmlPort<ID>.<Name>.al`.

## Lokale Entwicklungsumgebung einrichten

### Voraussetzungen

- Visual Studio Code mit der offiziellen **AL Language**-Extension.
- Zugriff auf eine Business-Central-Umgebung (Sandbox oder On-Premises) mit Version 26.0 oder kompatibel.
- Die Symbole der Zielumgebung (`.alpackages/`, wird per "Download Symbols" der AL-Extension erzeugt, ist per `.gitignore` von der Versionierung ausgeschlossen).

### Installation

```bash
# Symbole der Zielumgebung herunterladen (in VS Code Command Palette):
AL: Download Symbols

# Projekt kompilieren (VS Code Command Palette):
AL: Package (Kompilieren)

# In verbundene Umgebung veröffentlichen:
AL: Publish
```

Ein Build-/Test-Skript (`Makefile`, `npm`-Scripts o.ä.) existiert in diesem Projekt nicht – der Build läuft ausschließlich über die AL-Extension bzw. AL-Go-Pipelines, falls diese separat eingerichtet werden.

### Konfiguration

Keine Umgebungsvariablen im klassischen Sinn. Relevante Konfiguration erfolgt über `app.json` (`idRanges`, `features: ["NoImplicitWith","TranslationFile"]`) sowie zur Laufzeit über die Tabelle **"CXW General Sales Price Setup"** (siehe Key-User-Handbuch).

## Architektur

```
CSV-Datei
   │  Action "Import CSV"
   ▼
Xmlport 60328 "CXW Import Sales Price"
   │  schreibt Zeilen in
   ▼
Table 60312 "CXW Sales Price Checking"  ◄── Page 60322 "CXW Sales Price Checking List"
   │  (Item No./Currency Code/Country Code – Land leer =    (Validate / Approve / Add all Countries /
   │   importierte Quellzeile; kein Variantencode)            Release Sales Prices)
   │
   │  Action "Release Sales Prices" – nur Länderzeilen ("CXW Country Code" <> ''),
   │  je Zeile per Codeunit.Run(Codeunit 60333 "CXW Release Sales Price Line")
   │  in eigener Transaktion (Fehler → Rollback der Zeile, Export Status = Error)
   │
   ├─► Codeunit 60329.WriteBackAndArchive: legt Standardtabelle "Sales Price"
   │      neu an bzw. aktualisiert sie (Sales Type = All Customers); nur wenn
   │      Land = "CXW Archive Country Code" (Table 60311, Standard DE) zusätzlich
   │      neue, hochgezählte Version in Table 60313 "CXW Sales Price Archive"
   │
   ├─► Codeunit 60329.QueueExport: Table 60320 "CXW Sales Price Export"
   │      (Preisstand des Landes, Unit Price (LCY) bei Freigabe berechnet,
   │      SystemId des "Sales Price") + ChronextBC "Data Export Entry"
   │      (Destination Code SALESPRICE, Source Record ID = Table-60320-Datensatz,
   │      Status "CXW Pending" aus Enumextension 60300 – Insert + Modify in
   │      derselben Transaktion, "Waiting to Process" wird nie committet)
   │      → Prüfzeile Export Status = Queued
   │
   ▼
Aufgabenwarteschlange: Codeunit 60332 "CXW Export Sales Price Job"
   │  wählt SALESPRICE-Einträge mit Status "CXW Pending" oder
   │  Error und "Attempt Count" < "CXW Max. Export Attempts" (Table 60311, 0 → 3);
   │  je Eintrag Commit + Codeunit.Run(Codeunit 60334 "CXW Export Sales Price
   │  Entry"), Laufzeitfehler → SetAttemptResult(Error); der Joblauf selbst
   │  endet nie mit Fehler
   │
   └─► Codeunit 60329.ExportEntry: baut beim ersten Versuch das JSON
          (BuildSalesPriceJson, 30 feste camelCase-Schlüssel aus Table 60320,
          "Sales Price" per GetBySystemId und Item; profit = Marge % auf Basis
          VAT Posting Setup) und speichert es als Payload; Wiederholungen senden
          die gespeicherte Payload unverändert. SendToApiInterface sendet per
          HttpClient an den in Table
          60317 "CXW API Interface Setup" (Übersicht: Page 60324; Detaileinrichtung
          je Schnittstelle inkl. HTTP-Methode/SOAPAction/Authentifizierung:
          Page 60325 "CXW API Interface Setup Card", per Drilldown auf den Code
          oder Aktion "Edit Details" aus Page 60324 erreichbar) hinterlegten Endpunkt –
          ausgewählt über das Feld "CXW API Interface Code" auf Table 60311,
          und setzt über SetAttemptResult Status, Attempt Count, Last Attempt
          At, Processed At bzw. Error Message am bestehenden Eintrag.
          PageExtension 60336 auf ChronextBC-Page 50108 bietet "Requeue Sales
          Price" (Error → CXW Pending, Attempt Count = 0, Payload bleibt).
          SendToApiInterface protokolliert seit dem HTTP-Logging-Update jeden
          Aufruf (Erfolg, Non-Success-Status, Netzwerkfehler) in Table 60302
          "CXW Http Call Log" ("CXW Source Table No." = 50103), Authorization-
          Header redigiert – dasselbe Protokoll, das SellWatch für seinen
          Online-Check nutzt (siehe unten). Seit dem AWS-SigV4-Update unterstützt
          "CXW Auth Type" (Enum 60335) neben None/ApiKeyHeader/BasicAuth auch
          AWSSigV4: SendToApiInterface signiert die Anfrage dann selbst per
          AWS Signature Version 4 (Authorization- und X-Amz-Date-Header, optional
          X-Amz-Security-Token bei temporären/STS-Credentials) – benötigte
          Zusatzfelder auf Table 60317 (siehe Tabellenübersicht unten); Details
          zum Signieralgorithmus siehe
          `openspec/changes/sales-price-aws-sigv4-auth/design.md`. Seit dem
          Conditional-Fields-Update blendet Page 60325 "CXW API Interface Setup
          Card" die authentifizierungsspezifischen Felder (API Key, alle
          AWS-Felder) je nach gewähltem "CXW Auth Type" ein/aus, gesteuert über
          die neuen Table-60317-Prozeduren `IsApiKeyFieldRelevant()` /
          `IsAwsFieldsRelevant()` – dieselben Prozeduren, die auch die
          Aktivierungssperre auf "CXW Active" verwendet, damit beide Stellen
          nicht auseinanderlaufen können. Page 60324 selbst zeigt nur noch die
          Übersichtsspalten (Code, Description, Endpoint URL, Auth Type,
          Active); Details siehe
          `openspec/changes/api-interface-setup-conditional-fields/design.md`.

Steuerdaten für "Add all Countries":
Table Extension 60346 "CXW Country/Region" (auf Standard-Tabelle "Country/Region",
   Felder "CXW Sales Price Activated", "CXW Sales Price Currency Code" – leer = MW)
   ◄── Page Extension 60347 "CXW Countries/Regions" (auf Standard-Seite "Countries/Regions")

"Add all Countries" (Page 60322, lokale Prozeduren fnAddAllCountries/CreateCountryLine)
expandiert jede Quellzeile ("CXW Country Code" leer, "CXW Countries Processed" = false) in
eine Zeile je aktiviertem Land mit dessen Verkaufspreiswährung. Gleiche Währung wie die
Quellzeile → Preise 1:1, sonst Umrechnung über GetLastestExchangeRate. Stock/Recom.
Retail/Strike Price der Länderzeile werden danach immer auf den nächsten vollen 10er
aufgerundet (RoundUpToTen, Change `round-country-sales-price-to-ten`). Die frühere
Aktivierung pro Währung (Table/Page Extension 60320/60327 auf "Currency", Aktion
"Add all Currencies") wurde entfernt (Change `add-all-countries-sales-price`).
Die Enums 60331 "CXW Taxation Type" / 60332 "CXW Sales Price Reason Code" existieren,
wobei 60331 derzeit von keinem Objekt dieser Erweiterung referenziert wird (Table 60300
speichert die Besteuerung als Freitext "CXW Taxation").

Unabhängiger, nicht produktiv angebundener Baustein:
Datei (CSV) → Table 60315 "CXW Sales Price Inbound File"
            → Codeunit 60330 "CXW Import Sales Prices" (OnRun)
            → schreibt direkt in Standard-Tabelle "Sales Price"
            → Fehler in Table 60316 "CXW Price Import Protocol"
```

### SellWatch

```
Table 60300 "CXW SellWatch Vendor Info" (Zeilen extern angelegt – über
Page 60337 "CXW SellWatch API" (PageType = API, siehe unten) oder direkt
in der Tabelle; Berechtigung dazu über das Permission Set 60310
"CXW SWChronWSAll")
   │
   │  Codeunit 60305 "CXW SellWatch Mgt".OnRun → ValidateAndCreateVendor
   │  (Trigger selbst ist nicht im AL-Code verdrahtet – kein Installations-
   │   Codeunit, kein Job-Queue-Eintrag, kein Event-Subscriber im Projekt
   │   gefunden; siehe Bekannte Einschränkungen)
   ▼
Zeilen mit "CXW Created" = false – Eintragsnummern vorab gesammelt, dann JE
ANGEBOT: Commit → Codeunit.Run(60351 "CXW SellWatch Process Offer")
   → SellWatchMgt.ProcessOffer (eigene Transaktion; Fehler rollt nur dieses
   Angebot zurück und schreibt "CXW Last Error"/"CXW Last Error DateTime",
   Angebot bleibt offen und wird im nächsten Lauf wiederholt):
   ├─► sucht per Name/Address/Phone No./E-Mail einen bestehenden "Vendor";
   │      legt sonst einen neuen "Vendor" + "Vendor Bank Account" an
   │      (Bankverbindungscode = letzte 4 Stellen der IBAN + Währungscode)
   │
   └─► CreatePurchaseOrder: legt "Purchase Header" (Document Type = Order)
          und eine "Purchase Line" an – Artikel wird neu angelegt
          (CreateSellWatchItem über "Item Templ. Mgt."; Vorlage je
          "CXW Offer Type": commission → Feld 60303, sonst → Feld 60300
          der Einkaufseinrichtung), Menge 1, Amount und
          "Direct Unit Cost" = "CXW Final Offer Price", "CXW Used good" = true
          (Table Extension 60303 auf "Purchase Line") – gibt die Bestellung
          über Codeunit "Release Purchase Document" (PerformManualRelease)
          frei und markiert die Vendor-Info-Zeile als "CXW Created" = true,
          "CXW PO Number"/"CXW VendorNo" befüllt

Unabhängig davon, je Artikel/Variante:
Table 60301 "CXW Watch Online Approval"
   │  CreateEntryInexternalFile (aktuell aus keiner anderen Stelle im
   │  Code aufgerufen)
   ▼
HTTP GET an <Endpoint URL>/<Item No>/<Variant Code>/check, Header
"X-API-KEY" – Endpoint/Key aus Table 60317 "CXW API Interface Setup",
Code fest verdrahtet auf 'WOA' (dieselbe Tabelle wie die Verkaufspreis-
verwaltung, siehe Codeunit 60329)
   │  Antwortfeld "shouldBeOnline" = 'TRUE' → setzt "CXW Check Online" +
   │  ggf. "CXW First Online Date"; sonst "CXW Remark" = 'Watch is offline'
   └─► protokolliert jeden Aufruf (Erfolg wie Fehlschlag, API-Key im
          gespeicherten Request-Text redigiert) in Table 60302
          "CXW Http Call Log" ("CXW Source Table No." = 60301); bei
          Fehlschlag zusätzlich Telemetrie (Session.LogMessage,
          Event-ID 'SW-0101')

Ansicht (read-only, kein Insert/Modify/Delete über die Seiten):
Page 60307 "CXW SellWatch-Overview" (Liste, SourceTable Table 60300,
   Filter "CXW SRid" <> '', Aktion "Show Document" öffnet die Purchase Order)
Page 60308 "CXW SellWatch info" (CardPart auf Table 60300 – Uhren-Detaildaten)
Page 60309 "CXW Http Call Log" (Liste, SourceTable Table 60302 – jetzt
   gemeinsames Protokoll für SellWatch UND Verkaufspreisverwaltung,
   Spalte "CXW Source Table No." unterscheidet die Quelle; Aktionen
   "Download Request"/"Download Response" laden den jeweiligen Blob als .txt)

JSON-Builder ohne aktuellen Aufrufer im Projekt (vermutlich für externe
Rückmeldungen an SellWatch gedacht, siehe Bekannte Einschränkungen):
Codeunit 60305: CreateSourceFilePurchaseRequest(Purchase Header): Text
Codeunit 60305: CreateSourceFileOrderStatusSE(SellWatch Vendor Info; Enum
   "CXW SW Order Status"): Text
```

#### Page 60337 "CXW SellWatch API" – Schreibzugang für externe Systeme

Ergänzt die reine Anzeige-Seite 60307 um einen `PageType = API`-Endpunkt, über den externe Systeme per HTTP-Aufruf neue SellWatch-Anfragen anlegen oder bestehende ändern können. Beide Seiten liegen über derselben Tabelle 60300, sind aber unabhängige Objekte (eine Page kann nicht gleichzeitig `List` und `API` sein).

- **Endpunkt-Muster:** `.../api/saliniLife/sellWatch/v2.0/companies({companyId})/sellWatchVendorInfos` (Standard-BC-OData-v4-Muster aus `APIPublisher`/`APIGroup`/`APIVersion`/`EntitySetName`); einzelner Datensatz per `.../sellWatchVendorInfos({id})`.
- **Methoden:** `POST` zum Anlegen, `PATCH` zum Ändern; `DELETE` ist nicht erlaubt (`DeleteAllowed = false`).
- **Authentifizierung:** Standard-BC-API-Authentifizierung (Web Service Access Key oder Entra-ID-OAuth) – keine eigene Auth-Logik im AL-Code. Berechtigung zusätzlich über Permission Set 60310 "CXW SWChronWSAll" (Eintrag `page "CXW SellWatch API" = X`).
- **Beschreibbare Felder:** alle Vendor-/Uhren-/Angebotsfelder (u. a. Vendor Name, Adresse, IBAN/BIC, E-Mail, Brand/Model/Reference/SKU, Watch Condition, Offer Type, Final Offer Price, Currency Code, SRid).
- **Nicht beschreibbar (system-eigen):** `CXW Entry No` (Primärschlüssel), `CXW Created`, `CXW PO Number`, `CXW VendorNo` (werden ausschließlich von Codeunit 60305 gesetzt) sowie das FlowField `CXW Tracking Number`. Werte für diese Felder im Payload werden beim Insert/Modify ignoriert bzw. zurückgesetzt.
- **Validierung:** `OnInsertRecord`/`OnModifyRecord` verlangen `CXW SRid`, `CXW Brand`, `CXW Model` und `CXW Final Offer Price` und lehnen ein doppeltes `CXW SRid` mit einem Fehler (HTTP 4xx) ab, statt den Datensatz unvollständig oder doppelt anzulegen.
- Neu angelegte/aktualisierte Zeilen erscheinen unverändert auf Page 60307 und werden von Codeunit 60305 wie manuell erfasste Zeilen weiterverarbeitet.

### Workshop-Ankaufsprüfung

```
Purchase Order (Sachbearbeiter)
   │  Aktion "Send to Workshop" (PageExtension 60328 "CXW Workshop
   │  Purchase Order", auf Page "Purchase Order")
   ▼
Je offener Zeile (Type = Item, Quantity <> 0, Sent to Workshop = false):
   ├─► Confirm "Ist Artikel {No.} {Description} wirklich angekommen?"
   │     Nein → "CXW Not Arrived" := true, Zeile übersprungen (kein Abbruch)
   │     Ja   → Menge (Basis) = 1 und Artikelverfolgungscode mit
   │              "SN Purchase Inbound Tracking"? sonst Fehler für diese Zeile
   │            → Seriennr. aus der Artikelverfolgung der Zeile (Reservation
   │              Entry); keine vorhanden → nächste Nr. aus Item."Serial Nos."
   │              (fehlt → Fehler) und per "Create Reserv. Entry" als
   │              Artikelverfolgung (Menge 1, Überschuss) angehängt
   │            → "Serial No. Information" holen/anlegen, Commit (RunModal ist
   │              in Schreibtransaktionen nicht erlaubt), Page 6504
   │              "Serial No. Information Card" modal (CHX.Base-Felder
   │              Herstellerseriennr., Box/Papiere)
   │            → danach "CXB Manufacturer Serial No." leer oder CHX.Base-
   │              CheckPresenceMandatory (TryFunction) schlägt fehl → Fehler
   │              für diese Zeile gesammelt, weiter mit nächster Zeile
   │              (Seriennr./Artikelverfolgung bleiben für den nächsten
   │              Versuch erhalten)
   ▼
Bei vollständigen Angaben:
   "CXW Manufacturer Serial No." (aus der Seriennr.-Information)
   + "CXW Sent to Workshop" := true auf
   Purchase Line (TableExtension 60321 "CXW Workshop Purchase Line")
   ▼
Table 60318 "CXW Workshop Line" neu angelegt (PK: Document Type/No./
Line No.), Status = New, Item No. aus der Purchase Line übernommen;
Codeunit 60335 "CXW Workshop Line Mgt.".FillPurchaseData kopiert als
Momentaufnahme Bestellkopf (Vendor Order No., Buy-from Vendor No./Name,
Currency Code – leer → GL Setup "LCY Code"), Bestellzeile (Variant Code,
Description, Quantity, Direct Unit Cost, ChronextBC "Used Good") und die
Standard-Artikelattribute des Artikels ("Item Attribute Value Mapping",
Attribut-IDs 1 Marke, 2 Modell, 3 Submodell, 5 Referenz, 8 Jahr per
Evaluate → Integer, 10 Zustand, 11 Box, 13 Zertifikat – fehlt ein Wert,
bleibt das Feld leer bzw. 0) auf Felder 30–38/40–47 der Workshop Line
   │
   │  PageExtension 60329 "CXW Workshop Purch Order Subf" sperrt ab
   │  "Sent to Workshop" = true die Standardfelder der Zeile (Editable = false)
   ▼
Externe Werkstatt liest/schreibt über
Page 60339 "CXW Workshop Line API" (PageType = API, OAuth2-S2S,
   Endpunkt-Muster .../api/saliniLife/workshop/v1.0/companies({companyId})/
   workshopLines; Insert/Delete gesperrt, Statusrückschritte gesperrt)
   │  Werkstatt liest zusätzlich (nur lesend, PATCH-Änderungen abgelehnt):
   │  tenant (zur Laufzeit aus "Purchases & Payables Setup"."CXW Workshop
   │  Tenant", z. B. "GmbH"), vendorOrderNo, vendorNo, vendorName,
   │  variantCode, description, quantity, unitPrice, seller_currency,
   │  usedGoods, brand, model, subModel, ref, year, condition, box,
   │  certificate – alles außer tenant aus der Workshop Line selbst;
   │  "CXW Workshop API" = Workshop Line RM + Purchases & Payables Setup R
   │  Werkstatt setzt: isAuthentic, Attribute 1-10, Status = "WS checked"
   ▼
Codeunit 60331 "CXW Process Workshop Lines" (job-queue-gesteuert, OnRun
   → ProcessCheckedLines, SetRange Status = "WS checked")
   │  pro Zeile: ProcessLineWithErrorHandling kapselt TryProcessLine
   │  ([TryFunction]) – ein Fehlschlag blockiert nicht die übrigen Zeilen
   │
   ├─► Genuine = true → ProcessGenuineLine:
   │      "Qty. to Receive" = Bestellmenge, Codeunit "Purch.-Post"
   │      (Receive = true, Invoice = false), danach GetWorkshopAttributeName
   │      überträgt Attribute 1-8 (fachlich benannt: Dial Color, Case
   │      Diameter, Bracelet Material, Case Material, Movement, Gender,
   │      Crystal, Features; 9-10 weiterhin Platzhalter) als Standard-
   │      Artikelattribute (Item Attribute/Item Attribute Value/Item
   │      Attribute Value Mapping, fehlende Einträge automatisch als
   │      Typ Text angelegt) → Status = "Processed", "CXW Last Error" := ''
   │
   ├─► Genuine = false → ProcessNonGenuineLine:
   │      Status = "Processed" (bewusst VOR dem PO-Löschen gesetzt, damit
   │      der Cascade-Delete-Schutz in TabExt60321 greift), danach
   │      Purchase Order ggf. reopened und gelöscht
   │
   └─► Fehlschlag (beliebige Stelle im Verarbeitungspfad) → Status = Error
          (nur aus "WS checked" heraus erlaubt, sonst OnModify-Fehler),
          "CXW Last Error" = GetLastErrorText(); Commit() nach jeder Zeile
          sichert bereits erfolgreiche Zeilen unabhängig vom Ausgang der
          nächsten

Ansicht (read-only): Page 60338 "CXW Workshop Lines" (Liste, alle Felder
   inkl. Status, Attribute, Last Error)

Löschverhalten (TableExtension 60321, OnDelete der Purchase Line):
   Workshop Line im Status New/WS checked → wird mitgelöscht
   Workshop Line im Status Processed → bleibt als Prüfnachweis bestehen
```

#### Page 60339 "CXW Workshop Line API" – bidirektionaler Zugang für die Werkstatt

Im Unterschied zu Page 60337 (SellWatch, reiner Insert/Update-Empfang) erlaubt diese API sowohl Lesen (offene Zeilen) als auch Schreiben (Prüfergebnis) durch dieselbe externe Partei.

- **Endpunkt-Muster:** `.../api/saliniLife/workshop/v1.0/companies({companyId})/workshopLines`.
- **Methoden:** `GET` zum Abholen, `PATCH` zum Zurückschreiben; `POST`/`DELETE` gesperrt (`InsertAllowed = false`, `DeleteAllowed = false`) – Zeilen entstehen ausschließlich aus BC heraus über "Send to Workshop".
- **Beschreibbare Felder:** `dialColor`, `caseDiameter`, `braceletMaterial`, `caseMaterial`, `movement`, `gender`, `crystal`, `features` (fachlich benannt, entsprechen den AL-Feldbezeichnern 1–8), `attribute9`, `attribute10` (weiterhin generisch, da ohne fachlichen Namen), `genuine`, `status`. Schlüssel-, Artikel- und Seriennummernfelder sind gesperrt (`OnModifyRecord` lehnt Änderungsversuche mit Fehler ab).
- **Update 2026-08-13 (Breaking Change):** Die OData-Eigenschaftsnamen `attribute1`–`attribute8` wurden auf die fachlichen Namen umgestellt (z. B. `attribute1` → `dialColor`). Anders als bei der internen AL-Feldbezeichner-Umbenennung zuvor ist dies eine **Breaking Change am externen API-Vertrag** – der externe Workshop-Dienst muss seine Integration entsprechend anpassen. `attribute9`/`attribute10` bleiben unverändert, da für sie noch kein fachlicher Name vorliegt.
- **Statusrückschritte gesperrt:** greift über den `OnModify`-Trigger der Tabelle selbst (feuert unabhängig davon, ob die Änderung über die API oder intern erfolgt) – `WS checked` → `New` sowie jeder Wechsel weg von `Processed` werden abgelehnt; ein direkter Wechsel auf `Error` ist nur aus `WS checked` heraus erlaubt.
- **Berechtigung:** Permission Set 60302 "CXW Workshop API" – ausschließlich `tabledata "CXW Workshop Line" = RM`, kein Zugriff auf Purchase Line, Item oder andere Tabellen.

### Kommissionsverkauf

```
Purchase Order (Sachbearbeiter/Workshop-Prozess) – Wareneingang bereits gebucht,
noch NICHT fakturiert
   │
Sales Order/Sales Invoice – Zeile mit Item, dessen "CXB Consignment Sales" = true
   │  wird per Invoice gebucht (Liefern & Fakturieren ODER separate Rechnung)
   ▼
Codeunit "Sales-Post".OnAfterPostSalesDoc (Standard-BC-Event)
   │  [EventSubscriber] Codeunit 60344 "CXW Consignment Sale Detection"
   │  .OnAfterPostSalesDocCreateConsignmentEntries
   │  Abbruch (kein Entry), wenn PreviewMode = true oder SalesInvHdrNo = ''
   ▼
Je "Sales Invoice Line" mit Type = Item und Item."CXB Consignment Sales" = true:
   TryCreateConsignmentEntry ([TryFunction], fängt jeden Fehler ab – die
   VK-Buchung selbst darf dadurch nie fehlschlagen)
   │
   ├─► SetPurchaseOrder (public, auch von Codeunit 60345 wiederverwendet):
   │      Purchase Line gefiltert auf Document Type = Order, Type = Item,
   │      No. = Item No., Quantity Received > 0, Qty. to Invoice > 0
   │      1 Treffer   → "CXW Purchase Order No." gesetzt, Status = Open
   │      0/>1 Treffer → Status = Error, sprechender Fehlertext, kein Abbruch
   │
   └─► "CXW Due Date" = Sales Invoice Posting Date + Purchases & Payables
          Setup."CXW SW Consignment Invoice Delay (Days)"
   ▼
Table 60341 "CXW Consignment Posting Entry" (PK: Entry No, AutoIncrement)
   │  Ansicht: Page 60342 "CXW Cons. Posting Entries" (Liste, read-only bis
   │  auf Aktion "Retry": setzt ausgewählte Error-Zeilen zurück auf Open)
   ▼
Codeunit 60345 "CXW Post Consignment Purchases" (job-queue-gesteuert, OnRun
   → ProcessDueEntries, SetRange Status = Open, SetFilter Due Date <= Today)
   │  pro Eintrag: ProcessEntryWithErrorHandling kapselt TryProcessEntry
   │  ([TryFunction]) – ein Fehlschlag blockiert nicht die übrigen fälligen
   │  Einträge, Commit() nach jedem Eintrag
   │
   │  Ist "CXW Purchase Order No." leer (Eintrag kam als 0/>1-Treffer-Error
   │  aus der Erkennung), wird SetPurchaseOrder erneut versucht – sonst würde
   │  "Erneut versuchen" auf Page 60342 wirkungslos bleiben
   ▼
Purchase Header per Get(Order, ...) gelesen; "Vendor Invoice No." falls leer
mit "CXW Sales Invoice No." + "-CONS" befüllt; Purchase Line."Qty. to Invoice"
auf Quantity Received - Quantity Invoiced gesetzt (bricht mit sprechendem
Fehler ab, falls <= 0, statt einer generischen Purch.-Post-Meldung); Receive
= false, Invoice = true, Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader)
   │
   ├─► Erfolg  → Status = Posted, "CXW Error Text" geleert
   └─► Fehlschlag → Status = Error, "CXW Error Text" = GetLastErrorText()
```

## Objektschnittstellen (öffentliche Prozeduren & Events)

Vollständige Liste aller Prozeduren, Trigger und Events: siehe `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`. Die wichtigsten öffentlichen Schnittstellen:

| Objekt | Element | Zweck |
|---|---|---|
| Codeunit 60329 | `WriteBackAndArchive(SalesPriceChecking: Record "CXW Sales Price Checking"; var SalesPrice: Record "Sales Price")` | Schreibt/aktualisiert einen "Sales Price"-Datensatz aus einer freigegebenen Preiszeile (Sales Type = All Customers) und archiviert eine neue Version, falls das Land dem "CXW Archive Country Code" entspricht. Keine TryFunction mehr – Isolation über Codeunit 60333 per `Codeunit.Run`. |
| Codeunit 60329 | `QueueExport(SalesPriceChecking: Record "CXW Sales Price Checking"; SalesPrice: Record "Sales Price")` | Legt den Table-60320-Datensatz und den "Data Export Entry" (`SALESPRICE`, Status "CXW Pending", Dateiname `SalesPrice_<Artikel>_<Währung>_<Land>.json`) an. |
| Codeunit 60329 | `ExportEntry(var DataExportEntry: Record "Data Export Entry")` | Baut beim ersten Versuch die Payload (30 Schlüssel; `itemNo`/`variantCode` mit den alten NAV-Nummern "Old Item No."/"Old Variant Code") und sendet sie an die konfigurierte API-Schnittstelle; Ergebnis über `SetAttemptResult`, Protokoll in Table 60302 "CXW Http Call Log". Laufzeitfehler (fehlender Datensatz, Setup) werden an den Aufrufer weitergereicht. |
| Codeunit 60329 | `SetAttemptResult(var DataExportEntry; pSuccess: Boolean; pErrorMessage: Text)` / `GetDestinationCode(): Code[20]` | Versuch am Eintrag verbuchen (Attempt Count +1, Status, Zeitpunkte, Fehlertext) bzw. reservierten Destination Code `SALESPRICE` liefern. |
| Codeunit 60332 | `OnRun` (TableNo = "Job Queue Entry") | Job der Aufgabenwarteschlange für den Verkaufspreisexport, siehe Architektur. |
| Codeunit 60333 / 60334 | `OnRun` | Worker für `Codeunit.Run`: Freigabe einer Prüfzeile bzw. Export eines "Data Export Entry" in eigener Transaktion. |
| Page 60322 | `fnCalcNonStockPrice(p_decStockPriceFrom, p_decStockPriceTo, p_decNonStockPercent: Decimal)` | Berechnet den Nicht-Lagerpreis für Zeilen innerhalb einer Preisspanne. Aktuell aus keiner aktiven Stelle im Code aufgerufen. |
| Codeunit 60330 | `[IntegrationEvent] OnAfterSalesPriceModify(var SalesPriceRec, var SalesPricexRec: Record "Sales Price"; RunTrigger: Boolean)` | Wird ausgelöst, wenn der automatisierte Dateiimport einen bestehenden Verkaufspreis ändert. Aktuell ohne Subscriber. |
| Table 60317 | `SetApiKey(NewApiKey: Text)` / `GetApiKey(): Text` | Speichert/liest den API-Schlüssel einer Schnittstelle im Isolated Storage (Modul-Scope) statt in einem Klartext-Tabellenfeld. |
| Codeunit 60305 | `OnRun` / `ValidateAndCreateVendor` (lokal) | Verarbeitet alle Table-60300-Zeilen mit "CXW Created" = false einzeln in je eigener Transaktion (`Commit` + `Codeunit.Run` auf Codeunit 60351); scheitert ein Angebot, werden Fehlertext/-zeitpunkt am Angebot gespeichert und die übrigen weiterverarbeitet. Kein Aufrufer dieses `OnRun` im Projekt gefunden (siehe Bekannte Einschränkungen). |
| Codeunit 60305 | `internal ProcessOffer(var SellWatchOffer: Record "CXW SellWatch Vendor Info")` | Verarbeitet genau ein Angebot: Lieferant + Bankverbindung anlegen/finden, Einkaufsbestellung mit Artikel erzeugen und freigeben. Nur über Codeunit 60351 „CXW SellWatch Process Offer“ (`TableNo` = Table 60300) aufgerufen. |
| Codeunit 60305 | `CreateSourceFilePurchaseRequest(PurchaseHeader: Record "Purchase Header"): Text` | Baut das JSON für eine Bestellrückmeldung (SRid, purchase_order, optional tracking_number). Aktuell aus keiner anderen Stelle im Code aufgerufen. |
| Codeunit 60305 | `CreateSourceFileOrderStatusSE(SellWatchInfo: Record "CXW SellWatch Vendor Info"; Status: Enum "CXW SW Order Status"): Text` | Baut das JSON für eine Statusmeldung an SellWatch (Name, E-Mail, Uhrendaten, Link zur Online-Freigabe, Auszahlungswährung/-betrag aus der archivierten Einkaufszeile). Aktuell aus keiner anderen Stelle im Code aufgerufen. |
| Table 60301 | `CreateEntryInexternalFile(var WOA: Record "CXW Watch Online Approval")` | Fragt per HTTP GET beim SellWatch-Endpunkt ab, ob eine Uhr online sein sollte, aktualisiert die Zeile entsprechend und protokolliert den Aufruf in Table 60302 ("CXW Source Table No." = 60301). Aktuell aus keiner anderen Stelle im Code aufgerufen. |
| Codeunit 60331 | `OnRun` / `ProcessCheckedLines` (lokal) | Job-Queue-Einstiegspunkt; verarbeitet alle Table-60318-Zeilen mit Status "WS checked" einzeln über `ProcessLineWithErrorHandling`. |
| Codeunit 60331 | `ProcessLineWithErrorHandling` / `TryProcessLine` (beide lokal) | Kapselt die Verarbeitung einer einzelnen Zeile als `[TryFunction]`; bei Fehlschlag wird Status auf `Error` gesetzt und `GetLastErrorText()` in "CXW Last Error" geschrieben, ohne die Verarbeitung der übrigen Zeilen zu blockieren (`Commit()` nach jeder Zeile). |
| Codeunit 60335 | `GetWorkshopAttributeName(AttributeIndex: Integer): Text[250]` | Zentrale, austauschbare Zuordnung Attributindex → Name des Standard-Artikelattributs, gemeinsam genutzt für die Vorbefüllung bei "Send to Workshop" und das Rückschreiben in Codeunit 60331; Index 1–8 liefert die fachlichen Namen (Dial Color, Case Diameter, …), Index 9–10 weiterhin Platzhalter "Attribut 9"/"Attribut 10". |
| Codeunit 60335 | `internal IsSerialNoTracked` / `FindPurchLineSerialNo` / `AssignNextSerialNo` / `GetOrCreateSerialNoInformation` | Seriennummernlogik für "Send to Workshop": prüft SN-Einkaufsverfolgung am Artikelverfolgungscode, liest die Seriennr. aus der Artikelverfolgung der Einkaufszeile, zieht sonst die nächste Nr. aus `Item."Serial Nos."` und hängt sie per `Create Reserv. Entry` (Menge 1, Überschuss) an, und holt/legt den Datensatz "Serial No. Information" an. |
| Codeunit 60344 | `SetPurchaseOrder(var ConsignmentPostingEntry: Record "CXW Consignment Posting Entry"; ItemNo: Code[20])` | Ermittelt die offene, wareneingebuchte, noch nicht fakturierte Einkaufsbestellung zu einem Artikel und setzt Status/Fehlertext auf dem übergebenen Eintrag entsprechend. Bewusst public gemacht, damit Codeunit 60345 sie für die "Erneut versuchen"-Funktion wiederverwenden kann, statt die Logik zu duplizieren. |
| Codeunit 60345 | `OnRun` / `ProcessDueEntries` (lokal) | Job-Queue-Einstiegspunkt; verarbeitet alle Table-60341-Einträge mit Status "Open" und erreichtem "CXW Due Date" einzeln über `ProcessEntryWithErrorHandling`. |

Vollständige Liste aller Objekte mit Funktionsanzahl: siehe `docs/funktionsregister/gesamtuebersicht.md`.

## Tabellenübersicht (Kurzreferenz)

| Tabelle | Primärschlüssel | Zweck |
|---|---|---|
| 60300 CXW SellWatch Vendor Info | Entry No | Eingehende SellWatch-Ankaufsanfrage: Verkäufer-, Bank-, Uhren- und Angebotsdaten; "CXW Created" markiert, ob Lieferant/Bestellung bereits automatisiert angelegt wurden; "CXW Last Error"/"CXW Last Error DateTime" (nicht editierbar, nicht in der API) enthalten den Fehler des letzten gescheiterten Verarbeitungsversuchs und werden bei Erfolg geleert; FlowField "CXW Tracking Number" liest aus Table Extension 60304 auf "Purchase Header" |
| 60301 CXW Watch Online Approval | Entry No | Ergebnis der Online-Sichtbarkeitsprüfung je Artikel/Variante ("CXW Check Online", "CXW First Online Date", "CXW Remark"); FlowField "CXW SRid" liest "Vendor Order No." der zugehörigen Bestellung |
| 60302 CXW Http Call Log | Entry No | Gemeinsames Protokoll jedes HTTP-Aufrufs von `CreateEntryInexternalFile` (SellWatch) UND `SendToApiInterface` (Verkaufspreis-Export) – Erfolg/Fehlschlag, Statuscode, redigierter Request, Response als Blob; "CXW Source Table No." (60301, 50103 "Data Export Entry" bzw. bei Alt-Einträgen 60314) + "CXW Source Entry No" identifizieren die auslösende Zeile |
| 60311 CXW General Sales Price Setup | Primary Key (Singleton) | Grundeinstellungen, inkl. Export-Schalter und ausgewählter API-Schnittstelle |
| 60312 CXW Sales Price Checking | Item No., Currency Code, Country Code | Zwischenablage für Import/Prüfung/Freigabe |
| 60313 CXW Sales Price Archive | + Version No. | Historie; wird bei "Release Sales Prices" (Page 60322) über Codeunit 60329 **nur für das Archivland** ("CXW Archive Country Code", Standard DE) befüllt, Version No. je Item No./Currency Code/Country Code hochgezählt |
| 60320 CXW Sales Price Export | Entry No. (AutoIncrement) | Preisstand je freigegebener Länderzeile (Preise, Unit Price (LCY), Gültigkeit, Grund, Kommentar, Bemerkung, Änderungsinfo, SystemId des "Sales Price", Data Export Entry No., FlowField Export Status); Quelle der JSON-Payload; Ansicht Page 60320 "CXW Sales Price Export Entries" |
| 60314 CXW Sales Price Outbound File | Entry No. | **Obsolete Pending seit 27.0.0.3** – wird nicht mehr beschrieben (ersetzt durch ChronextBC "Data Export Entry", Destination Code `SALESPRICE`); enthält nur noch Altdaten bis 27.0.0.2 |
| 60315 CXW Sales Price Inbound File | Entry No. | Für automatisierten Dateiimport (nicht produktiv angebunden) |
| 60316 CXW Price Import Protocol | Entry No. | Fehlerprotokoll zum automatisierten Import (fachlich weiterhin das Sales-Price-Import-Protokoll; „Sales" im technischen Bezeichner wegen des 30-Zeichen-Limits von AL entfallen) |
| 60317 CXW API Interface Setup | Code | Endpunkt-URL, Authentifizierungsart und (im Isolated Storage abgelegter) API-Schlüssel je externer Schnittstelle; bei "CXW Auth Type" = AWSSigV4 zusätzlich AWS Access Key ID/Region/Service (Klartextfelder) sowie AWS Secret Access Key/Session Token (im Isolated Storage) |
| 60318 CXW Workshop Line | Document Type, Document No., Line No. | Ein Datensatz je an die Werkstatt übergebener Bestellzeile: Item No., Manufacturer Serial No., Status (Enum 60337: New/WS checked/Processed/Error), isAuthentic (Echtheits-Kennzeichen), acht fachlich benannte Attributfelder (Dial Color … Features) + zwei Platzhalter (Attribut 9/10), Created At, Checked At, Last Error |
| 60341 CXW Consignment Posting Entry | Entry No (AutoIncrement) | Ein Datensatz je gebuchter VK-Rechnungszeile eines Kommissionsartikels: Item No., Purchase Order No. (leer bei Erkennungsfehler), Sales Invoice No., Sales Posting Date, Due Date, Status (Enum 60343: Open/Posted/Error), Error Text |

**Kennzeichen "Auftrag halten":** Die frühere Table Extension 60300 "CXW Sales Header" (Feld "CXW Hold Order") und PageExtension 60337 "CXW Sales Order List" wurden mit Version 27.0.0.10 entfernt; das Feld liegt jetzt in CHX.Base (ab 27.0.3.5, TableExt 60212 "CXB Sales Header Ext.", Feld "CXB Hold Order"). Change: `openspec/changes/move-hold-order-to-chx-base`.

## Permission Set

Das Permission Set **`CXWChronWSAll`** (ID 60336, `src/PermissionSets/CXWChronWSAll.permissionset.al`) deckt Lese-/Schreibzugriff auf alle sieben Tabellen der Verkaufspreisverwaltung sowie – seit dem HTTP-Logging-Update – auf das mit SellWatch geteilte Table 60302 "CXW Http Call Log" ab, dazu Ausführungsrechte für beide Codeunits, Xmlport 60328 und die fünf Seiten (die vier der Verkaufspreisverwaltung plus Page 60309 "CXW Http Call Log"). Tabellenerweiterungen und Seitenerweiterungen benötigen keine eigenen Einträge, da sie über die Berechtigung des jeweiligen Basisobjekts (z. B. Standard-Zugriff auf "Currency") mit abgedeckt sind; die Standardtabelle "Sales Price", in die Codeunit 60329 schreibt, ist ebenso über die Base-App-Berechtigungen abgedeckt, nicht über dieses Set. Seit 27.0.0.3 enthält das Set zusätzlich `RIM` auf die ChronextBC-Tabelle "Data Export Entry", in die der Preisexport schreibt. Seit 27.0.0.6 zusätzlich `RIMD` auf Table 60320, Page 60320 und die Codeunits 60332–60334; der Benutzer des Aufgabenwarteschlangenpostens benötigt dieses Set. Das Set muss noch aktiv einer Benutzergruppe zugewiesen werden.

Für SellWatch deckt das separate Permission Set **`CXW SWChronWSAll`** (ID 60310, `src/PermissionSets/CXWSWChronWSAll.permissionset.al`) RIMD-Zugriff auf die beiden SellWatch-eigenen Tabellen (60300–60301) sowie das mit der Verkaufspreisverwaltung geteilte Table 60302 "CXW Http Call Log" ab, dazu Ausführungsrechte für Codeunit 60305 und die drei SellWatch-Seiten (60307–60309, wobei Page 60309 "CXW Http Call Log" ebenfalls geteilt ist). Die Table Extensions 60303/60304 auf "Purchase Line"/"Purchase Header" benötigen wie bei der Verkaufspreisverwaltung keinen eigenen Eintrag, da sie über die Standardberechtigung auf die jeweilige Basistabelle mit abgedeckt sind. Auch dieses Set muss noch aktiv einer Benutzergruppe zugewiesen werden.

Für die Workshop-Ankaufsprüfung gibt es zwei getrennte Permission Sets: **`CXW Workshop All`** (ID 60301, `src/PermissionSets/CXWWorkshopAll.permissionset.al`) für den vollständigen internen Zugriff auf Table 60318, alle Workshop-Seiten und Codeunit 60331 – inklusive der für Wareneingang, Stornierung und Artikelattribute benötigten Standardtabellen (Purchase Header/Line, Item, Item Attribute, Item Attribute Value, Item Attribute Value Mapping; für "Send to Workshop" zusätzlich Reservation Entry und Serial No. Information mit RIM, No. Series Line mit RM und Item Tracking Code mit R), damit die Job-Queue-Codeunit eigenständig lauffähig ist – und **`CXW Workshop API`** (ID 60302, `src/PermissionSets/CXWWorkshopAPI.permissionset.al`) als schlankes Gegenstück ausschließlich für den externen Workshop-Benutzer: nur `tabledata "CXW Workshop Line" = RM`, kein Insert/Delete, kein Zugriff auf Purchase Line oder Item. Beide Sets müssen noch aktiv zugewiesen werden (`CXW Workshop All` an interne Sachbearbeiter/den Job-Queue-Ausführungsbenutzer, `CXW Workshop API` ausschließlich an den dedizierten OAuth2-S2S-Benutzer der Werkstatt).

**`CXW Workshop All`** deckt seit dem Kommissionsverkauf-Update zusätzlich Table 60341, Codeunit 60344/60345 und Page 60342 ab, inklusive Lesezugriff auf die Standardtabellen `Sales Invoice Header`/`Sales Invoice Line` (für den Event-Subscriber) und `Purchases & Payables Setup` (für das neue Verzögerungs-Feld) – der Job-Queue-Ausführungsbenutzer von Codeunit 60345 benötigt somit dasselbe Permission Set wie für die Workshop-Verarbeitung.

## Tests ausführen

Es existieren aktuell **keine** AL-Testcodeunits in diesem Projekt. Als Grundlage für zukünftige Tests eignet sich die Spezifikation `openspec/specs/sales-price-country-copy/spec.md` (Szenarien für Ländereinrichtung und die Aktion "Add all Countries"). Für SellWatch liefern `openspec/specs/sellwatch-http-call-logging/spec.md` (Szenarien für Erfolgs-/Fehlschlag-Logging, API-Key-Redaktion und Telemetrie von `CreateEntryInexternalFile`) und `openspec/specs/sellwatch-standard-table-extensions/spec.md` (Szenarien für "CXW Used good" und "CXW Tracking Number") eine vergleichbare Grundlage. Für die Workshop-Ankaufsprüfung liegen die Szenarien noch verteilt auf mehrere, teils noch nicht archivierte OpenSpec-Changes (`openspec/changes/purchase-workshop-integration/specs/` sowie die darauf aufbauenden Deltas in `openspec/changes/archive/2026-08-13-workshop-line-error-handling/` und `openspec/changes/archive/2026-08-13-workshop-attribute-*`) – vor einer Testerstellung sollten diese zu einer konsolidierten Spec unter `openspec/specs/workshop-line-processing/` zusammengeführt werden (siehe Bekannte Einschränkungen).

## Deployment

Kein CI/CD-Setup (z. B. AL-Go-Workflow) im Projekt gefunden. Deployment erfolgt aktuell manuell über "AL: Publish" aus VS Code in die Zielumgebung.

## Beitragen / Konventionen

- Alle neuen Objekte erhalten IDs im registrierten Bereich **60300–60349** (siehe `app.json`, `idRanges`; der ältere Bereich 51000–51049 bleibt zwar registriert, wird aber seit dem Rename vom 2026-08-10 nicht mehr belegt), pro Objekttyp unabhängig gezählt.
- Der Code enthält bewusst **keine** Kommentare (auf ausdrücklichen Kundenwunsch entfernt) – fachliche Hintergründe und Design-Entscheidungen werden stattdessen in diesem Handbuch und im Funktionsregister dokumentiert. Bei Änderungen bitte diesen Stil beibehalten und Kontext hier statt im Code ergänzen.
- Abgeschlossene, funktionale Änderungen werden als OpenSpec-Change dokumentiert (`openspec/changes/`, nach Fertigstellung archiviert unter `openspec/changes/archive/`) und als dauerhafte Spezifikation unter `openspec/specs/` abgelegt.
- Übersetzungen: `.g.xlf` wird durch den Compiler erzeugt und darf **nicht** manuell editiert werden; Pflege erfolgt ausschließlich in `Translations/CHX.Webshop.de-DE.xlf`.

## Bekannte Einschränkungen

- **"Add all Countries" rechnet nur von einer Quellzeile in Mandantenwährung korrekt um.** Die Umrechnung (`Preis * (1 / Kurs)` über `GetLastestExchangeRate`) setzt voraus, dass die importierte Quellzeile in MW vorliegt. Eine Quellzeile in Fremdwährung (z. B. CHF) würde für Länder mit anderer Währung falsch umgerechnet. Länder mit derselben Währung wie die Quellzeile erhalten den Preis unverändert.
- **"Sales Price" kennt kein Land.** Bei mehreren Ländern derselben Währung wird derselbe "Sales Price"-Datensatz (Schlüssel ohne Land) mehrfach geschrieben – der zuletzt freigegebene Preis gewinnt. Das Land und der Preis je Land werden in Table 60320 und im gesendeten JSON (`countryRegionCode`) geführt; der Job liest die Preise deshalb aus Table 60320, nicht aus "Sales Price".
- **Quellzeilen ohne Land werden nicht freigegeben.** Ohne aktivierte DE-Länderzeile entsteht kein EUR-Preis in "Sales Price", kein Archiveintrag und kein Export.
- **Table 60320 hat keine Aufbewahrungsregel** und wächst mit jeder Freigabe.
- **"Approve" selbst übernimmt Preise nicht in die Standardtabelle "Sales Price" oder in "CXW Sales Price Archive".** Die Aktion setzt nur die Freigabe-Kennzeichen auf Table 60312. Die Übernahme erfolgt erst im nachgelagerten Schritt "Release Sales Prices" (Page 60322, Codeunits 60333/60329).
- **(Behoben am 2026-08-10) `"CXW Unit Price (LCY)"` wurde nie automatisch befüllt** – `WriteBackAndArchive` schrieb bislang nur das Standardfeld `"Unit Price"`, während `fnValidate` auf Page 60322 beim Vergleich mit dem vorherigen Preis durch `"CXW Unit Price (LCY)"` dividierte. Da dieses Feld bei jedem automatisiert geschriebenen Datensatz `0` blieb, führte jeder zweite "Validate"-Lauf für ein bereits einmal hochgeladenes Artikel/Währungs-Paar zuverlässig zu `Attempted to divide by zero.` und brach den gesamten Batch ab. Seit `Codeunit 60329`.`ResolveUnitPriceLCY` befüllt `WriteBackAndArchive` das Feld bei jedem Schreiben automatisch (Umrechnung über den auf der Preiszeile bereits erfassten Wechselkurs bzw. per Fallback-Lookup); zusätzlich überspringt `fnValidate` den Vergleich statt zu dividieren, wenn der vorherige Datensatz noch `0` enthält. Bereits vor dem Fix geschriebene "Sales Price"-Datensätze bleiben bei `0`, bis sie das nächste Mal über "Upload Sales Price" neu geschrieben werden – kein rückwirkendes Backfill (siehe `openspec/changes/archive/2026-08-10-sales-price-unit-price-lcy-autofill/design.md`).
- **`Reason Code` als Enum ohne echten Leerwert**: Das Enum hat immer einen Default-Wert (`CatMan`), es gibt keinen Zustand "kein Grund angegeben".
- **Dateibasierter Import (Codeunit 60330, Tables 60315–60316)** ist vollständig implementiert, aber an keiner Stelle produktiv verdrahtet oder terminiert (kein Job Queue Eintrag). `WriteSalesPrices` ruft `SalesPrice.Get(...)` jetzt mit genau den 8 echten Primärschlüsselfeldern der Standardtabelle "Sales Price" auf (verifiziert anhand der Symbole in `.alpackages/Microsoft_Base Application_*.app`), mit `''` für "Variant Code" – die zuvor dokumentierte Schlüssel-Abweichung ist damit behoben.
- **Keine automatisierten Tests** vorhanden.
- **Der eigentliche Auslöser von Codeunit 60305 "CXW SellWatch Mgt".OnRun ist nicht Teil des AL-Quellcodes.** Im Projekt existiert weder ein Installations-/Upgrade-Codeunit noch ein Event-Subscriber noch eine API-Page, die `OnRun` aufruft oder Zeilen in Table 60300 einfügt. In der Praxis muss die Ausführung daher über einen zur Laufzeit angelegten Job-Queue-Eintrag, einen manuellen Aufruf oder eine außerhalb dieses Codes liegende Integration erfolgen; das steht nicht im Widerspruch zur im Benutzerhandbuch beschriebenen automatisierten Verarbeitung, ist im Code selbst aber nicht nachvollziehbar.
- **`CreateSourceFilePurchaseRequest`, `CreateSourceFileOrderStatusSE` (Codeunit 60305) und `CreateEntryInexternalFile` (Table 60301, für den eigentlichen Online-Check) werden aktuell von keiner anderen Stelle im Projekt aufgerufen.** Insbesondere die beiden JSON-Builder wirken wie vorbereitete, aber (noch) nicht angebundene Rückmeldungen an SellWatch.
- **`CreatePurchaseOrderinBV` und `CreatePurchaseOrderinGmBH` (Codeunit 60305, beide lokal)** sind ebenfalls nicht aufgerufen – Reste der im Quellsystem laut Code-Kommentar bereits deaktivierten GMBH/BV-Fallunterscheidung. `ReadJSONFile` (Table 60301, lokal) ist ein leerer Stub ohne Funktion.
- **(Behoben) SellWatch-Artikelanlage nutzt eine konfigurierbare Artikelvorlage statt fester Variantencodes.** Ursprünglich waren Artikel-/Variantencodes für SellWatch-Einkaufszeilen fest im Code hinterlegt (`C2C-SW`, `CPST-SW`, `TI-SW`); das wurde durch eine dynamische Artikelanlage per Artikelvorlage ersetzt (`CreateSellWatchItem`, Codeunit 60305, seit 2026-09-30 über den Standard `"Item Templ. Mgt".CreateItemFromTemplate` statt `Item.TransferFields`). Die Vorlagen sind in `TableExtension 60322 "CXW SW Purchases Setup"` / `PageExtension 60330` konfigurierbar – `"CXW SW Item Template Code"` (Standard) und `"CXW SW Consign. Item Templ."` (Kommission); `GetSellWatchItemTemplateCode` wählt nach `"CXW Offer Type"` und bricht mit sprechendem Fehler ab, falls das zuständige Feld leer ist oder auf eine nicht mehr existierende Vorlage verweist, siehe `openspec/specs/sellwatch-item-template-setup/spec.md`.
- **Kommissionsverkauf setzt "1 Artikel = 1 offene Purchase Order = 1 Purchase Line" voraus** (dieselbe Annahme wie bei der Workshop-Ankaufsprüfung). Bricht diese Annahme (z. B. mehrere offene Bestellungen für denselben Artikel), liefert `SetPurchaseOrder` (Codeunit 60344) bewusst einen `Error`-Eintrag statt einer präziseren Auflösung.
- **`"Vendor Invoice No."` wird beim automatischen Fakturieren (Codeunit 60345) mit `"CXW Sales Invoice No." + "-CONS"` befüllt, falls auf der Purchase Order leer.** Dieses Muster ist ein Platzhalter für die tatsächliche Kreditoren-Rechnungsnummer, die im automatisierten Ablauf nicht anderweitig vorliegt – bei Bedarf mit dem Fachbereich abstimmen.
- **Kein Job-Queue-Eintrag für Codeunit 60345 "CXW Post Consignment Purchases" ist vorkonfiguriert.** Muss nach Deployment manuell eingerichtet werden (empfohlen: täglich), siehe Key-User-Handbuch.
- **Der Online-Check (`CreateEntryInexternalFile`) verwendet einen fest verdrahteten Schnittstellen-Code `'WOA'`** auf Table 60317 "CXW API Interface Setup" – derselben Tabelle, die auch die Verkaufspreisverwaltung für ihren Preisexport nutzt (dort über das konfigurierbare Feld "CXW API Interface Code"). Für SellWatch ist der Code nicht konfigurierbar, sondern muss exakt `'WOA'` lauten.
- **Workshop-Ankaufsprüfung deckt nur den Standardfall "eine Purchase Order = eine Purchase Line" ab.** Gemischte Bestellungen (mehrere Zeilen, teils echt/teils nicht echt) sind nicht implementiert – bei Nicht-Echtheit storniert `ProcessNonGenuineLine` (Codeunit 60331) aktuell die *gesamte* Purchase Order, auch wenn nur eine von mehreren Zeilen betroffen wäre (`// TODO:`-markiert im Code).
- **Zwei der zehn Workshop-Attributfelder (Attribut 9/10) haben weiterhin keine fachliche Bezeichnung** (Platzhalter-Captions), im Unterschied zu den bereits benannten Attributen 1–8 (Dial Color … Features).
- **Die Basis-Spezifikation der Workshop-Ankaufsprüfung ist nicht sauber archiviert.** Der ursprüngliche Change `purchase-workshop-integration` (Enum 60337, Table 60318, TableExtension 60321, PageExtension 60328/60329, Pages 60338–60339, Codeunit 60331, PermissionSets 60301/60302) liegt fehlplatziert unter `openspec/changes/archive/2026-08-13-workshop-line-error-handling/purchase-workshop-integration/` statt an einer regulären, datierten Archiv-Stelle und ist für `openspec list`/`openspec status` unsichtbar (Stand: 30/34 Tasks). Mehrere spätere Changes (`workshop-line-error-handling`, `workshop-attribute-names`, `workshop-attribute-field-names`) liefern Delta-Specs gegen die Capabilities `workshop-line-processing`/`workshop-line-api`, die dadurch nie zu einer kanonischen Spec unter `openspec/specs/` konsolidiert wurden. Vor weiteren Änderungen an der Workshop-Verarbeitung sollte dies bereinigt werden.
